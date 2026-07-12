#!/bin/sh
set -eu

case "$HOME" in /home/spw|/tmp/*) ;; *) echo "error: refusing non-isolated HOME: $HOME" >&2; exit 1 ;; esac

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT INT TERM
market="$root/market-a"
moved="$root/market-b"
plugin_id="wrapper-probe@superpowers-wrapper-probe"

write_market() {
  target="$1"
  commit="$2"
  mkdir -p "$target/.agents/plugins" "$target/plugins/wrapper-probe/.codex-plugin" "$target/plugins/wrapper-probe/skills/probe"
  cat > "$target/.agents/plugins/marketplace.json" <<'JSON'
{
  "name": "superpowers-wrapper-probe",
  "interface": {"displayName": "Superpowers Wrapper Probe"},
  "plugins": [{
    "name": "wrapper-probe",
    "source": {"source": "local", "path": "./plugins/wrapper-probe"},
    "policy": {
      "installation": "AVAILABLE",
      "authentication": "ON_INSTALL",
      "products": ["CODEX"]
    },
    "category": "Developer Tools"
  }]
}
JSON
  cat > "$target/plugins/wrapper-probe/.codex-plugin/plugin.json" <<'JSON'
{
  "name": "wrapper-probe",
  "version": "0.0.0+probe.abcdef0",
  "description": "Throwaway offline Codex probe.",
  "skills": "./skills/",
  "interface": {
    "displayName": "Wrapper Probe",
    "shortDescription": "Offline marketplace probe.",
    "longDescription": "Temporary local plugin used only in an isolated container.",
    "developerName": "superpowers-wrapper",
    "category": "Developer Tools",
    "capabilities": ["skills"],
    "defaultPrompt": ["Use wrapper-probe only for local marketplace testing."]
  }
}
JSON
  printf '%s\n' '---' 'name: probe' 'description: offline probe' '---' '# Probe' > "$target/plugins/wrapper-probe/skills/probe/SKILL.md"
  printf '{"commit":"%s"}\n' "$commit" > "$target/plugins/wrapper-probe/.superpowers-upstream.json"
}

write_market "$market" aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
codex plugin marketplace add "$market"
codex plugin add "$plugin_id"
test -n "$(find "$HOME/.codex" -path '*/wrapper-probe/.superpowers-upstream.json' -o -path '*/wrapper-probe/*/.superpowers-upstream.json' | head -n 1)"

cp -R "$market" "$moved"
codex plugin marketplace remove superpowers-wrapper-probe
codex plugin marketplace add "$moved"
codex plugin add "$plugin_id"

codex plugin remove "$plugin_id"
codex plugin marketplace remove superpowers-wrapper-probe

if codex plugin list --json | grep -Fq "$plugin_id"; then exit 1; fi
if codex plugin marketplace list --json | grep -Fq 'superpowers-wrapper-probe'; then exit 1; fi
echo "codex offline probe: OK"
