# Behavioral Migration Baseline

This inventory freezes the observable behavior that later migration pull
requests must preserve or explicitly amend. It records the repository at the
Phase 0 baseline; it does not make generated content under
`plugins/superpowers/` maintained source.

Every normative behavior has a stable ID. The executable mapping is in
[`traceability.md`](traceability.md). Reader differences are deliberate
compatibility facts, not a recommendation to make every parser identical.

## Public CLI

| Behavior ID | Contract |
|---|---|
| `CLI-MODE-HELP-01` | `--help` and `-h` are standalone help modes. They write the complete usage text to stdout, write nothing to stderr, perform no preflight or dispatch, and exit 0. |
| `CLI-MODE-VERSION-01` | `--version` is a standalone version mode. It reads the current package version, writes that value plus one newline to stdout, writes nothing to stderr, performs no dispatch, and exits 0. |
| `CLI-MODE-DEFAULT-01` | No arguments is the third distinct mode and is exactly equivalent to dispatching `update` with no arguments. |
| `CLI-COMMANDS-01` | The eight named subcommands are `pin`, `track-latest`, `unpin`, `prepare`, `probe`, `install`, `update`, and `uninstall`. Except for CLI-owned arity and pin-ref checks, remaining arguments pass through unchanged to the selected script. |
| `CLI-USAGE-01` | Unknown commands, stray top-level flags, invalid `pin` arity/ref syntax, and extra arguments to `track-latest` or `unpin` are usage errors. They do not dispatch, print `error: ...` followed by usage, and exit 2. |
| `CLI-PREFLIGHT-01` | Preflight is command-specific and completes before dispatch: `pin` needs Git and Python; `track-latest` needs Python; `unpin` has no extra tool; `prepare` needs Git and Python; `probe`, `install`, and `update` need Git, Python, and Codex; `uninstall` needs Python and Codex. Every command also needs a POSIX shell. Missing requirements exit 1 without dispatch. |
| `CLI-CHILD-STATUS-01` | After successful preflight, the delegated script inherits stdio and environment; its numeric exit status is the CLI exit status. Spawn failure or a signal-only result is normalized to exit 1. |

## Environment and location

The ten `SUPERPOWERS_*` variables below are the complete public override set.
The CLI inherits the environment wholesale. “Unset” means the consumer uses
the source-derived default shown here.

| Behavior ID | Variable | Current default | Production consumer and effect |
|---|---|---|---|
| `CLI-ENV-REF-01` | `SUPERPOWERS_REF` | Saved pinned/track-latest intent, then `config/upstream-ref` (`latest-release`) | Selection/ref computation; when non-empty it independently overrides the effective ref. `unpin` also reports that the active override remains effective. |
| `CLI-ENV-UPSTREAM-URL-01` | `SUPERPOWERS_UPSTREAM_URL` | `https://github.com/obra/superpowers` unless saved selection supplies a source | Selection/source computation plus `pin` and `track-latest`; when non-empty it independently overrides the effective source. |
| `CLI-ENV-CODEX-01` | `SUPERPOWERS_CODEX` | `codex` | CLI Codex preflight and every Codex adapter listing or mutation. A path override is accepted. |
| `CLI-ENV-CACHE-DIR-01` | `SUPERPOWERS_CACHE_DIR` | Package-root `.cache/upstream` | `prepare`; relative values are resolved from the invocation directory and the upstream repository is beneath `superpowers/`. |
| `CLI-ENV-CONFIG-DIR-01` | `SUPERPOWERS_CONFIG_DIR` | Location chain below | Selection-state readers and writers. An explicitly set value, including empty, must be absolute. |
| `CLI-ENV-PLUGIN-ROOT-01` | `SUPERPOWERS_PLUGIN_ROOT` | Package-root `plugins/superpowers` | `prepare`; relative values are resolved from the invocation directory and become the generated live tree. |
| `CLI-ENV-MANIFEST-TEMPLATE-01` | `SUPERPOWERS_MANIFEST_TEMPLATE` | Package-root `plugins/superpowers/.codex-plugin/plugin.template.json` | `prepare` and adapter build fallback; the path must name a file before build. |
| `CLI-ENV-VALIDATOR-01` | `SUPERPOWERS_VALIDATOR` | Empty, meaning no additional validator | `prepare`; a non-empty path runs after built-in validation and before activation. |
| `CLI-ENV-INSTALLED-ROOT-01` | `SUPERPOWERS_INSTALLED_SEARCH_ROOT` | `$HOME/.codex` | Codex fingerprint inspection; the active version selects the exact plugin cache path below this root. |
| `CLI-ENV-REFRESH-MODE-01` | `SUPERPOWERS_INSTALL_REFRESH_MODE` | `add-only` | Codex adapter install; allowed values are `add-only` and `remove-add`. |
| `CLI-ENV-XDG-CONFIG-01` | `XDG_CONFIG_HOME` | Unset | Second selection-location candidate. A non-empty value must be absolute and gains `/superpowers-manager`. |
| `CLI-ENV-HOME-01` | `HOME` | Process environment; no manager fallback | Final selection-location base and installed-search default. It must be present and absolute when used for selection location. |

