#!/usr/bin/env bash
# Entry point of the Home Assistant add-on.
# Reads the add-on options, keeps all worker state under /data (survives restarts and add-on updates),
# fetches worker.py from the master on first start and then lets the worker update itself.
set -u

OPTIONS=/data/options.json
STATE=/data/worker
mkdir -p "$STATE"

opt() { jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS"; }

MASTER_API_URL="$(opt master_url)"
MASTER_API_URL="${MASTER_API_URL%/}"
WORKER_TOKEN="$(opt worker_token)"
WORKER_ID="$(opt worker_id)"
WORKER_NAME="$(opt worker_name)"
REQUEST_DELAY_MIN="$(opt request_delay_min)"
REQUEST_DELAY_MAX="$(opt request_delay_max)"

if [ -z "$WORKER_TOKEN" ]; then
    echo "[addon] worker_token is empty. Set it in the add-on Configuration tab, then restart." >&2
    # Stay up instead of crash-looping, so the message stays visible in the Log tab.
    exec sleep infinity
fi

# A stable id per installation when the user leaves worker_id empty.
if [ -z "$WORKER_ID" ]; then
    if [ ! -s /data/generated_worker_id ]; then
        echo "ha-$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')" > /data/generated_worker_id
    fi
    WORKER_ID="$(cat /data/generated_worker_id)"
fi
[ -z "$WORKER_NAME" ] && WORKER_NAME="$WORKER_ID"

export MASTER_API_URL WORKER_TOKEN WORKER_ID WORKER_NAME REQUEST_DELAY_MIN REQUEST_DELAY_MAX
# Keep the 12h dedup cache across restarts. The Chrome profile stays in /opt/worker-chrome-profile
# (re-downloaded after a container restart): the worker's profile reset rmtree()s that path, which a
# symlink into /data would silently break.
export WORKER_CACHE_FILE=/data/worker_seen_cache.json

WORKER_PY="$STATE/worker.py"

fetch_worker() {
    local tmp="$STATE/worker.py.download"
    if curl -fsSL --max-time 30 \
            -H "X-Worker-Token: $WORKER_TOKEN" -H "X-Worker-ID: $WORKER_ID" \
            "$MASTER_API_URL/api/worker/script" -o "$tmp" \
        && grep -q '^def main():' "$tmp" \
        && python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' "$tmp"; then
        mv -f "$tmp" "$WORKER_PY"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# Only on first start: after that worker.py replaces itself when the master announces a new version,
# and its boot guard (.worker_good.py next to it) rolls back a version that keeps crashing.
until [ -s "$WORKER_PY" ]; do
    if fetch_worker; then
        echo "[addon] worker.py downloaded from $MASTER_API_URL"
    else
        echo "[addon] could not download worker.py from $MASTER_API_URL, retrying in 60s" >&2
        sleep 60
    fi
done

child=0
trap 'if [ "$child" -ne 0 ]; then kill -TERM "$child" 2>/dev/null; wait "$child"; fi; exit 0' TERM INT

echo "[addon] starting worker id=$WORKER_ID name=$WORKER_NAME master=$MASTER_API_URL"
while true; do
    python3 -u "$WORKER_PY" &
    child=$!
    wait "$child"
    rc=$?
    child=0
    if [ "$rc" -eq 0 ]; then
        # Exit 0 means the worker just wrote a new version of itself.
        echo "[addon] worker exited after self-update, restarting"
        sleep 2
    else
        echo "[addon] worker exited with code $rc, restarting in 15s" >&2
        sleep 15
    fi
done
