#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM

fake_codex="$tmpdir/codex"
log="$tmpdir/codex.log"
cat > "$fake_codex" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$log"
exit 0
EOF
chmod +x "$fake_codex"

SUPERPOWERS_CODEX="$fake_codex" SUPERPOWERS_INSTALL_REFRESH_MODE="add-only" sh "$root/scripts/install"

grep -Fq "plugin marketplace add $root" "$log"
grep -Fq "plugin add superpowers@superpowers-wrapper" "$log"
# Order matters: the marketplace must be re-snapshotted before install.
mp_line=$(grep -Fn "plugin marketplace add" "$log" | head -n1 | cut -d: -f1)
pa_line=$(grep -Fn "plugin add superpowers@superpowers-wrapper" "$log" | head -n1 | cut -d: -f1)
[ "$mp_line" -lt "$pa_line" ] || { echo "marketplace add must precede plugin add" >&2; exit 1; }
if grep -Fq "openai-curated" "$log"; then
  echo "install script must not touch openai-curated" >&2
  exit 1
fi

: > "$log"
SUPERPOWERS_CODEX="$fake_codex" SUPERPOWERS_INSTALL_REFRESH_MODE="remove-add" sh "$root/scripts/install"
grep -Fq "plugin remove superpowers@superpowers-wrapper" "$log"
grep -Fq "plugin add superpowers@superpowers-wrapper" "$log"
# Order: marketplace add, then wrapper-only remove, then plugin add.
mp_line=$(grep -Fn "plugin marketplace add" "$log" | head -n1 | cut -d: -f1)
rm_line=$(grep -Fn "plugin remove superpowers@superpowers-wrapper" "$log" | head -n1 | cut -d: -f1)
pa_line=$(grep -Fn "plugin add superpowers@superpowers-wrapper" "$log" | head -n1 | cut -d: -f1)
{ [ "$mp_line" -lt "$rm_line" ] && [ "$rm_line" -lt "$pa_line" ]; } || { echo "order must be: marketplace add, remove, plugin add" >&2; exit 1; }
if grep -Fq "openai-curated" "$log"; then
  echo "remove-add mode must not touch openai-curated" >&2
  exit 1
fi