| Behavior ID | Contract |
|---|---|
| `SEL-LOCATION-01` | Selection state is exactly `SUPERPOWERS_CONFIG_DIR/selection.json` when that variable is set; otherwise `$XDG_CONFIG_HOME/superpowers-manager/selection.json` when XDG is non-empty; otherwise `$HOME/.config/superpowers-manager/selection.json`. Relative or unavailable required bases fail closed. |
| `SEL-PRECEDENCE-REF-01` | Ref precedence is independent: non-empty `SUPERPOWERS_REF` > saved pinned ref or saved track-latest intent > packaged `config/upstream-ref`. |
| `SEL-PRECEDENCE-SOURCE-01` | Source precedence is independent: non-empty `SUPERPOWERS_UPSTREAM_URL` > source saved with either selection mode > `https://github.com/obra/superpowers`. A ref and source may therefore have different origins. |
| `SEL-PRECEDENCE-VALIDATE-01` | Saved selection and the resulting source are validated before Git, adapter, generated-tree, or Codex access. Invalid saved state cannot be bypassed by environment ref/source overrides. |

## Selection schema, refs, and canonical bytes

| Behavior ID | Contract |
|---|---|
| `SEL-SCHEMA-MODES-01` | Absent state normalizes to mode `none` and empty saved fields. Present state is an object with integer `schema_version: 1` and mode exactly `pinned` or `track-latest`. Boolean `true` is not integer 1. |
| `SEL-SCHEMA-KEYS-01` | `track-latest` has exactly `schema_version`, `mode`, and `source`. `pinned` additionally has exactly `requested_ref`, `resolved_ref`, and `commit`. Missing, unknown, or duplicate keys fail. |
| `SEL-SCHEMA-REFS-01` | A pinned tag is a v-prefixed SemVer 2.0.0 core with optional prerelease and no build metadata; `resolved_ref` must equal the requested tag. All ref/source strings are non-empty single-line strings without NUL. |
| `SEL-SCHEMA-COMMIT-01` | A saved raw commit is lowercase 40-hex and `requested_ref`, `resolved_ref`, and `commit` must be identical. Writers accept uppercase commit input only by normalizing all three fields to lowercase. |
| `SEL-SCHEMA-SOURCE-01` | Source may be HTTP(S), SSH, scp-like, absolute local, or other Git-compatible text. HTTP(S) userinfo is rejected and redacted from diagnostics. |
| `SEL-BYTES-PINNED-01` | `pin` atomically writes the canonical two-space-indented pinned record below with a final newline and file mode 0600. A newly created state directory is mode 0700. |
| `SEL-BYTES-TRACK-01` | `track-latest` atomically writes the canonical two-space-indented track-latest record below with a final newline and file mode 0600. It saves intent only. |

Pinned tag bytes:

```json
{
  "schema_version": 1,
  "mode": "pinned",
  "source": "https://github.com/obra/superpowers",
  "requested_ref": "v6.1.1",
  "resolved_ref": "v6.1.1",
  "commit": "0123456789abcdef0123456789abcdef01234567"
}
```

Pinned commit bytes:

```json
{
  "schema_version": 1,
  "mode": "pinned",
  "source": "https://github.com/obra/superpowers",
  "requested_ref": "0123456789abcdef0123456789abcdef01234567",
  "resolved_ref": "0123456789abcdef0123456789abcdef01234567",
  "commit": "0123456789abcdef0123456789abcdef01234567"
}
```

Track-latest bytes:

```json
{
  "schema_version": 1,
  "mode": "track-latest",
  "source": "https://github.com/obra/superpowers"
}
```

