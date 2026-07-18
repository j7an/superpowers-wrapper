#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
wf="$root/.github/workflows/tag-release.yml"
bump="$root/.version-bump.json"
package="$root/package.json"
release_doc="$root/RELEASING.md"

[ -f "$wf" ] || { echo "missing $wf" >&2; exit 1; }
[ -f "$bump" ] || { echo "missing $bump" >&2; exit 1; }
[ -f "$package" ] || { echo "missing $package" >&2; exit 1; }
[ -f "$release_doc" ] || { echo "missing $release_doc" >&2; exit 1; }

grep -q 'workflow_dispatch:' "$wf"
grep -Fq 'uses: j7an/shared-workflows/.github/workflows/tag-release.yml@dc9105acf09a4ad43bad2e4a86f4c65f553fe3c0 # v4.2.2' "$wf"
grep -q 'tag-prefix: "v"' "$wf"
grep -q 'RELEASE_BOT_PRIVATE_KEY: ${{ secrets.RELEASE_BOT_PRIVATE_KEY }}' "$wf"

python3 - "$bump" "$package" "$release_doc" <<'PY'
import json
import re
import sys

path, package_path, release_doc_path = sys.argv[1:]
with open(path, encoding="utf-8") as fh:
    actual = json.load(fh)

expected = {"files": [{"path": "package.json", "field": "version"}]}
if actual != expected:
    raise SystemExit(f"unexpected {path}: {actual!r}")

with open(package_path, encoding="utf-8") as fh:
    package = json.load(fh)
with open(release_doc_path, encoding="utf-8") as fh:
    release_doc = fh.read()

stable_semver = re.compile(
    r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$"
)


def parse_stable_semver(value, label):
    if not isinstance(value, str):
        raise ValueError(f"{label} is not a stable semver string: {value!r}")
    match = stable_semver.fullmatch(value)
    if match is None:
        raise ValueError(f"{label} is not stable semver: {value!r}")
    return tuple(int(part) for part in match.groups())


def assert_source_not_behind(source, baseline):
    source_version = parse_stable_semver(source, "package.json version")
    baseline_version = parse_stable_semver(
        baseline, "documented published Manager baseline"
    )
    if source_version < baseline_version:
        raise ValueError(
            "package.json version is behind the documented published Manager "
            f"baseline: {source!r} < {baseline!r}"
        )


baseline_pattern = re.compile(
    r"^Published Manager baseline for version monotonicity: "
    r"`superpowers-manager@([^`\n]+)`\.$",
    re.MULTILINE,
)


def extract_published_baseline(document):
    matches = baseline_pattern.findall(document)
    if len(matches) != 1:
        raise ValueError(
            "RELEASING.md must contain exactly one published Manager baseline "
            f"marker, found {len(matches)}"
        )
    return matches[0]


version_cases = (
    ("1.2.3", "1.2.3", True),
    ("1.2.4", "1.2.3", True),
    ("1.2.2", "1.2.3", False),
)
for source, baseline, expected_ok in version_cases:
    try:
        assert_source_not_behind(source, baseline)
    except ValueError:
        actual_ok = False
    else:
        actual_ok = True
    if actual_ok != expected_ok:
        raise SystemExit(
            "internal version-contract regression: "
            f"source={source!r}, baseline={baseline!r}, "
            f"expected_ok={expected_ok!r}"
        )

try:
    parse_stable_semver("1.2.3-beta.1", "test version")
except ValueError:
    pass
else:
    raise SystemExit("internal version-contract regression: prerelease accepted")

historical_release_text = """\
`superpowers-manager@1.0.0` and its GitHub Release were recovered.
Published Manager baseline for version monotonicity: `superpowers-manager@1.2.3`.
"""
if extract_published_baseline(historical_release_text) != "1.2.3":
    raise SystemExit(
        "internal version-contract regression: historical release overrode marker"
    )

if package.get("name") != "superpowers-manager":
    raise SystemExit(
        f"unexpected package name in {package_path}: {package.get('name')!r}"
    )

try:
    published_baseline = extract_published_baseline(release_doc)
    assert_source_not_behind(package.get("version"), published_baseline)
except ValueError as exc:
    raise SystemExit(str(exc)) from exc
PY

echo "test_tag_release_workflow: OK"
