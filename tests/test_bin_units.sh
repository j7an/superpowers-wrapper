#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
command -v node >/dev/null 2>&1 || { echo "error: node is required for this test" >&2; exit 1; }
node "$root/tests/bin/units.test.js"
echo "test_bin_units: OK"