| Behavior ID | Contract |
|---|---|
| `REF-PINNABLE-01` | Public `pin` accepts only an exact v-prefixed SemVer tag or full 40-hex commit. Tag build metadata, short commits, branches, and symbolic refs are rejected as usage errors. |
| `REF-LATEST-STABLE-01` | `latest-release` queries v-prefixed tags, ignores prereleases and non-three-component tags, peels annotated tags, and selects the greatest numeric stable major/minor/patch. |
| `REF-SOURCE-PROOF-01` | Exact tags are resolved from the selected source. Raw commits are lowercased, fetched without tags into a private proof repository, and accepted only when the selected source supplies a commit object. Saved intent records the proven commit. |
| `REF-CLEANUP-01` | Verification, exact-fetch, and prepare workspaces are invocation-specific and trap-cleaned on normal, failed, or interrupted exits; a cleanup never removes a sibling or earlier invocation’s workspace. |

## Canonical generated provenance

| Behavior ID | Contract |
|---|---|
| `PROVENANCE-BYTES-01` | `prepare` manager-authors `.superpowers-upstream.json` with exactly `source`, `requested_ref`, `resolved_ref`, `commit`, and `upstream_manifest_version` in that order, two-space indentation, JSON escaping, and one final newline. |

Tag/latest provenance bytes:

```json
{
  "source": "https://example.invalid/superpowers.git",
  "requested_ref": "latest-release",
  "resolved_ref": "v6.1.1",
  "commit": "d884ae04edebef577e82ff7c4e143debd0bbec99",
  "upstream_manifest_version": "6.1.1"
}
```

Raw-commit provenance bytes:

```json
{
  "source": "https://example.invalid/superpowers.git",
  "requested_ref": "d884ae04edebef577e82ff7c4e143debd0bbec99",
  "resolved_ref": "d884ae04edebef577e82ff7c4e143debd0bbec99",
  "commit": "d884ae04edebef577e82ff7c4e143debd0bbec99",
  "upstream_manifest_version": "6.1.1"
}
```

## Reader and trust-boundary matrix

“No byte cap” means the reader has no manager-authored input-size check. “No
explicit depth cap” means decoder recursion failure is handled, but there is no
promised numeric nesting boundary.

| Profile | Constants | Nesting | Bytes | Duplicate keys | Schema refinement and fail-closed behavior |
|---|---|---|---|---|---|
| Selection state | Reject | Maximum 256 containers; 257 rejects | No byte cap | Reject recursively | Exact selection keys/types/cross-field rules; absent is normalized, malformed/path-type input exits nonzero with no normalized output or traceback. |
| Provenance strict field reader | Reject | Maximum 256 containers | No byte cap | Last key wins | Requires a top-level object, then extracts one dotted field; malformed input is an operational error. |
| Provenance lenient generated-commit reader | Reject to empty | No explicit depth cap; recursion failure becomes empty | No byte cap | Last key wins | Returns only a 40-hex commit. Missing, malformed, short, or wrong-type input yields empty success so status remains conservative. |
| Provenance candidate validator | Reject | Maximum 256 containers | No byte cap | Last key wins | Exact five-key manager contract, expected-value equality, and lowercase 40-hex commit; validation exits 1 without traceback. |
| Provenance Codex build source reader | Accept | No explicit depth cap; recursion failure rejects | No byte cap | Last key wins | Requires only a top-level object with non-empty string `source`; failure becomes controlled `invalid-provenance`, then candidate validation applies the full contract. |
| Provenance Codex installed-commit reader | Reject | Maximum 256 containers | No byte cap | Last key wins | Top-level object and string commit of 7 or 40 hex; unreadable or invalid input returns nonzero and cannot prove a fingerprint. |
| Installed generated-manifest reader | Reject | Maximum 256 containers | No byte cap | Last key wins | Top-level object and string `version`; returns only a terminal `+manager.` 7-hex suffix. Failure cannot prove the installed fingerprint. |
| Upstream manifest pipeline | Reject | Maximum 256 containers | No byte cap | Last key wins | Requires an object; materialization, overlay, and built-in validation refine hooks and manager fields. Any failure prevents activation. |
| Candidate hook materializer | Reject | Maximum 256 containers | No byte cap | Last key wins | Object plus source-sensitive hook declaration and contained regular-file/subtree rules; failure aborts adapter build. |
| Candidate manifest overlay | Reject | Maximum 256 containers | No byte cap | Last key wins | Object; preserves unknown fields and winning upstream values except manager-owned `version` and `skills`; write/read failure aborts build. |
| Candidate generated-plugin validator | Reject | Maximum 256 containers | No byte cap | Last key wins | Exact manager provenance, required manifest fields and paths, source-sensitive hooks, required tree, and skill frontmatter; accumulated errors exit 1 without traceback. |
| Codex installed/listing membership parser | Accept | No explicit depth cap; recursion failure exits 2 | No byte cap | Last key wins | Named top-level array; every item must be an object with a non-empty string target field. Emits only `present`/`absent`; invalid input exits 2 with no result. |
| Codex marketplace-root parser | Accept | No explicit depth cap; recursion failure exits 2 | No byte cap | Last key wins | Every item needs a non-empty string name; only the matching item needs a non-empty string root. Invalid input exits 2 with no result. |
| Codex active-version parser | Reject | No explicit depth cap; recursion failure exits 2 | No byte cap | Last key wins | At most one matching plugin; version is a safe non-empty cache-path component without terminal controls. Invalid input exits 2; verified absence is empty exit 0. |
| Adapter-response reader | Reject | Maximum 64 containers; 65 rejects | 1,048,576 bytes inclusive | Reject recursively | Exact protocol-v1 envelope and per-operation schema. Malformed input exits validator 2, writes no result, and replays nothing; the public adapter boundary normalizes nonzero to operational failure. |

