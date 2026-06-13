#!/bin/sh
# =============================================================================
# entrypoint.sh — translates environment variables into konnectd CLI flags.
#
# Every recognised env-var is optional; unset or empty values are silently
# ignored so that konnect falls back to its own defaults.
#
# The binary is referenced by its absolute path inside the virtualenv to
# avoid relying on PATH resolution, which is not guaranteed to be inherited
# correctly by all OCI runtimes (e.g. Podman without a login shell).
# =============================================================================
set -eu

KONNECTD="/home/konnect/venv/bin/konnectd"

ARGS=""

# --name NAME
[ -n "${KONNECT_NAME:-}" ]           && ARGS="$ARGS --name $KONNECT_NAME"

# --discovery-port PORT
[ -n "${KONNECT_DISCOVERY_PORT:-}" ] && ARGS="$ARGS --discovery-port $KONNECT_DISCOVERY_PORT"

# --service-port PORT
[ -n "${KONNECT_SERVICE_PORT:-}" ]   && ARGS="$ARGS --service-port $KONNECT_SERVICE_PORT"

# --admin-port PORT  (accepts tcp port number or unix socket path)
[ -n "${KONNECT_ADMIN_PORT:-}" ]     && ARGS="$ARGS --admin-port $KONNECT_ADMIN_PORT"

# --config-dir DIR
[ -n "${KONNECT_CONFIG_DIR:-}" ]     && ARGS="$ARGS --config-dir $KONNECT_CONFIG_DIR"

# --debug (boolean flag — any non-empty value enables it)
[ -n "${KONNECT_DEBUG:-}" ]          && ARGS="$ARGS --debug"

# --timestamps (boolean flag)
[ -n "${KONNECT_TIMESTAMPS:-}" ]     && ARGS="$ARGS --timestamps"

# Append any extra arguments passed directly to `docker run … <extra>` or CMD.
# "$@" is used instead of $* so arguments containing spaces are preserved.
# shellcheck disable=SC2086
exec "$KONNECTD" $ARGS "$@"
