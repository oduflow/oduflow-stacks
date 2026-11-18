FROM node:24-bookworm-slim

ARG TARGETARCH
ARG AMP_VERSION=0.0.1795017641-g2e763e
ARG CODEX_VERSION=0.170.0

LABEL org.opencontainers.image.title="Multica Runtime Machine" \
      org.opencontainers.image.version="0.11.0-2" \
      org.opencontainers.image.description="Non-root Multica daemon with Amp and Codex; no embedded credentials"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git jq openssh-client python3 python3-venv ripgrep tini \
    && rm -rf /var/lib/apt/lists/*

# Use a release asset rather than the installer, which can also provision a server.
# Digests are from the v0.11.0 GitHub release asset metadata.
RUN set -eu; \
    TARGETARCH="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$TARGETARCH" in \
      arm64) checksum=924b34eeee4a1680c4e72853b45de1ce6a33f3a84d5c98a8963d8ccaa398feb1 ;; \
      amd64) checksum=0d5150c8257d814c29b82e091d2da393deb5fc0306d8c391fda66c557e0993ea ;; \
      *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL --retry 3 \
      "https://github.com/multica-ai/multica/releases/download/v0.11.0/multica-cli-0.11.0-linux-${TARGETARCH}.tar.gz" \
      -o /tmp/multica.tar.gz; \
    echo "$checksum  /tmp/multica.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/multica.tar.gz -C /usr/local/bin multica; \
    chmod 0755 /usr/local/bin/multica; \
    rm /tmp/multica.tar.gz

RUN npm install --global \
        "@sourcegraph/amp@${AMP_VERSION}" \
        "@openai/codex@${CODEX_VERSION}" \
    && npm cache clean --force

ENV HOME=/home/node \
    CODEX_HOME=/home/node/.codex \
    NPM_CONFIG_PREFIX=/home/node/.npm-global \
    PATH="/home/node/.npm-global/bin:${PATH}" \
    MULTICA_WORKSPACES_ROOT=/home/node/workspaces \
    MULTICA_DAEMON_DEVICE_NAME="Oduflow Docker Machine" \
    MULTICA_DAEMON_MAX_CONCURRENT_TASKS=1 \
    MULTICA_DAEMON_AUTO_UPDATE=false \
    MULTICA_DAEMON_AUTO_RELOAD=false

RUN install -d -m 0700 -o node -g node \
        /home/node/.multica /home/node/.codex /home/node/workspaces

COPY entrypoint.sh /usr/local/bin/multica-runtime-entrypoint
RUN chmod 0755 /usr/local/bin/multica-runtime-entrypoint

USER node
WORKDIR /home/node

# Build-time checks do not authenticate or start a daemon.
RUN multica version \
    && amp --version \
    && codex --version \
    && git --version \
    && python3 --version \
    && multica daemon start --help | grep -q -- --foreground

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/multica-runtime-entrypoint"]
CMD ["daemon", "start", "--foreground", "--no-auto-update", "--no-auto-reload"]
