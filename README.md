# docker-konnect

[![Build & Publish](https://github.com/ferdiu/docker-konnect/actions/workflows/docker-build.yml/badge.svg)](https://github.com/ferdiu/docker-konnect/actions/workflows/docker-build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/ferdiu/konnect)](https://hub.docker.com/r/ferdiu/konnect)
[![Image Size](https://img.shields.io/docker/image-size/ferdiu/konnect/latest)](https://hub.docker.com/r/ferdiu/konnect)
[![License](https://img.shields.io/badge/license-GPL--2.0-blue)](LICENSE)

Unofficial Docker image for **[konnect](https://github.com/metallkopf/konnect)** — a headless [KDE Connect](https://community.kde.org/KDEConnect) server that exposes a REST API, letting you send notifications, ping, ring, and interact with your devices from any server or script.

---

## Image variants

| Tag | Description |
|-----|-------------|
| `latest` / `X.Y.Z` | Minimal image — Python + konnect only |
| `latest-full` / `X.Y.Z-full` | Extends the minimal image with common Linux utilities (`busybox`, `curl`, `wget`, `jq`, `vim-tiny`, `net-tools`, …) |

Both variants are published to **Docker Hub** and **GHCR** under the same naming scheme:

```
ferdiu/konnect:latest
ferdiu/konnect:latest-full

ghcr.io/ferdiu/konnect:latest
ghcr.io/ferdiu/konnect:latest-full
```

Architectures: `linux/amd64`, `linux/arm64`.

---

## Quick start

> **Important:** konnect needs to be on the same broadcast domain as your KDE Connect devices. `--network host` is the simplest way to achieve this.

```sh
docker run -d \
  --name konnect \
  --network host \
  --restart unless-stopped \
  -e KONNECT_NAME="my-server" \
  -e KONNECT_DISCOVERY_PORT="1716" \
  -v konnect_data:/data \
  ferdiu/konnect:latest
```

The REST API is available at `http://localhost:8080`.

---

## Configuration

All konnect options are exposed as environment variables:

| Variable | konnectd flag | Default |
|---|---|---|
| `KONNECT_NAME` | `--name` | hostname |
| `KONNECT_DISCOVERY_PORT` | `--discovery-port` | `1764` |
| `KONNECT_SERVICE_PORT` | `--service-port` | `1764` |
| `KONNECT_ADMIN_PORT` | `--admin-port` | `8080` |
| `KONNECT_CONFIG_DIR` | `--config-dir` | `/data` |
| `KONNECT_DEBUG` | `--debug` | *(unset)* |
| `KONNECT_TIMESTAMPS` | `--timestamps` | *(unset)* |

Boolean flags (`KONNECT_DEBUG`, `KONNECT_TIMESTAMPS`) are enabled by setting them to **any non-empty value**.

You can also pass konnectd flags directly after the image name:

```sh
docker run --rm --network host ferdiu/konnect:latest --debug --name mybox
```

---

## Docker Compose

A ready-to-use example is provided in [`docker-compose.yml`](https://github.com/ferdiu/docker-konnect/blob/main/docker-compose.yml). Copy and adjust it to your needs:

```sh
curl -O https://raw.githubusercontent.com/ferdiu/docker-konnect/main/docker-compose.yml
# edit KONNECT_NAME and any other variables
docker compose up -d
```

---

## Volumes

| Path | Purpose |
|------|---------|
| `/data` | konnect configuration & paired-device database |

Mount a named volume or host directory at `/data` to persist your configuration across container restarts and upgrades.

---

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| `1716` | UDP + TCP | KDE Connect discovery (use with official app) |
| `1764` | TCP | konnect service port (konnect default) |
| `8080` | TCP | REST admin API |

---

## Health check

Both image variants include a built-in health check that probes the admin TCP port every 30 seconds using the Python standard library (no extra tools required). The probe respects the `KONNECT_ADMIN_PORT` environment variable, so custom port overrides are automatically honoured.

---

## Security

- The daemon runs as an **unprivileged user** (`konnect`, UID 1000) — never as root.
- No capabilities are requested beyond what the base image provides.

---

## REST API

Refer to the [upstream documentation](https://github.com/metallkopf/konnect#rest-api) for the full REST API reference. Quick example:

```sh
# List connected devices
curl http://localhost:8080/device

# Send a notification to a device named "phone"
curl -X POST http://localhost:8080/notification/@phone \
  -d "application=MyApp&title=Hello&text=World"

# Ping
curl -X POST http://localhost:8080/ping/@phone
```

---

## Updating

The CI workflow polls the [upstream GitHub releases](https://github.com/metallkopf/konnect/releases) every night at midnight UTC. A new image is built automatically whenever a new konnect version is released. To update your running container:

```sh
docker compose pull && docker compose up -d
```

---

## Building locally

```sh
# Minimal image
docker build --target konnect \
  --build-arg KONNECT_VERSION=0.4.0 \
  -t konnect:local .

# Full image
docker build --target konnect-full \
  --build-arg KONNECT_VERSION=0.4.0 \
  -t konnect-full:local .
```

---

## License

The Docker image and associated files are released under the [GPL-2.0 license](LICENSE), consistent with upstream konnect.

> konnect is developed by [metallkopf](https://github.com/metallkopf/konnect) and distributed under GPL-2.0.
