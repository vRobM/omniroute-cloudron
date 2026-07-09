# OmniRoute — Cloudron single-stage build
# Based on the proven 9router pattern (single-stage, no COPY --from)
FROM docker.io/cloudron/base:5.0.0

LABEL org.opencontainers.image.title="omniroute" \
  org.opencontainers.image.description="Unified AI proxy — route any LLM through one endpoint" \
  org.opencontainers.image.url="https://omniroute.online" \
  org.opencontainers.image.source="https://github.com/diegosouzapw/OmniRoute" \
  org.opencontainers.image.licenses="MIT"

# System deps for build and runtime (skip upgrade to speed up build)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates curl git python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js 24 via nodesource
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

# Verify
RUN node --version && npm --version

WORKDIR /app

# Clone upstream source
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

# Install dependencies (ignore scripts, then rebuild native modules)
RUN test -f package-lock.json \
  || (echo "package-lock.json is required for reproducible Docker builds" >&2 && exit 1) \
  && npm ci --no-audit --no-fund --legacy-peer-deps --ignore-scripts \
  && npm rebuild better-sqlite3 \
  && node -e "require('better-sqlite3')(':memory:').close()"

# Build configuration — Turbopack uses less memory than webpack
ENV OMNIROUTE_USE_TURBOPACK=1
ENV OMNIROUTE_MITM_STUB=1
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Copy full source and build
RUN cp -a /tmp/omniroute-src/. ./ && rm -rf /tmp/omniroute-src/.git
RUN mkdir -p /app/data && npm run build

# Production config
ENV NODE_ENV=production
ENV PORT=20128
ENV HOSTNAME=0.0.0.0
ENV OMNIROUTE_MEMORY_MB=512
ENV NODE_OPTIONS="--max-old-space-size=512"
ENV DATA_DIR=/app/data
ENV OMNIROUTE_MIGRATIONS_DIR=/app/migrations

# Cloudron expects gosu, drop privileges via entrypoint
COPY start.sh CloudronManifest.json ./
RUN chmod +x start.sh

EXPOSE 20128

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["node", "scripts/dev/healthcheck.mjs"]

CMD ["./start.sh"]
