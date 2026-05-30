#!/bin/sh
# =============================================================================
# entrypoint.sh — translates environment variables into konnectd CLI flags.
#
# Every recognised env-var is optional; unset or empty values are silently
# ignored so that konnect falls back to its own defaults.
# =============================================================================
set -eu

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

# Append any extra arguments passed directly to `docker run … <extra>` or CMD
ARGS="$ARGS $*"

# shellcheck disable=SC2086
exec konnectd $ARGS
