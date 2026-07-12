#!/bin/sh

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$root/scripts/core/common.sh"
. "$root/scripts/core/upstream.sh"
. "$root/scripts/core/provenance.sh"
. "$root/scripts/core/status.sh"
. "$root/scripts/core/lifecycle.sh"
. "$root/scripts/core/adapter.sh"
. "$root/scripts/adapters/codex/lib.sh"
