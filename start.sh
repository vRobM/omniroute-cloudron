#!/bin/bash
set -euo pipefail

# ── Cloudron startup script for OmniRoute ───────────────────────────────
# Cloudron provides: gosu, cloudron user (UID 1000), localstorage addon, redis addon
# Localstorage addon creates a volume at /run/database/ (mounted by Cloudron)
# The addon also injects CLOUDRON_* env vars for the database connection

# ── Ownership ──────────────────────────────────────────────────────────
# Cloudron's localstorage addon may mount the data volume with different ownership.
# The addon injects LOCALSTORAGE_* vars but we use the simpler DATA_DIR path.
DATA_PATH="${DATA_DIR:-/app/data}"
chown -R cloudron:cloudron "$DATA_PATH" 2>/dev/null || true

# ── Redis configuration ────────────────────────────────────────────────
# Cloudron Redis addon injects CLOUDRON_REDIS_HOST, CLOUDRON_REDIS_PORT, etc.
if [[ -n "${CLOUDRON_REDIS_HOST:-}" ]]; then
    REDIS_PORT="${CLOUDRON_REDIS_PORT:-6379}"
    REDIS_PASSWORD="${CLOUDRON_REDIS_PASSWORD:-}"
    if [[ -n "$REDIS_PASSWORD" ]]; then
        export REDIS_URL="redis://:${REDIS_PASSWORD}@${CLOUDRON_REDIS_HOST}:${REDIS_PORT}"
    else
        export REDIS_URL="redis://${CLOUDRON_REDIS_HOST}:${REDIS_PORT}"
    fi
    echo "Redis: ${CLOUDRON_REDIS_HOST}:${REDIS_PORT}"
elif [[ -z "${REDIS_URL:-}" ]]; then
    # Fallback: no Redis addon configured
    echo "WARNING: No Redis addon configured. Rate limiting will use in-memory mode."
fi

# ── Bootstrap environment ──────────────────────────────────────────────
# OmniRoute's bootstrap-env.mjs initializes the SQLite DB, runs migrations,
# and sets up default settings. We call it here before starting the server.
if [[ -f "scripts/build/bootstrap-env.mjs" ]]; then
    echo "Running bootstrap-env..."
    node scripts/build/bootstrap-env.mjs 2>&1 || echo "WARN: bootstrap-env exited with errors (continuing)"
fi

# ── OIDC seed (Cloudron OIDC addon) ───────────────────────────────────
if [[ -n "${CLOUDRON_OIDC_DISCOVERY_URL:-}" ]]; then
    echo "Cloudron OIDC detected: ${CLOUDRON_OIDC_PROVIDER_NAME:-cloudron}"
    # The OIDC settings are read from env vars by src/lib/auth/oidc.js
    # No need to seed database — the getOidcRuntimeConfig() function reads env vars first
fi

# ── Start the application ──────────────────────────────────────────────
# OmniRoute's standalone output is in .build/next/standalone/
cd /app/.build/next/standalone

# Cloudron provides gosu for privilege drop
# The upstream app uses dev/run-standalone.mjs which spawns server-ws.mjs
exec gosu cloudron:cloudron node /app/scripts/dev/run-standalone.mjs