The reader behaviors above are assigned as follows.

| Behavior ID | Contract |
|---|---|
| `SEL-READER-DUPLICATES-01` | Selection JSON rejects duplicate object keys recursively. |
| `SEL-READER-CONSTANTS-01` | Selection JSON rejects `NaN`, `Infinity`, and `-Infinity`. |
| `SEL-READER-DEPTH-01` | Selection JSON accepts parsing through 256 nested arrays/objects and rejects 257 before schema use. |
| `SEL-READER-BYTES-01` | Selection JSON has no input byte cap; valid state padded beyond 1 MiB remains valid. |
| `SEL-READER-PATHS-01` | Selection state and its immediate directory are inspected without following a state symlink; symlink, directory, FIFO, and symlinked-parent cases fail closed. |
| `PROV-READER-STRICT-01` | The strict provenance field-reader profile is frozen exactly as the matrix states. |
| `PROV-READER-LENIENT-01` | The lenient generated-commit profile is frozen exactly as the matrix states. |
| `PROV-READER-CANDIDATE-01` | The generated-candidate provenance validator profile is frozen exactly as the matrix states. |
| `PROV-READER-CODEX-SOURCE-01` | The Codex build source-reader profile is frozen exactly as the matrix states. |
| `PROV-READER-CODEX-COMMIT-01` | The Codex installed-metadata commit-reader profile is frozen exactly as the matrix states. |
| `MANIFEST-READER-INSTALLED-01` | The installed generated-manifest fingerprint profile is frozen exactly as the matrix states. |
| `MANIFEST-READER-UPSTREAM-01` | The upstream manifest pipeline profile is frozen exactly as the matrix states. |
| `MANIFEST-READER-MATERIALIZE-01` | The candidate hook-materializer profile is frozen exactly as the matrix states. |
| `MANIFEST-READER-OVERLAY-01` | The candidate manifest-overlay profile is frozen exactly as the matrix states. |
| `MANIFEST-READER-VALIDATOR-01` | The candidate generated-plugin validator profile is frozen exactly as the matrix states. |
| `CODEX-JSON-ARRAY-01` | The Codex installed/listing membership profile is frozen exactly as the matrix states. |
| `CODEX-JSON-MARKETPLACE-01` | The Codex marketplace-root profile is frozen exactly as the matrix states. |
| `CODEX-JSON-VERSION-01` | The Codex active-version profile is frozen exactly as the matrix states. |

## Adapter protocol

[`docs/adapter-protocol.md`](../adapter-protocol.md) is the normative internal
protocol-v1 envelope and operation-schema definition. This inventory links to
that contract rather than restating or redefining its six-key envelope.

