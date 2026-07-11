#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
python3 -S "$root/tests/test_validate_generated_plugin.py"
echo "test_validate_generated_plugin: OK"
