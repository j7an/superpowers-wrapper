#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$root/scripts/lib.sh"

desired="896224c4b1879920ab573417e68fd51d2ccc9072"

test "$(spw_status_for_commits "$desired" "" "")" = "needs prepare"
test "$(spw_status_for_commits "$desired" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" "")" = "needs prepare"
test "$(spw_status_for_commits "$desired" "$desired" "")" = "needs install"
test "$(spw_status_for_commits "$desired" "$desired" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")" = "needs install"
test "$(spw_status_for_commits "$desired" "$desired" "$desired")" = "current"
test "$(spw_status_for_commits "$desired" "$desired" "896224c")" = "current"

# spw_commit_matches: full-sha match, 7-char short-sha match, mismatch, and
# the load-bearing empty-observed invariant (empty must NOT match).
spw_commit_matches "$desired" "$desired"
spw_commit_matches "$desired" "896224c"
! spw_commit_matches "$desired" "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
! spw_commit_matches "$desired" ""

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM
mkdir -p "$tmpdir/plugin/.codex-plugin"
cat > "$tmpdir/plugin/.codex-plugin/plugin.json" <<'JSON'
{
  "name": "superpowers",
  "version": "0.0.0+wrapper.896224c"
}
JSON
short=$(spw_manifest_short_sha_or_empty "$tmpdir/plugin/.codex-plugin/plugin.json")
test "$short" = "896224c"

# The template's placeholder version is not a real fingerprint -> empty.
cat > "$tmpdir/plugin/.codex-plugin/plugin.json" <<'JSON'
{
  "name": "superpowers",
  "version": "0.0.0+wrapper.template"
}
JSON
template_short=$(spw_manifest_short_sha_or_empty "$tmpdir/plugin/.codex-plugin/plugin.json")
test -z "$template_short"
