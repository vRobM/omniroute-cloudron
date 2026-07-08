# ── Common base with runtime deps ──────────────────────────────────────────
FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c AS base

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# ── Builder ────────────────────────────────────────────────────────────────
FROM node:24-trixie-slim AS builder

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends python3 make g++ git ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone upstream source (not in git repo to avoid exposing OAuth credentials)
ARG UPSTREAM_REPO=https://github.com/diegosouzapw/OmniRoute.git
ARG UPSTREAM_REF=main
RUN git clone --depth 1 --branch ${UPSTREAM_REF} ${UPSTREAM_REPO} /tmp/omniroute-src

# Copy package manifests first for layer caching
RUN mkdir -p open-sse scripts/build \
  && cp /tmp/omniroute-src/package*.json ./ \
  && cp /tmp/omniroute-src/open-sse/package.json ./open-sse/ \
  && cp /tmp/omniroute-src/scripts/build/postinstall.mjs ./scripts/build/ \
  && cp /tmp/omniroute-src/scripts/build/postinstallSupport.mjs ./scripts/build/ \
  && cp /tmp/omniroute-src/scripts/build/native-binary-compat.mjs ./scripts/build/

ENV NPM_CONFIG_LEGACY_PEER_DEPS=true

RUN test -f package-lock.json \
  || (echo "package-lock.json is required for reproducible Docker builds" >&2 && exit 1) \
  && npm ci --no-audit --no-fund --legacy-peer-deps --ignore-scripts \
  && npm rebuild better-sqlite3 \
  && node -e "require('better-sqlite3')(':memory:').close()"

# Build with Turbopack (stable in Next 16)
ENV OMNIROUTE_USE_TURBOPACK=1
# Keep MITM manager as graceful stub in Docker (no host DNS/cert access)
ENV OMNIROUTE_MITM_STUB=1

ARG OMNIROUTE_BUILD_MEMORY_MB=4096
ENV NODE_OPTIONS="--max-old-space-size=${OMNIROUTE_BUILD_MEMORY_MB}"

# Copy full source and build
RUN cp -a /tmp/omniroute-src/. ./ && rm -rf /tmp/omniroute-src/.git
RUN mkdir -p /app/data && npm run build

# ── Runner base ────────────────────────────────────────────────────────────
FROM base AS runner-base

LABEL org.opencontainers.image.title="omniroute" \
  org.opencontainers.image.description="Unified AI proxy — route any LLM through one endpoint" \
  org.opencontainers.image.url="https://omniroute.online" \
  org.opencontainers.image.source="https://github.com/diegosouzapw/OmniRoute" \
  org.opencontainers.image.licenses="MIT"

ENV NODE_ENV=production
ENV PORT=20128
ENV HOSTNAME=0.0.0.0
ENV OMNIROUTE_MEMORY_MB=512
ENV NODE_OPTIONS="--max-old-space-size=${OMNIROUTE_MEMORY_MB}"

ENV DATA_DIR=/app/data
RUN mkdir -p /app/data

# Copy Next.js standalone output
COPY --from=builder /app/.build/next/standalone ./
# better-sqlite3 native module
COPY --from=builder /app/node_modules/better-sqlite3 ./node_modules/better-sqlite3
# Migrations directory
ENV OMNIROUTE_MIGRATIONS_DIR=/app/migrations

# Healthcheck script
COPY --from=builder /app/scripts/dev/healthcheck.mjs ./healthcheck.mjs

# Install runtime native rebuild deps (better-sqlite3 may need them)
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

# Cloudron expects gosu, drop privileges via entrypoint
COPY start.sh ./
RUN chmod +x start.sh

EXPOSE 20128

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["node", "healthcheck.mjs"]

CMD ["./start.sh"]
