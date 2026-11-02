# Changelog

## 1.0.0

- First release: runs the Marketplace fleet worker as a Home Assistant add-on (amd64, aarch64).
- worker.py is fetched from the Master on first start, then updates itself; state is kept in `/data`.
