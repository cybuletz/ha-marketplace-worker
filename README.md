# Marketplace Fleet Worker – Home Assistant add-on repository

[![Add repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fcybuletz%2Fha-marketplace-worker)

Runs a Marketplace fleet crawler node on a Home Assistant OS / Supervised machine.
Outbound HTTPS only, no ports, no access to Home Assistant itself.

Installation and options: [marketplace_worker/DOCS.md](marketplace_worker/DOCS.md).

## How it is put together

- `marketplace_worker/` is the add-on. Home Assistant pulls a prebuilt image
  (`ghcr.io/cybuletz/ha-marketplace-worker-{arch}`), so the HA box never builds Chromium itself.
- The image holds only the runtime (Python, Chromium, Xvfb). The crawler code, `worker.py`, is downloaded
  from the Master on first start and keeps itself up to date, exactly like the Docker and LXC workers.
  This repository therefore contains no crawler code and no secrets; the token is entered in the add-on UI.
- `.github/workflows/build.yaml` builds both arches on native GitHub runners and pushes to GHCR on every
  push to `main` that touches the add-on.

## Releasing a new add-on version

Only needed when the runtime changes (base image, Python packages, `run.sh`). Worker code updates do not
need a release.

1. Bump `version` in `marketplace_worker/config.yaml` and add a line to `CHANGELOG.md`.
2. Push to `main` and wait for the workflow to finish.
3. Home Assistant shows an **Update** button for the add-on.
