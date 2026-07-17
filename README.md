# Superpowers Manager

Install and update the latest stable
[`obra/superpowers`](https://github.com/obra/superpowers) release directly from
upstream, without waiting for agent marketplaces to catch up.
Codex supported today.

> Unofficial community integration. Not affiliated with the
> `obra/superpowers` maintainers.

## Quick start

```sh
npx superpowers-manager install
npx superpowers-manager probe
npx superpowers-manager update
```

Use the official marketplace for the simplest native Codex installation. Use
Superpowers Manager when you want immediate stable-upstream freshness after a
user-triggered install/update, per-invocation release or commit selection,
recorded upstream provenance, diagnostics, Codex-specific hook-free packaging,
and explicit install/update/probe/uninstall lifecycle control.

| Choose | Best fit |
|---|---|
| Official marketplace | Simplest Codex-native installation and marketplace-managed cadence |
| `superpowers-manager` | Direct stable-upstream freshness when invoked, exact ref selection, provenance, diagnostics, and lifecycle control |

### Moving from `superpowers-wrapper`

```sh
npx superpowers-wrapper@0.1.1 uninstall
npx superpowers-manager install
```

The manager detects legacy wrapper-owned Codex state and stops before mutation.
It never removes the legacy provider automatically.

## Requirements and platforms

Superpowers Manager requires Node 24+, `git`, Python 3, and a POSIX `sh`.
Codex CLI is required for `probe`, `install`, `update`, and `uninstall`;
`prepare` does not require it.

macOS and Linux are tested. WSL2 is supported. The native Windows path is
untested; the launcher looks for Git Bash, `git`, and `python3`, but path
handling between MSYS and Codex remains a known risk area.

Prepare, install, probe, and update resolve the requested upstream ref over the
network. Updates are user-triggered and need upstream network access; the
manager does not run automatic or background updates.

## What it does

- Resolves an upstream ref, defaulting to the latest stable `vX.Y.Z` release
  tag.
- Clones/fetches upstream at that commit and assembles a Codex plugin tree under
  `plugins/superpowers/` (skills, assets, license/readme, and manifest;
  upstream's `hooks/` directory is deliberately excluded).
- Stamps the generated manifest with a ref-aware manager version ending in
  `+manager.<short-sha>` and writes the upstream provenance to
  `.superpowers-upstream.json`.
- Validates the generated tree with the manager's shipped, Python-standard-library
  contract validator before swapping it into place (a failed run never destroys
  a previously generated tree).
- Registers the `superpowers-manager` marketplace and installs or refreshes
  `superpowers@superpowers-manager` in Codex.

The generated plugin carries upstream skills, assets, and documentation. The
manager excludes upstream `hooks/`, removes the manifest `hooks` field, and
validates that both stay absent. This is a Codex-specific adapter policy, not a
claim about how Superpowers should be packaged for future or other harnesses.
Changing the hook-free policy requires a separate design and current
compatibility evidence.

## Runtime architecture

- `scripts/core/` owns the shared lifecycle, status, and protocol validation.
- `scripts/adapters/codex/` owns build, inspection, reconciliation, and Codex
  mutation.
- Codex is the only supported adapter today; no public harness selector ships
  yet.

Validation checks the manager-owned manifest overlay, generated-tree structure,
skill frontmatter envelope, known local paths, and provenance. It deliberately
does not implement a general YAML parser or mirror every Codex ingestion rule;
upstream owns skill semantics and Codex owns its evolving schema.

`SUPERPOWERS_VALIDATOR=/path/to/validator.py` adds an optional Python validator
after the built-in check. It receives the candidate plugin root as its only
argument. It cannot replace or bypass built-in validation, and either check
failing prevents the tree swap and all Codex mutation.

Direct `scripts/install` keeps harness-specific validation in the Codex adapter:
phase 1 prepares the exact candidate first, then the adapter performs its Codex
and refresh-mode preflight before any Codex mutation. The Node dispatcher keeps
its existing Codex preflight before dispatching to the shell lifecycle.

## Provider ownership

If another `superpowers` provider is installed, remove or disable it yourself
before installing this one. The manager never removes another provider and
mutates only `superpowers@superpowers-manager` and the `superpowers-manager`
marketplace.

For example, if you intentionally want the manager to take over from the
official provider:

```sh
codex plugin remove superpowers@openai-curated
npx superpowers-manager install
```

Manager install, update, and uninstall commands inspect both current and legacy
identities and fail closed when Codex state cannot be read or parsed. If legacy
`superpowers-wrapper` state remains, use the migration commands above; the
manager will not remove it for you.

## Lifecycle commands

| Command | Codex side effects | Purpose |
|---|---|---|
| `npx superpowers-manager prepare` | None | Resolve upstream, build a staged plugin tree, validate it, and replace the generated tree only on success |
| `npx superpowers-manager probe` | None | Report requested and resolved refs, desired/generated/installed commits, identity state, and status |
| `npx superpowers-manager install` | Marketplace and plugin state | Prepare and validate, register the marketplace, install the plugin, and verify installed state |
| `npx superpowers-manager update` | Marketplace and plugin state when stale | Probe, prepare and/or install as needed, then verify the refresh |
| `npx superpowers-manager uninstall` | Marketplace and plugin state | Remove only manager-owned Codex state and verify removal |

Calling `npx superpowers-manager` without a subcommand is equivalent to
`update`. `probe` is read-only. Install and update stop before prepare or Codex
mutation when legacy state is present. Uninstall removes only manager-owned
state and reports any legacy residue without modifying it. These commands fail
closed when required state cannot be inspected and refuse to report success
when resulting manager state cannot be verified.

## Choosing the upstream version

`SUPERPOWERS_REF` selects a stable release tag, full commit SHA, branch, or
other resolvable upstream ref for that invocation. The stateless npx package
records the requested ref, resolved ref, and exact commit, but does not persist
the selection for a later invocation that omits `SUPERPOWERS_REF`.

Without `SUPERPOWERS_REF`, the manager reads `config/upstream-ref`, which ships
as `latest-release`. Accepted values include:

- `latest-release` — highest stable `vX.Y.Z` tag (prereleases are excluded).
- A specific tag, e.g. `v6.0.3`.
- A full 40-character commit SHA.
- Any other ref upstream resolves (e.g. a branch name).

```sh
SUPERPOWERS_REF=v6.0.3 npx superpowers-manager prepare
SUPERPOWERS_REF=main npx superpowers-manager probe
SUPERPOWERS_REF=feature/foo npx superpowers-manager install
SUPERPOWERS_REF=latest-release npx superpowers-manager update
```

`SUPERPOWERS_CACHE_DIR` may point to a persistent upstream clone cache to avoid
re-cloning between package materializations. It caches Git objects; it does not
persist ref selection or trigger updates.

## How versioning works

- **Upstream manifest first:** when upstream provides
  `.codex-plugin/plugin.json`, `prepare` uses it as the generated manifest base
  so future upstream metadata fields are preserved by default.
- **Fallback template:** `plugins/superpowers/.codex-plugin/plugin.template.json`
  is committed as a minimal fallback for older upstream refs that do not ship a
  Codex manifest. It carries the placeholder version
  `0.0.0+manager.template`.
- **Manager overlay:** `prepare` replaces the version with a ref-aware manager
  version, forces `skills` to `./skills/`, and enforces the manager's current
  hook-free policy: no manifest `hooks` key and no copied `hooks/` directory.
  Unknown upstream manifest fields remain preserved.
- Stable tags generate release-looking versions such as
  `6.0.3+manager.896224c`; explicit prerelease tags generate versions such as
  `6.1.0-beta.1+manager.abc1234`.
- Branch builds deliberately stay below real releases:
  `main` generates `0.0.0-main+manager.<short-sha>` and other named refs
  generate `0.0.0-ref-<sanitized-ref>+manager.<short-sha>`.
- Raw 40-character commit SHAs generate `0.0.0+manager.<short-sha>`.
- **`.superpowers-upstream.json`** records the authoritative provenance:
  `source`, `requested_ref`, `resolved_ref`, `commit`, and the upstream manifest
  version. The generated manifest version is for human readability and Codex
  package identity; the upstream `commit` is what `probe`/`update` compare
  against.

## Refresh modes

`install` and `update` accept `SUPERPOWERS_INSTALL_REFRESH_MODE`:

- `add-only` (default) — `plugin add` re-reads the local source, which refreshes
  a mutated tree. Verified sufficient for local marketplaces.
- `remove-add` — removes the manager's own plugin first, then re-adds it. Use
  only if a refresh ever fails to take:

  ```sh
  SUPERPOWERS_INSTALL_REFRESH_MODE=remove-add npx superpowers-manager update
  ```

## Tests

```sh
sh tests/run.sh                          # Layers 1-3: host-side hermetic checks while iterating
sh tests/container.sh                    # Layers 1-4: blocking Docker acceptance command
sh tests/manual/codex-behavior-probe.sh  # optional native-only compatibility residue
```

Layers 1-3 stay offline and hermetic: they use a fake local upstream repo plus
host-side fixtures, and they perform no mutation of the developer's or runner's
real Codex state.

Layer 4 is the Docker acceptance path. It is the required completion command
because the isolated-container Codex probe graduated from a temporary
nonblocking spike to a blocking acceptance gate. `sh tests/container.sh` runs
the inner `sh tests/run.sh` suite and then the real Codex offline probe inside
an isolated container home with networking disabled. That container run may
mutate the throwaway container-local Codex state, but it still performs no
mutation of the developer's or runner's real Codex state.

The manual probe is opt-in and covers native-only compatibility residue such as
path/cache behavior against an intentionally real local Codex install. It is
not part of acceptance. GitHub Actions runs the blocking container acceptance
command on pull requests and pushes to `main`.

## Repository layout

```
.agents/plugins/marketplace.json          # local marketplace definition (tracked)
config/upstream-ref                        # which upstream ref to track (tracked)
plugins/superpowers/
  .codex-plugin/plugin.template.json       # fallback manifest template (tracked)
  .codex-plugin/plugin.json                # generated manifest          (gitignored)
  skills/ assets/ LICENSE ...              # generated from upstream      (gitignored)
  .superpowers-upstream.json               # generated provenance         (gitignored)
scripts/
  adapters/codex/                          # Codex adapter entrypoint + validator helpers
  core/                                    # shared lifecycle/provenance/status modules
  prepare probe install update uninstall   # user-facing shell entrypoints
tests/                                     # hermetic suite + manual Codex probe
.cache/upstream/                           # upstream clone cache         (gitignored)
```

Everything under `plugins/superpowers/` except the fallback manifest template is
generated by `prepare` and ignored by Git; re-run `prepare` to regenerate it.
