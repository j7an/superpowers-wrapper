#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

for test_file in "$root"/tests/test_*.sh; do
  echo "==> ${test_file#$root/}"
  sh "$test_file"
done
