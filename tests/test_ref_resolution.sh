#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$root/scripts/lib.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM

cat > "$tmpdir/ls-remote-tags.txt" <<'EOF'
1111111111111111111111111111111111111111	refs/tags/v6.0.2
2222222222222222222222222222222222222222	refs/tags/v6.0.2^{}
3333333333333333333333333333333333333333	refs/tags/v6.0.10
4444444444444444444444444444444444444444	refs/tags/v6.0.10^{}
5555555555555555555555555555555555555555	refs/tags/v6.1.0-beta.1
EOF

selected=$(spw_select_latest_release_from_ls_remote < "$tmpdir/ls-remote-tags.txt")
if [ "$selected" != "v6.0.10 4444444444444444444444444444444444444444" ]; then
  echo "unexpected latest release: $selected" >&2
  exit 1
fi

version=$(spw_manifest_version_for_commit "896224c4b1879920ab573417e68fd51d2ccc9072")
if [ "$version" != "0.0.0+wrapper.896224c" ]; then
  echo "unexpected manifest version: $version" >&2
  exit 1
fi

if spw_select_latest_release_from_ls_remote < /dev/null >/dev/null 2>&1; then
  echo "expected empty tag list to fail" >&2
  exit 1
fi
