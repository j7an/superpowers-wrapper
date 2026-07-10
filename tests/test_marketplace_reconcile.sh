#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$root/scripts/lib.sh"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM

# --- spw_marketplace_root_from_json ---
json='{"marketplaces":[{"name":"openai-curated","root":"/x"},{"name":"superpowers-wrapper","root":"/y"}]}'
out=$(spw_marketplace_root_from_json "$json" superpowers-wrapper)
[ "$out" = "/y" ] || { echo "expected /y, got '$out'" >&2; exit 1; }

out=$(spw_marketplace_root_from_json '{"marketplaces":[{"name":"openai-curated","root":"/x"}]}' superpowers-wrapper)
[ -z "$out" ] || { echo "expected empty for absent, got '$out'" >&2; exit 1; }

if spw_marketplace_root_from_json 'not json {{{' superpowers-wrapper >/dev/null 2>&1; then
  echo "malformed JSON must fail closed" >&2; exit 1
fi
if spw_marketplace_root_from_json '{"unexpected":[]}' superpowers-wrapper >/dev/null 2>&1; then
  echo "schema drift must fail closed" >&2; exit 1
fi
if spw_marketplace_root_from_json '{"marketplaces":[{"name":"superpowers-wrapper","root":""}]}' superpowers-wrapper >/dev/null 2>&1; then
  echo "empty root must fail closed" >&2; exit 1
fi

# --- spw_paths_equal: symlinked roots are the same physical location.
# This is the portable equivalent of macOS /var vs /private/var. ---
mkdir -p "$tmpdir/real"
ln -s "$tmpdir/real" "$tmpdir/link"
[ "$(spw_paths_equal "$tmpdir/real" "$tmpdir/link")" = same ]
[ "$(spw_paths_equal "$tmpdir/real" "$tmpdir")" = different ]
# Nonexistent paths fall back to string comparison.
[ "$(spw_paths_equal /no/such/path-a /no/such/path-a)" = same ]
[ "$(spw_paths_equal /no/such/path-a /no/such/path-b)" = different ]

# --- spw_verify_refresh: compares installed metadata to the desired commit
# passed by the caller; it must not call scripts/probe or resolve upstream after
# Codex has already been mutated.
desired="abcdef0123456789abcdef0123456789abcdef01"
installed_root="$tmpdir/codex/plugins/cache/superpowers-wrapper/superpowers/1.0.0"
mkdir -p "$installed_root"
cat > "$installed_root/.superpowers-upstream.json" <<EOF
{"commit":"$desired"}
EOF
out=$(SUPERPOWERS_INSTALLED_SEARCH_ROOT="$tmpdir/codex" spw_verify_refresh "$desired")
printf '%s\n' "$out" | grep -Fq "wrapper updated"
printf '%s\n' "$out" | grep -Fq "installed_commit=$desired"

if (SUPERPOWERS_INSTALLED_SEARCH_ROOT="$tmpdir/codex" spw_verify_refresh "1111111111111111111111111111111111111111") >"$tmpdir/stale.out" 2>&1; then
  echo "stale installed metadata must fail" >&2; exit 1
fi
grep -Fq "still stale" "$tmpdir/stale.out"

rm -rf "$tmpdir/codex"
out=$(SUPERPOWERS_INSTALLED_SEARCH_ROOT="$tmpdir/codex" spw_verify_refresh "$desired" 2>&1)
printf '%s\n' "$out" | grep -Fq "installed wrapper not detectable"

echo "test_marketplace_reconcile: OK"
