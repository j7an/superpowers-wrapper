# Codex Local Marketplace Behavior

Date: 2026-06-19 (probe run 2026-06-20)
Codex CLI: `codex-cli 0.141.0`

Probe command:

```bash
sh tests/manual/codex-behavior-probe.sh | tee /tmp/superpowers-wrapper-codex-behavior.txt
```

The probe registers a throwaway local marketplace `superpowers-wrapper-probe`
with a single plugin `wrapper-probe`, installs commit A, mutates the source to
commit B, and observes which refresh verb (add-only, marketplace re-add, or
remove/add) updates the installed copy. It then checks where the installed
copy lives and whether a `session-start` hook auto-activates. It only ever
touches `wrapper-probe@superpowers-wrapper-probe`; it never touches
`superpowers@openai-curated`.

## Conclusions

### Q1 — Does `plugin add` alone (no marketplace re-add) refresh a mutated local source? YES

After mutating the source from commit A (`0.0.0+probe.a`) to commit B
(`0.0.0+probe.b`) and running **only** `codex plugin add` (no marketplace
re-add), the installed plugin root advanced to the `0.0.0+probe.b` directory.
For a local marketplace, `plugin add` re-reads the live source path, so
add-only refresh works.

→ **`scripts/install` keeps `add-only` as the default refresh mode.** It still
runs `marketplace add` before `plugin add` (harmless — Codex reports "already
added" — and required for the first-ever install).

### Q2 — Is remove/add required for refresh? NO

remove/add also produced the `0.0.0+probe.b` root, but it is not necessary
because add-only already refreshed. `remove-add` remains available as a
fallback via `SUPERPOWERS_INSTALL_REFRESH_MODE=remove-add` and is the hint
`scripts/update` prints if a post-install re-probe ever detects staleness.

`scripts/install` only ever removes its own id (`superpowers@superpowers-wrapper`);
it never removes `superpowers@openai-curated`.

### Q3 — Where does the installed copy live? Versioned cache directory

```
~/.codex/plugins/cache/<marketplace>/<plugin>/<version>/...
```

Observed for the probe:
`~/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/0.0.0+probe.b/`

Confirmed against the live `superpowers@openai-curated` install, which has the
same shape with the commit short-sha as the version segment:
`~/.codex/plugins/cache/openai-curated/superpowers/202e9242/` — containing the
copied `LICENSE`, `README.md`, `CODE_OF_CONDUCT.md`, `skills/`, `assets/`, and
`.codex-plugin/plugin.json`. Root-level files (including the wrapper's
`.superpowers-upstream.json`) are copied into this versioned directory.

The probe printed "Installed metadata path: not found" for its own
`.wrapper-probe-upstream.json`. This is a **false negative of the probe's
`find` glob** (`*/wrapper-probe/.wrapper-probe-upstream.json`), which anchors
the file directly under the plugin name and so cannot match across the
intervening `<version>/` segment — not evidence that Codex dropped the file.

→ **Fix applied to `scripts/lib.sh`:** `spw_find_installed_metadata` and
`spw_find_installed_manifest` now match both the versioned layout
(`*/superpowers/*/...`) and the flat layout (`*/superpowers/...`). Verified
against the live install (the versioned-cache copy now resolves) and locked in
by `tests/test_installed_finders.sh`. Without this fix `scripts/probe` and the
`scripts/update` post-install self-verification could never detect the
installed commit and would always report `unverifiable`.

### Q4 — Does a copied `session-start` hook auto-activate? NOT via `codex exec`

The hook sentinel was unwritten both before and after `codex exec`. Per the
plan, automatic session-start activation stays out of scope; copied `hooks/`
are runtime files only. (A fresh interactive Codex session was not exercised
here; if hook activation is ever desired it needs separate investigation.)

### Q5 — Does add-only refresh from a stable-looking version to a branch-looking version? YES

The probe installed `6.0.3+wrapper.ccccccc`, mutated the same local marketplace
source to `0.0.0-main+wrapper.ddddddd`, and ran `codex plugin add` without
removing the plugin first. Codex replaced the installed cache with the
`0.0.0-main+wrapper.ddddddd` directory, so the lower SemVer precedence of the
branch-looking version did not block refresh.

`add-only` remains the default. `remove-add` remains available as the
wrapper-only fallback if `scripts/update` ever detects a stale installed cache.

## Raw Probe Output

```text
Q1/Q2/Q3 probe root: /var/folders/w1/7tvmnnfd49s8qxfdnz2jl82c0000gn/T//superpowers-wrapper-codex-probe
Register marketplace and install commit A
Added marketplace `superpowers-wrapper-probe` from /private/var/folders/w1/7tvmnnfd49s8qxfdnz2jl82c0000gn/T/superpowers-wrapper-codex-probe.
Installed marketplace root: /private/var/folders/w1/7tvmnnfd49s8qxfdnz2jl82c0000gn/T/superpowers-wrapper-codex-probe
Added plugin `wrapper-probe` from marketplace `superpowers-wrapper-probe`.
Installed plugin root: /Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/0.0.0+probe.a
Installed metadata path: not found
Mutate source to commit B
Run plugin add without marketplace re-add
Added plugin `wrapper-probe` from marketplace `superpowers-wrapper-probe`.
Installed plugin root: /Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/0.0.0+probe.b
Installed metadata path after add-only refresh: not found
Run marketplace add, then plugin add
Marketplace `superpowers-wrapper-probe` is already added from /private/var/folders/w1/7tvmnnfd49s8qxfdnz2jl82c0000gn/T/superpowers-wrapper-codex-probe.
Installed marketplace root: /private/var/folders/w1/7tvmnnfd49s8qxfdnz2jl82c0000gn/T/superpowers-wrapper-codex-probe
Added plugin `wrapper-probe` from marketplace `superpowers-wrapper-probe`.
Installed plugin root: /Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/0.0.0+probe.b
Run wrapper-plugin remove, then plugin add
Removed plugin `wrapper-probe` from marketplace `superpowers-wrapper-probe`.
Added plugin `wrapper-probe` from marketplace `superpowers-wrapper-probe`.
Installed plugin root: /Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/0.0.0+probe.b
Stable-to-branch version precedence probe
Added plugin `wrapper-probe` from marketplace `superpowers-wrapper-probe`.
Installed plugin root: /Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/6.0.3+wrapper.ccccccc
Installed root after stable-looking add:
/Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/6.0.3+wrapper.ccccccc
Added plugin `wrapper-probe` from marketplace `superpowers-wrapper-probe`.
Installed plugin root: /Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/0.0.0-main+wrapper.ddddddd
Installed root after stable-to-branch add-only refresh:
/Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/0.0.0-main+wrapper.ddddddd
Removed plugin `wrapper-probe` from marketplace `superpowers-wrapper-probe`.
Added plugin `wrapper-probe` from marketplace `superpowers-wrapper-probe`.
Installed plugin root: /Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/0.0.0-main+wrapper.ddddddd
Installed root after stable-to-branch remove/add refresh:
/Users/j7an/.codex/plugins/cache/superpowers-wrapper-probe/wrapper-probe/0.0.0-main+wrapper.ddddddd
Hook sentinel before new-session probe:
not written
Run a noninteractive session to check hook activation
Hook sentinel after codex exec:
not written
```
