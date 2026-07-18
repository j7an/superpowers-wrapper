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

assert_not_contains() {
  path="$1"
  text="$2"
  if grep -Fq "$text" "$root/$path"; then
    echo "unexpected text in $path: $text" >&2
    exit 1
  fi
}

assert_file ".gitignore"
assert_file "config/upstream-ref"
assert_file ".agents/plugins/marketplace.json"
assert_file "plugins/superpowers/.codex-plugin/plugin.template.json"
assert_file "scripts/adapters/codex/adapter"
assert_file "scripts/adapters/codex/validate-generated-plugin.py"
assert_file "scripts/core/validate-adapter-response.py"

assert_contains "package.json" '"type": "module"'
assert_not_contains "bin/superpowers-manager.js" "import.meta.main"
assert_contains "config/upstream-ref" "latest-release"
assert_contains ".agents/plugins/marketplace.json" '"name": "superpowers-manager"'
assert_contains ".agents/plugins/marketplace.json" '"products": ["CODEX"]'
assert_contains ".gitignore" "plugins/superpowers/.codex-plugin/plugin.json"
assert_contains ".gitignore" "plugins/.superpowers.prepare.*/"
assert_not_contains ".gitignore" "plugins/.superpowers.tmp.*/"
assert_contains "plugins/superpowers/.codex-plugin/plugin.template.json" '"name": "superpowers"'
assert_contains "plugins/superpowers/.codex-plugin/plugin.template.json" '"skills": "./skills/"'
assert_contains "AGENTS.md" 'Run `sh tests/container.sh` before declaring a change complete.'
assert_contains "AGENTS.md" "no mutation of the developer's or runner's real Codex state"
assert_contains "README.md" "sh tests/container.sh"
assert_contains "README.md" "Layers 1-3 stay offline and hermetic"
assert_contains "README.md" "Layer 4 is the Docker acceptance path"
assert_contains "README.md" "sh tests/container.sh                    # Layers 1-4: blocking Docker acceptance command"
assert_contains "README.md" "no public harness selector"
assert_contains "RELEASING.md" 'Ensure `main` is green (`sh tests/container.sh`)'
assert_contains "RELEASING.md" "sh tests/container.sh"
assert_contains "RELEASING.md" 'immutable out-of-main maintenance tag `v0.1.4`'
assert_contains "RELEASING.md" '`v0.1.5` is an immutable failed pre-publication build.'
assert_contains "RELEASING.md" 'At failure time, registry `latest` remained `superpowers-manager@0.1.4`.'
assert_contains "RELEASING.md" 'Published Manager baseline for version monotonicity: `superpowers-manager@0.1.4`.'
assert_contains "RELEASING.md" 'Advance this marker after successful publication and before another Tag Release.'
assert_contains "RELEASING.md" 'The one-time `0.1.6` recovery uses `bump=patch`.'
assert_contains "RELEASING.md" 'No npm token belongs in this recovery.'
assert_contains "RELEASING.md" 'first end-to-end OIDC validation'
assert_contains "RELEASING.md" 'Persistent pinning remains required before `0.2.0`.'
assert_contains "RELEASING.md" 'Never move, delete, or recreate `v0.1.5`.'
assert_contains "RELEASING.md" 'Never run or rerun a release workflow for `v0.1.5`, and never publish `superpowers-manager@0.1.5` by any path.'
assert_contains "RELEASING.md" 'j7an/superpowers-manager'
assert_contains "RELEASING.md" 'workflow `release.yml`'
assert_contains "RELEASING.md" 'environment `npm`'
assert_not_contains "RELEASING.md" 'npm-bootstrap'
assert_not_contains "RELEASING.md" 'NPM_BOOTSTRAP_TOKEN'
assert_not_contains "RELEASING.md" 'j7an/superpowers-wrapper'
assert_contains "tests/manual/codex-behavior-probe.sh" "Optional native-only Codex compatibility probe"
assert_not_contains "README.md" "The automated suite is fully hermetic: it uses a fake local upstream repo and a"
