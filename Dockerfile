# =============================================================================
# docker-konnect — Dockerfile
# Maintainer: Federico Manzella <ferdiu>
#
# Multi-stage build producing two distinct images:
#
#   konnect      — minimal Python image with konnect installed (no extra tools)
#   konnect-full — konnect + common Linux utilities (busybox, curl, …)
#
# Build arguments
#   KONNECT_VERSION   upstream release tag, e.g. "0.4.0"
#   UID / GID         uid/gid for the unprivileged runtime user (default 1000)
#
# konnect is NOT on PyPI — it is distributed exclusively as a wheel attached
# to each GitHub release at:
#   https://github.com/metallkopf/konnect/releases/download/<ver>/konnect-<ver>-py3-none-any.whl
# =============================================================================

ARG PYTHON_VERSION=3.14
ARG KONNECT_VERSION=0.4.0

# ---------------------------------------------------------------------------
# Stage 1 — "konnect": bare Python image with only konnect installed
# ---------------------------------------------------------------------------
FROM python:${PYTHON_VERSION}-slim AS konnect

ARG KONNECT_VERSION
ARG UID=1000
ARG GID=1000

LABEL org.opencontainers.image.title="konnect" \
      org.opencontainers.image.description="Headless KDE Connect server — minimal image" \
      org.opencontainers.image.authors="Federico Manzella <ferdiu>" \
      org.opencontainers.image.source="https://github.com/ferdiu/docker-konnect" \
      org.opencontainers.image.licenses="GPL-2.0"

# Create a dedicated non-root user/group so the daemon never runs as root
RUN groupadd --gid "${GID}" konnect \
 && useradd  --uid "${UID}" --gid "${GID}" \
             --home-dir /home/konnect \
             --create-home \
             --shell /bin/false \
             konnect

# Install konnect from the GitHub release wheel inside a virtualenv.
# Using a venv keeps the system Python pristine and makes upgrades atomic.
# The wheel URL pattern is stable across releases:
#   https://github.com/metallkopf/konnect/releases/download/<ver>/konnect-<ver>-py3-none-any.whl
#
# Why twisted[tls]?
#   konnect declares "twisted" and "pyopenssl" as dependencies, but "twisted"
#   alone does not pull in service_identity, idna, or automat — those arrive
#   only via the "twisted[tls]" extra.  Installing twisted[tls] explicitly
#   satisfies the full TLS dependency chain without pinning transitive versions.
ENV VIRTUAL_ENV=/home/konnect/venv
RUN python -m venv "${VIRTUAL_ENV}" \
 && "${VIRTUAL_ENV}/bin/pip" install --no-cache-dir \
      "twisted[tls]" \
      "https://github.com/metallkopf/konnect/releases/download/${KONNECT_VERSION}/konnect-${KONNECT_VERSION}-py3-none-any.whl"

# Put the venv binaries on PATH so CMD can reference them by name
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

# ----------------------------
# Runtime configuration knobs
# ----------------------------
# All env-vars map 1-to-1 to konnectd CLI flags.
# Override them at `docker run` time with -e or in a compose file.
ENV KONNECT_NAME=""           \
    KONNECT_DISCOVERY_PORT="" \
    KONNECT_SERVICE_PORT=""   \
    KONNECT_ADMIN_PORT=""     \
    KONNECT_CONFIG_DIR=""     \
    KONNECT_DEBUG=""          \
    KONNECT_TIMESTAMPS=""

# Config and data directories
RUN install -d -o konnect -g konnect /home/konnect/.config/konnect /data
VOLUME ["/data"]

# Default network ports used by konnect
# 1716 — KDE Connect discovery (UDP + TCP)
# 1764 — KDE Connect service port (TCP) — konnect default when not using 1716
# 8080 — REST admin API (TCP)
EXPOSE 1716/udp 1716/tcp 1764/tcp 8080/tcp

# Drop privileges for the rest of the lifecycle
USER konnect
WORKDIR /home/konnect

# Entrypoint wrapper resolves env-vars into CLI flags.
COPY --chown=konnect:konnect entrypoint.sh /home/konnect/entrypoint.sh
RUN chmod +x /home/konnect/entrypoint.sh

ENTRYPOINT ["/home/konnect/entrypoint.sh"]
CMD []

# ---------------------------------------------------------------------------
# Stage 2 — "konnect-full": extends the minimal image with common Linux tools
# ---------------------------------------------------------------------------
FROM konnect AS konnect-full

LABEL org.opencontainers.image.title="konnect-full" \
      org.opencontainers.image.description="Headless KDE Connect server — image with common Linux tools" \
      org.opencontainers.image.authors="Federico Manzella <ferdiu>" \
      org.opencontainers.image.source="https://github.com/ferdiu/docker-konnect" \
      org.opencontainers.image.licenses="GPL-2.0"

# Temporarily switch to root to install system packages, then drop back
USER root

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      busybox \
      curl \
      wget \
      ca-certificates \
      iputils-ping \
      net-tools \
      iproute2 \
      procps \
      less \
      vim-tiny \
      jq \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Return to the unprivileged user for runtime
USER konnect
