#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$root/scripts/core/common.sh"
. "$root/scripts/adapters/codex/lib.sh"
. "$root/scripts/core/common.sh"
. "$root/scripts/core/lifecycle.sh"

if grep -Eq '^spw_(plugin_is_installed|marketplace_is_registered)\(\)' \
  "$root/scripts/adapters/codex/lib.sh"; then
  echo "dead Codex ownership adapter helpers must remain removed" >&2
  exit 1
fi

plugins='{"installed":[{"pluginId":"superpowers@superpowers-manager"},{"pluginId":"other@x"}],"available":[]}'
markets='{"marketplaces":[{"name":"openai-curated"},{"name":"superpowers-manager"}]}'

assert_fails() {
  if out=$(spw_json_array_has "$1" "$2" "$3" "$4" 2>&1); then
    echo "expected spw_json_array_has to fail for invalid schema" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  case "$out" in
    present|absent)
      echo "expected no membership result on helper failure" >&2
      printf '%s\n' "$out" >&2
      exit 1
      ;;
  esac
}

# present: value found in the named array on the named field
test "$(spw_json_array_has "$plugins" installed pluginId "superpowers@superpowers-manager")" = present
test "$(spw_json_array_has "$markets" marketplaces name "superpowers-manager")" = present

# absent: value not present
test "$(spw_json_array_has "$plugins" installed pluginId "missing@x")" = absent
test "$(spw_json_array_has "$markets" marketplaces name "missing")" = absent

# malformed schema -> non-zero exit (fail closed), no "present"/"absent" output
assert_fails '{}' installed pluginId "superpowers@superpowers-manager"
assert_fails '{"installed":{}}' installed pluginId "superpowers@superpowers-manager"
assert_fails '{"installed":[{}]}' installed pluginId "superpowers@superpowers-manager"
assert_fails '{"installed":[{"pluginId":42}]}' installed pluginId "superpowers@superpowers-manager"
assert_fails '{"installed":[null]}' installed pluginId "superpowers@superpowers-manager"
assert_fails '{"marketplaces":[{}]}' marketplaces name "superpowers-manager"
assert_fails '{"marketplaces":[{"name":42}]}' marketplaces name "superpowers-manager"
assert_fails '{"marketplaces":[null]}' marketplaces name "superpowers-manager"

# absent: empty array
test "$(spw_json_array_has '{"installed":[]}' installed pluginId "x")" = absent

# malformed JSON -> non-zero exit (fail closed), no "present"/"absent" output
assert_fails 'not json {{{' installed pluginId "x"

for state in neither manager; do
  output=$(spw_require_no_legacy_state "$state" 2>&1)
  [ -z "$output" ]
done

for state in legacy both; do
  if output=$(spw_require_no_legacy_state "$state" 2>&1); then
    echo "legacy policy must reject $state" >&2
    exit 1
  fi
  printf '%s\n' "$output" | grep -Fxq 'Legacy superpowers-wrapper Codex state is installed.'
  printf '%s\n' "$output" | grep -Fxq 'Run: npx superpowers-wrapper@0.1.1 uninstall'
  printf '%s\n' "$output" | grep -Fxq 'Then run: npx superpowers-manager install'
done

for state in neither manager; do
  output=$(spw_report_legacy_state "$state")
  [ -z "$output" ]
done

for state in legacy both; do
  output=$(spw_report_legacy_state "$state")
  printf '%s\n' "$output" | grep -Fxq 'Legacy superpowers-wrapper Codex state remains installed.'
  printf '%s\n' "$output" | grep -Fxq 'Run: npx superpowers-wrapper@0.1.1 uninstall'
done

echo "test_uninstall_helpers: OK"
