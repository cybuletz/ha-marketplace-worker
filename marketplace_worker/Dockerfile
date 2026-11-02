# Same base as docker/worker in marketplace-platform: Python + Chromium + its system libraries,
# published for linux/amd64 and linux/arm64.
ARG BUILD_FROM=mcr.microsoft.com/playwright/python:v1.49.0-jammy
FROM ${BUILD_FROM}

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_ROOT_USER_ACTION=ignore

# xvfb is installed here so the worker never has to apt-get it at runtime (headful Lens mode).
RUN apt-get update && apt-get install -y --no-install-recommends \
        tini jq curl procps xvfb ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# playwright is pinned to the base image's version so the bundled Chromium matches it.
RUN pip install --no-cache-dir \
        playwright==1.49.0 curl_cffi requests beautifulsoup4 lxml

COPY run.sh /run.sh
RUN chmod a+x /run.sh

ARG BUILD_ARCH
ARG BUILD_VERSION
LABEL io.hass.type="addon" \
      io.hass.name="Marketplace Fleet Worker" \
      io.hass.arch="${BUILD_ARCH}" \
      io.hass.version="${BUILD_VERSION}" \
      org.opencontainers.image.source="https://github.com/cybuletz/ha-marketplace-worker"

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/run.sh"]