| Behavior ID | Contract |
|---|---|
| `ADAPTER-PROTOCOL-01` | Adapters emit one protocol-1 JSON response on stdout for `build`, `inspect`, `install`, or `uninstall`; result acceptance is operation/view-specific as defined by the normative protocol. |
| `ADAPTER-ENVELOPE-01` | Envelope and nested object key sets are exact; empty, malformed, non-object, missing, extra, wrong-type, and operation/view-mismatched input is rejected before replay. |
| `ADAPTER-FINGERPRINT-01` | Fingerprint inspection accepts only null or a 7- or 40-hex fingerprint in its exact result shape. |
| `ADAPTER-UPDATE-CONTROL-01` | Update-control inspection accepts only `managed` or `unsupported` in its exact result shape. |
| `ADAPTER-OWNERSHIP-01` | Ownership inspection accepts only internally consistent manager/legacy resource Booleans and derived identity state. |
| `ADAPTER-INSTALL-RESULT-01` | Install success has exact `verification_hints`, containing only optional `mismatch` and `missing` terminal-facing strings. |
| `ADAPTER-STATUS-01` | `ok`, adapter exit status, `result`, and `error` obey the success/failure cross-rules. |
| `ADAPTER-REPLAY-01` | Only a completely validated response replays messages, in array order and to each declared stream. |
| `ADAPTER-CONTROLLED-FAILURE-01` | A valid controlled failure replays validated messages, error, and hints, yields no result, and returns validator status 1. |
| `ADAPTER-TERMINAL-01` | Terminal-facing protocol strings reject C0, DEL, and C1 controls and must be non-empty single-line strings. |
| `ADAPTER-SURROGATE-01` | Terminal-facing protocol strings reject surrogate code points without leaking a traceback. |
| `ADAPTER-READER-BYTES-01` | The response file limit is inclusive at exactly 1,048,576 bytes and rejects the next byte before replay. |
| `ADAPTER-READER-UTF8-01` | Adapter response size is counted in UTF-8 bytes, not Unicode code points. |
| `ADAPTER-READER-CONSTANTS-01` | Adapter response JSON rejects all non-standard numeric constants before replay. |
| `ADAPTER-READER-DEPTH-01` | Adapter response JSON accepts exactly 64 nested containers and rejects 65 before replay. |
| `ADAPTER-READER-DUPLICATES-01` | Adapter response JSON rejects duplicate keys recursively before replay. |

## Generated tree and hook forms

| Behavior ID | Contract |
|---|---|
| `GENERATED-LAYOUT-01` | Every generated tree contains `.codex-plugin/plugin.json`, `.codex-plugin/plugin.template.json`, `.superpowers-upstream.json`, `CODE_OF_CONDUCT.md`, `LICENSE`, `README.md`, and a non-empty `skills/`; optional upstream `assets/` is copied. |
| `GENERATED-UNKNOWN-FIELDS-01` | When upstream provides `.codex-plugin/plugin.json`, unknown upstream fields are preserved. The manager requires name `superpowers`, overwrites a ref-aware manager version and `skills: ./skills/`, and rejects rather than repairs a wrong name; fallback is used only when upstream has no manifest. |
| `GENERATED-HOOKS-FORBID-01` | Upstream exact `hooks: {}` forbids generated `hooks/`. Manifest-less fallback also has no hook declaration and forbids generated `hooks/`. |
| `GENERATED-HOOKS-DEFAULT-01` | Upstream absent `hooks` or empty array uses default discovery: copy `hooks/` only when upstream has regular `hooks/hooks.json`; generated default-discovered hooks must contain that file. |
| `GENERATED-HOOKS-DECLARED-01` | Active upstream string/path-list declarations materialize the declared contained files and any valid hook subtree; active object/object-list declarations copy a present valid hook subtree. Unsupported, mixed, escaping, broken, absolute-symlink, or wrong-type inputs fail closed. |

Canonical no-hooks form:

```text
.codex-plugin/
.codex-plugin/plugin.json
.codex-plugin/plugin.template.json
.superpowers-upstream.json
CODE_OF_CONDUCT.md
LICENSE
README.md
assets/
assets/superpowers-small.svg
skills/
skills/brainstorming/
skills/brainstorming/SKILL.md
```

Canonical default-hooks form adds:

```text
hooks/
hooks/hooks-codex.json
hooks/hooks.json
hooks/session-start-codex
hooks/support/
hooks/support/helper.txt
```

Canonical declared-hooks form adds:

```text
alternate/
alternate/hooks-second.json
config/
config/hooks-first.json
hooks/
hooks/hooks-codex.json
hooks/session-start-codex
hooks/support/
hooks/support/helper.txt
```

## Filesystem, lifecycle, and observability

