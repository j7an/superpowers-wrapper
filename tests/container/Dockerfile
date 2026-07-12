FROM node:24.18.0-bookworm-slim@sha256:cb4e8f7c443347358b7875e717c29e27bf9befc8f5a26cf18af3c3dec80e58c5

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates git python3 ruby \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/spw-test-tools
COPY tests/container/package.json tests/container/package-lock.json ./
RUN npm ci --ignore-scripts \
    && test "$(./node_modules/.bin/codex --version | awk '{print $NF}')" = "0.144.1"

RUN useradd --create-home --uid 10001 spw
WORKDIR /workspace
COPY . .
RUN chown -R root:root /workspace /opt/spw-test-tools \
    && chmod +x tests/container.sh tests/container/codex-offline-probe.sh

ENV HOME=/home/spw
ENV PATH=/opt/spw-test-tools/node_modules/.bin:$PATH
USER spw
ENTRYPOINT ["sh", "tests/container.sh", "--inside"]
