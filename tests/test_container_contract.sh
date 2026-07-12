#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
dockerfile="$root/tests/container/Dockerfile"
runner="$root/tests/container.sh"
tools="$root/tests/container/package.json"

test -f "$dockerfile"
test -x "$runner"
test -f "$tools"
test -f "$root/.dockerignore"

grep -Fq 'node:24.18.0-bookworm-slim@sha256:cb4e8f7c443347358b7875e717c29e27bf9befc8f5a26cf18af3c3dec80e58c5' "$dockerfile"
grep -Fq '"@openai/codex": "0.144.1"' "$tools"
grep -Fq '"typescript": "7.0.2"' "$tools"
grep -Fq '"@types/node": "24.13.3"' "$tools"
grep -Fq -- '--network none' "$runner"
grep -Fq -- '--read-only' "$runner"
grep -Fq 'suite)' "$runner"
grep -Fq 'codex-spike)' "$runner"

echo "test_container_contract: OK"