| Behavior ID | Contract |
|---|---|
| `FS-ATOMIC-01` | `prepare` builds and validates in a same-parent invocation workspace, then replaces the live tree by rename with restoration of the prior tree on swap failure. Any pre-activation failure preserves the previous generated tree. |
| `FS-CLEANUP-01` | Normal, failed, and trapped exits clean only the current invocation’s prepare/proof/install/probe/uninstall workspace; sibling and interrupted historical workspaces are preserved. |
| `FS-SYMLINK-01` | Required inputs, hook declarations, copied hook trees, and generated hook trees enforce containment and regular-file/directory types. Escaping, broken, or absolute symlinks fail before activation or Codex mutation. |
| `FS-SELECTION-ATOMIC-01` | Selection writers use exclusive mode-0600 temporary files and atomic replace; write/replace failure preserves the prior valid record and removes only the writer’s own temporary file. |
| `FS-SELECTION-TYPES-01` | Selection read/write/unpin reject unexpected symlink, directory, FIFO, and unsafe parent types rather than following or removing them. |
| `PREPARE-VALIDATE-01` | `prepare` resolves/fetches, builds via the adapter, completes built-in validation, then any configured additional validator, and only then activates. |
| `PREPARE-DETERMINISTIC-01` | Given the same selected source/ref and inputs, `prepare` emits the canonical generated layout, manager overlay, provenance bytes, and ref-aware version deterministically. |
| `PROBE-READONLY-01` | `probe` computes desired/generated/installed state and reports human or porcelain fields without changing selection, generated, cache, adapter, or Codex state; its own temporary workspace is removed. |
| `PROBE-FAIL-CLOSED-01` | Invalid selection/source, malformed adapter response, unprovable Codex listing, or unreadable installed state is an operational failure, never reported as current or absent. |
| `INSTALL-ORDER-01` | `install` probes, rejects legacy state, prepares and validates when needed, then re-inspects ownership/update control, mutates manager state, and finally inspects the installed fingerprint. No adapter mutation precedes successful preparation/validation. |
| `INSTALL-VERIFY-01` | Install succeeds only when the final 7- or 40-hex installed fingerprint matches the prepared 40-hex commit; missing or mismatched proof fails with the validated adapter hint when available. |
| `UPDATE-CONTROL-01` | `update` requires fresh validated `managed` update-control evidence before treating current state as success or allowing installation/refresh mutation. Unsupported, unknown, or malformed evidence fails without mutation. |
| `UNINSTALL-OWNERSHIP-01` | `uninstall` inspects then removes only `superpowers@superpowers-manager` and marketplace `superpowers-manager`; legacy and other-provider resources are reported but never removed automatically. Generated/cache artifacts are left in place. |
| `UNINSTALL-VERIFY-01` | After adapter uninstall, ownership is re-inspected and success requires both manager plugin and marketplace to be absent; otherwise uninstall fails. |

Observable filesystem and external-state effects:

| Operation | Success effect | Failure or no-op boundary |
|---|---|---|
| `pin` / `track-latest` | Create/update only selection state and its private temporary file lifecycle. | Prior valid state survives failed proof/write; no generated or Codex mutation. |
| `unpin` | Remove only a regular saved `selection.json`. | Invalid path types remain and fail; generated/cache/Codex state is untouched. |
| `prepare` | Update the upstream cache and atomically replace only the selected generated plugin root. | Prior live tree survives validation/build/swap failure; current invocation scratch is removed. |
| `probe` | No durable write. | Unprovable state is failure, not absence/current. |
| `install` / `update` | May register/reconcile the manager marketplace and add/refresh only the manager plugin after validation. | Preflight, prepare, ownership, update-control, and protocol failures prevent later mutations. |
| `uninstall` | May remove only the manager plugin and manager marketplace. | Generated plugin and cache remain; legacy and foreign providers remain. |

## Diagnostics and package entrypoints

| Behavior ID | Contract |
|---|---|
| `DIAG-INTENTIONAL-01` | Exact public usage/help text, usage-error classification and exit 2, missing-tool preflight messages, canonical selection success text, porcelain field names/status values, and adapter replay ordering are actionable/frozen where tests compare exact bytes. |
| `DIAG-INCIDENTAL-01` | Absolute temporary paths, Git/Codex/library wording, and the unasserted remainder of operational diagnostics are incidental. Where tests match a fragment, the error category, safety meaning, exit behavior, and absence of traceback are intentional but surrounding prose is not frozen. |
| `PACKAGE-REPO-01` | The public bin resolves package root from the physical bin location and runs from a repository/copy checkout without relying on the caller’s current directory. |
| `PACKAGE-TARBALL-01` | The same declared `superpowers-manager` bin works from an offline installed npm tarball and exposes package-local help/version without reaching the repository checkout or network. |
