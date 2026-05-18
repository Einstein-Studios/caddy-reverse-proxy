#!/bin/sh

set -euo pipefail

OPENCLAW_CONFIGURED=0
if [ -n "${DAYTONA_GATEWAY_PREVIEW_URL:-}" ] \
	|| [ -n "${DAYTONA_METADATA_PREVIEW_URL:-}" ] \
	|| [ -n "${DAYTONA_PREVIEW_TOKEN:-}" ] \
	|| [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
	OPENCLAW_CONFIGURED=1
fi

if [ "$OPENCLAW_CONFIGURED" = "1" ]; then
	: "${DAYTONA_GATEWAY_PREVIEW_URL:?missing DAYTONA_GATEWAY_PREVIEW_URL}"
	: "${DAYTONA_METADATA_PREVIEW_URL:?missing DAYTONA_METADATA_PREVIEW_URL}"
	: "${DAYTONA_PREVIEW_TOKEN:?missing DAYTONA_PREVIEW_TOKEN}"
	: "${OPENCLAW_GATEWAY_TOKEN:?missing OPENCLAW_GATEWAY_TOKEN}"
else
	export DAYTONA_GATEWAY_PREVIEW_URL="${DAYTONA_GATEWAY_PREVIEW_URL:-http://127.0.0.1:9}"
	export DAYTONA_METADATA_PREVIEW_URL="${DAYTONA_METADATA_PREVIEW_URL:-http://127.0.0.1:9}"
	export DAYTONA_PREVIEW_TOKEN="${DAYTONA_PREVIEW_TOKEN:-openclaw-proxy-not-configured}"
	export OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-openclaw-proxy-not-configured}"
fi

export OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
export OPENCLAW_METADATA_PORT="${OPENCLAW_METADATA_PORT:-18790}"
export PORT="${PORT:-3000}"

# for backwards compatibility, seperates host and port from url
export FRONTEND_HOST="${FRONTEND_HOST:-127.0.0.1:9}"
export FRONTEND_DOMAIN=${FRONTEND_DOMAIN:-${FRONTEND_HOST%:*}}
export FRONTEND_PORT=${FRONTEND_PORT:-${FRONTEND_HOST##*:}}

export BACKEND_HOST="${BACKEND_HOST:-127.0.0.1:9}"
export BACKEND_DOMAIN=${BACKEND_DOMAIN:-${BACKEND_HOST%:*}}
export BACKEND_PORT=${BACKEND_PORT:-${BACKEND_HOST##*:}}

# strip https:// or https:// from domain if necessary
FRONTEND_DOMAIN=${FRONTEND_DOMAIN##*://}
BACKEND_DOMAIN=${BACKEND_DOMAIN##*://}

echo using frontend: ${FRONTEND_DOMAIN} with port: ${FRONTEND_PORT}
echo using backend: ${BACKEND_DOMAIN} with port: ${BACKEND_PORT}
if [ "$OPENCLAW_CONFIGURED" = "1" ]; then
	echo using openclaw gateway preview: ${DAYTONA_GATEWAY_PREVIEW_URL}
	echo using openclaw metadata preview: ${DAYTONA_METADATA_PREVIEW_URL}
else
	echo openclaw daytona preview proxy is not configured
fi

exec caddy run --config Caddyfile --adapter caddyfile 2>&1
