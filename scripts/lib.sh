#!/bin/sh

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$root/scripts/core/common.sh"
. "$root/scripts/core/upstream.sh"
. "$root/scripts/core/provenance.sh"
. "$root/scripts/core/status.sh"
. "$root/scripts/core/lifecycle.sh"
. "$root/scripts/core/adapter.sh"
. "$root/scripts/adapters/codex/lib.sh"

# Given a JSON document as the FIRST ARGUMENT (a string), print "present" if any
# element of the top-level array <array_key> is an object whose <field> equals
# <value>, else print "absent" (exit 0). On unparseable JSON or invalid schema,
# print nothing and exit 2 so callers can fail closed rather than treat an
# unreadable listing as "absent".
# The JSON is passed as an argument (exactly as spw_json_get takes a file path),
# NOT on stdin: the here-doc below is Python's stdin (its program source), so a
# json.load(sys.stdin) here would read the program, not the caller's JSON.
spw_json_array_has() {
  json="$1"
  array_key="$2"
  field="$3"
  value="$4"
  python3 - "$json" "$array_key" "$field" "$value" <<'PY'
import json, sys
raw, array_key, field, value = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
try:
    data = json.loads(raw)
except (json.JSONDecodeError, RecursionError):
    sys.exit(2)
if not isinstance(data, dict):
    sys.exit(2)
items = data.get(array_key)
if not isinstance(items, list):
    sys.exit(2)
found = any(isinstance(i, dict) and i.get(field) == value for i in items)
print("present" if found else "absent")
PY
}

# Return 0 if <plugin_id> is installed, 1 if genuinely not installed. Fail
# closed: spw_die (exit) if the listing cannot be queried or parsed, so a
# read/parse error is never mistaken for "absent".
spw_plugin_is_installed() {
  codex_bin="$1"
  plugin_id="$2"
  if ! out=$("$codex_bin" plugin list --json 2>/dev/null); then
    spw_die "cannot list Codex plugins via '$codex_bin plugin list --json'"
  fi
  if ! result=$(spw_json_array_has "$out" "installed" "pluginId" "$plugin_id"); then
    spw_die "cannot parse output of '$codex_bin plugin list --json'"
  fi
  [ "$result" = present ]
}

# Return 0 if <marketplace_name> is registered, 1 if genuinely not registered.
# Fail closed exactly like spw_plugin_is_installed.
spw_marketplace_is_registered() {
  codex_bin="$1"
  marketplace_name="$2"
  if ! out=$("$codex_bin" plugin marketplace list --json 2>/dev/null); then
    spw_die "cannot list Codex marketplaces via '$codex_bin plugin marketplace list --json'"
  fi
  if ! result=$(spw_json_array_has "$out" "marketplaces" "name" "$marketplace_name"); then
    spw_die "cannot parse output of '$codex_bin plugin marketplace list --json'"
  fi
  [ "$result" = present ]
}
