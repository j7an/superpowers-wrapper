#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM

upstream="$tmpdir/upstream"
output="$tmpdir/out"
template="$root/plugins/superpowers/.codex-plugin/plugin.template.json"
template_before=$(cksum "$template")

mkdir -p "$upstream/skills/brainstorming" "$upstream/assets" "$upstream/hooks" "$upstream/.codex-plugin"
git -C "$tmpdir" init upstream >/dev/null
cat > "$upstream/skills/brainstorming/SKILL.md" <<'EOF'
---
name: brainstorming
description: Fake upstream skill
---
# Brainstorming
EOF
printf 'asset\n' > "$upstream/assets/superpowers-small.svg"
printf '#!/bin/sh\n' > "$upstream/hooks/session-start-codex"
printf 'license\n' > "$upstream/LICENSE"
printf 'readme\n' > "$upstream/README.md"
printf 'code\n' > "$upstream/CODE_OF_CONDUCT.md"
cat > "$upstream/.codex-plugin/plugin.json" <<'JSON'
{
  "name": "superpowers",
  "version": "6.0.3",
  "hooks": "./hooks/hooks-codex.json"
}
JSON
git -C "$upstream" add .
git -C "$upstream" -c user.email=superpowers-wrapper@example.invalid -c user.name=superpowers-wrapper commit -m "fake upstream" >/dev/null
git -C "$upstream" -c user.email=superpowers-wrapper@example.invalid -c user.name=superpowers-wrapper tag -a v6.0.3 -m "fake release"
commit=$(git -C "$upstream" rev-list -n1 v6.0.3)

SUPERPOWERS_UPSTREAM_URL="$upstream" \
SUPERPOWERS_CACHE_DIR="$tmpdir/cache" \
SUPERPOWERS_PLUGIN_ROOT="$output" \
sh "$root/scripts/prepare"

metadata="$output/.superpowers-upstream.json"
manifest="$output/.codex-plugin/plugin.json"

test -f "$output/skills/brainstorming/SKILL.md"
test -f "$output/assets/superpowers-small.svg"
test -f "$output/hooks/session-start-codex"
test -f "$output/LICENSE"
test -f "$output/README.md"
test -f "$output/CODE_OF_CONDUCT.md"

actual_commit=$(python3 - "$metadata" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["commit"])
PY
)
if [ "$actual_commit" != "$commit" ]; then
  echo "metadata commit mismatch: $actual_commit != $commit" >&2
  exit 1
fi

version=$(python3 - "$manifest" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["version"])
PY
)
case "$version" in
  0.0.0+wrapper.*) ;;
  *) echo "unexpected wrapper version: $version" >&2; exit 1 ;;
esac

if grep -Fq '"hooks"' "$manifest"; then
  echo "manifest must not contain unsupported hooks field" >&2
  exit 1
fi

template_after=$(cksum "$template")
if [ "$template_before" != "$template_after" ]; then
  echo "prepare test must not mutate the committed manifest template" >&2
  exit 1
fi
