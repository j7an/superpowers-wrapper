#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

assert_file() {
  path="$1"
  if [ ! -f "$root/$path" ]; then
    echo "missing file: $path" >&2
    exit 1
  fi
}

assert_contains() {
  path="$1"
  text="$2"
  if ! grep -Fq "$text" "$root/$path"; then
    echo "missing text in $path: $text" >&2
    exit 1
  fi
}

assert_file ".gitignore"
assert_file "config/upstream-ref"
assert_file ".agents/plugins/marketplace.json"
assert_file "bin/superpowers-manager.js"
assert_file "plugins/superpowers/.codex-plugin/plugin.template.json"

if [ -e "$root/bin/superpowers-wrapper.js" ]; then
  echo "deprecated executable must not ship" >&2
  exit 1
fi
if grep -Fq '"superpowers-wrapper"' "$root/package.json"; then
  echo "old npm/bin identity remains in package.json" >&2
  exit 1
fi

assert_contains "config/upstream-ref" "latest-release"
assert_contains "package.json" '"name": "superpowers-manager"'
assert_contains "package.json" '"version": "0.1.2"'
assert_contains "package.json" '"superpowers-manager": "bin/superpowers-manager.js"'
assert_contains ".agents/plugins/marketplace.json" '"name": "superpowers-manager"'
assert_contains ".agents/plugins/marketplace.json" '"products": ["CODEX"]'
assert_contains ".gitignore" "plugins/superpowers/.codex-plugin/plugin.json"
assert_contains "scripts/lib.sh" 'SPW_PLUGIN_ID="superpowers@superpowers-manager"'
assert_contains "scripts/lib.sh" 'SPW_MARKETPLACE_NAME="superpowers-manager"'
assert_contains "scripts/update" 'echo "manager is current"'
assert_contains "scripts/probe" 'installed manager commit or fingerprint:'
assert_contains "plugins/superpowers/.codex-plugin/plugin.template.json" '"name": "superpowers"'
assert_contains "plugins/superpowers/.codex-plugin/plugin.template.json" '"version": "0.0.0+manager.template"'
assert_contains "plugins/superpowers/.codex-plugin/plugin.template.json" '"skills": "./skills/"'
