# Behavioral Baseline Traceability

Every behavior ID in
[`behavioral-inventory.md`](behavioral-inventory.md) has exactly one row here.
`PATH::SELECTOR` names a literal runnable Node test, Python unittest method, or
committed shell `BASELINE CASE` marker. A supporting artifact is optional; it
never substitutes for the named test.

Later migration pull requests must cite the affected IDs and preserve their
selectors or intentionally update the inventory, test, and this map together.

| Behavior ID | Behavior | Exact test case | Fixture / builder |
|---|---|---|---|
| `CLI-MODE-HELP-01` | Help modes | `tests/baseline/cli-parity.test.js::CLI-MODE-HELP-01 help modes` | — |
| `CLI-MODE-VERSION-01` | Version mode | `tests/baseline/cli-parity.test.js::CLI-MODE-VERSION-01 version mode` | — |
| `CLI-MODE-DEFAULT-01` | Default update mode | `tests/baseline/cli-parity.test.js::CLI-MODE-DEFAULT-01 no arguments dispatch update` | — |
| `CLI-COMMANDS-01` | Eight subcommands and argument pass-through | `tests/baseline/cli-parity.test.js::CLI-COMMANDS-01 eight named commands dispatch` | — |
| `CLI-USAGE-01` | Usage errors and exit 2 | `tests/baseline/cli-parity.test.js::CLI-USAGE-01 invalid command and stray flag fail with exit 2` | — |
| `CLI-PREFLIGHT-01` | Command-specific preflight | `tests/baseline/cli-parity.test.js::CLI-PREFLIGHT-01 missing tools fail before dispatch` | — |
| `CLI-CHILD-STATUS-01` | Delegated status propagation | `tests/baseline/cli-parity.test.js::CLI-CHILD-STATUS-01 delegated child status is preserved` | — |
| `CLI-ENV-REF-01` | Ref override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-UPSTREAM-URL-01` | Source override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-CODEX-01` | Codex override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-CACHE-DIR-01` | Cache override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-CONFIG-DIR-01` | Config override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-PLUGIN-ROOT-01` | Plugin-root override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-MANIFEST-TEMPLATE-01` | Manifest-template override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-VALIDATOR-01` | Additional-validator override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-INSTALLED-ROOT-01` | Installed-root override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-REFRESH-MODE-01` | Install-refresh override pass-through | `tests/baseline/cli-parity.test.js::CLI-ENV-01 ten SUPERPOWERS variables pass through` | — |
| `CLI-ENV-XDG-CONFIG-01` | XDG config location | `tests/baseline/cli-parity.test.js::CLI-MODE-HELP-01 help modes` | — |
| `CLI-ENV-HOME-01` | HOME config and installed defaults | `tests/baseline/cli-parity.test.js::CLI-MODE-HELP-01 help modes` | — |
| `SEL-LOCATION-01` | Selection location chain | `tests/baseline/cli-parity.test.js::CLI-MODE-HELP-01 help modes` | — |
| `SEL-PRECEDENCE-REF-01` | Ref precedence | `tests/baseline/cli-parity.test.js::SEL-PRECEDENCE-REF-01 ref precedence and validate-first ordering` | `tests/fixtures/baseline/selection/pinned-tag.json` |
| `SEL-PRECEDENCE-SOURCE-01` | Independent source precedence | `tests/baseline/cli-parity.test.js::SEL-PRECEDENCE-SOURCE-01 source precedence is independent` | `tests/fixtures/baseline/selection/track-latest.json` |
| `SEL-PRECEDENCE-VALIDATE-01` | Validate before access | `tests/baseline/cli-parity.test.js::SEL-PRECEDENCE-REF-01 ref precedence and validate-first ordering` | `tests/fixtures/baseline/selection/wrong-schema-version.json` |
| `SEL-SCHEMA-MODES-01` | Selection modes and absent normalization | `tests/test_selection_state.py::test_read_normalizes_absent_pinned_and_track_latest` | `tests/fixtures/baseline/selection/track-latest.json` |
| `SEL-SCHEMA-KEYS-01` | Exact keys and version | `tests/test_selection_state.py::test_read_rejects_duplicate_unknown_missing_and_inconsistent_fields` | `tests/fixtures/baseline/selection/unknown-key.json` |
| `SEL-SCHEMA-REFS-01` | Tag and string refinement | `tests/test_selection_state.py::test_read_rejects_empty_multiline_and_invalid_ref_strings` | `tests/fixtures/baseline/selection/pinned-tag.json` |
| `SEL-SCHEMA-COMMIT-01` | Raw-commit cross-field equality | `tests/test_selection_state.py::test_raw_commit_requires_cross_field_equality` | `tests/fixtures/baseline/selection/pinned-commit.json` |
| `SEL-SCHEMA-SOURCE-01` | Source validation and redaction | `tests/test_selection_state.py::test_source_validation_rejects_http_userinfo_only` | — |
| `SEL-BYTES-PINNED-01` | Canonical pinned bytes | `tests/baseline/cli-parity.test.js::SEL-BYTES-PINNED-01 pin writes canonical selection bytes` | `tests/fixtures/baseline/selection/pinned-tag.json` |
| `SEL-BYTES-TRACK-01` | Canonical track-latest bytes | `tests/baseline/cli-parity.test.js::SEL-BYTES-TRACK-01 track-latest writes canonical selection bytes` | `tests/fixtures/baseline/selection/track-latest.json` |
| `REF-PINNABLE-01` | Pinnable public ref forms | `tests/baseline/cli-parity.test.js::CLI-PIN-REF-01 pin accepts exact tag or 40-hex commit only` | — |
| `REF-LATEST-STABLE-01` | Latest stable tag selection | `tests/baseline/cli-parity.test.js::SEL-BYTES-TRACK-01 track-latest writes canonical selection bytes` | `tests/builders/baseline-scenario.sh` |
| `REF-SOURCE-PROOF-01` | Exact source proof | `tests/baseline/cli-parity.test.js::SEL-BYTES-PINNED-01 pin writes canonical selection bytes` | `tests/builders/baseline-scenario.sh` |
| `REF-CLEANUP-01` | Ref and invocation cleanup | `tests/baseline/cli-parity.test.js::FS-CLEANUP-01 interrupted state cleanup is invocation-scoped` | `tests/builders/baseline-scenario.sh` |
| `PROVENANCE-BYTES-01` | Canonical provenance bytes | `tests/baseline/cli-parity.test.js::PROVENANCE-BYTES-01 prepare writes canonical provenance bytes` | `tests/fixtures/baseline/provenance/valid-tag.json` |
| `SEL-READER-DUPLICATES-01` | Selection duplicate keys | `tests/test_selection_state.py::test_read_rejects_duplicate_unknown_missing_and_inconsistent_fields` | `tests/fixtures/baseline/selection/duplicate-key.json` |
| `SEL-READER-CONSTANTS-01` | Selection constants | `tests/test_selection_state.py::test_read_rejects_non_object_constants_and_excessive_nesting` | `tests/fixtures/baseline/selection/non-standard-constant.json` |
| `SEL-READER-DEPTH-01` | Selection depth 256 | `tests/test_selection_state.py::test_read_enforces_exact_nesting_boundary` | `tests/fixtures/baseline/selection/depth-257.json` |
| `SEL-READER-BYTES-01` | Selection has no byte cap | `tests/test_selection_state.py::test_read_has_no_input_byte_limit` | `tests/fixtures/baseline/selection/track-latest.json` |
| `SEL-READER-PATHS-01` | Selection path types | `tests/test_selection_state.py::test_read_rejects_symlink_directory_and_fifo_paths` | — |
| `PROV-READER-STRICT-01` | Strict provenance profile | `tests/test_probe.sh::# BASELINE CASE: PROV-READER-STRICT-01 strict provenance reader profile` | `tests/fixtures/baseline/provenance/duplicate-key.json` |
| `PROV-READER-LENIENT-01` | Lenient provenance profile | `tests/test_probe.sh::# BASELINE CASE: PROV-READER-LENIENT-01 lenient commit reader profile` | `tests/fixtures/baseline/provenance/commit-7-hex.json` |
| `PROV-READER-CANDIDATE-01` | Candidate provenance validator profile | `tests/test_validate_generated_plugin.py::test_candidate_provenance_reader_profile` | `tests/fixtures/baseline/provenance/wrong-key-set.json` |
| `PROV-READER-CODEX-SOURCE-01` | Codex source-reader profile | `tests/test_adapter_protocol.sh::# BASELINE CASE: PROV-READER-CODEX-SOURCE-01 Codex source reader profile` | `tests/fixtures/baseline/provenance/non-standard-constant.json` |
| `PROV-READER-CODEX-COMMIT-01` | Codex commit-reader profile | `tests/test_codex_state_units.sh::# BASELINE CASE: PROV-READER-CODEX-COMMIT-01 installed metadata reader profile` | `tests/fixtures/baseline/provenance/commit-7-hex.json` |
| `MANIFEST-READER-INSTALLED-01` | Installed manifest profile | `tests/test_probe.sh::# BASELINE CASE: MANIFEST-READER-INSTALLED-01 installed generated manifest reader profile` | `tests/fixtures/baseline/manifests/installed-manager-version.json` |
| `MANIFEST-READER-UPSTREAM-01` | Upstream manifest profile | `tests/test_prepare_with_fake_upstream.sh::# BASELINE CASE: MANIFEST-READER-UPSTREAM-01 upstream manifest reader profile` | `tests/fixtures/baseline/manifests/candidate-duplicate-key.json` |
| `MANIFEST-READER-MATERIALIZE-01` | Candidate materializer profile | `tests/test_prepare_with_fake_upstream.sh::# BASELINE CASE: MANIFEST-READER-MATERIALIZE-01 hook materializer profile` | `tests/fixtures/baseline/manifests/candidate-non-standard-constant.json` |
| `MANIFEST-READER-OVERLAY-01` | Candidate overlay profile | `tests/test_prepare_with_fake_upstream.sh::# BASELINE CASE: MANIFEST-READER-OVERLAY-01 manifest overlay profile` | `tests/fixtures/baseline/manifests/candidate-unknown-field.json` |
| `MANIFEST-READER-VALIDATOR-01` | Candidate validator profile | `tests/test_validate_generated_plugin.py::test_candidate_manifest_reader_profile` | `tests/fixtures/baseline/manifests/candidate-duplicate-key.json` |
| `CODEX-JSON-ARRAY-01` | Codex membership parser | `tests/test_codex_state_units.sh::# BASELINE CASE: CODEX-JSON-ARRAY-01 installed/listing parser profile` | — |
| `CODEX-JSON-MARKETPLACE-01` | Codex marketplace parser | `tests/test_marketplace_reconcile.sh::# BASELINE CASE: CODEX-JSON-MARKETPLACE-01 marketplace-root parser profile` | — |
| `CODEX-JSON-VERSION-01` | Codex active-version parser | `tests/test_marketplace_reconcile.sh::# BASELINE CASE: CODEX-JSON-VERSION-01 active-version parser profile` | — |
| `ADAPTER-PROTOCOL-01` | Protocol v1 operation results | `tests/test_adapter_protocol.py::test_build_and_uninstall_accept_exact_empty_results` | `tests/fixtures/baseline/adapter-responses/valid-build.json` |
| `ADAPTER-ENVELOPE-01` | Exact envelope and shapes | `tests/test_adapter_protocol.py::test_rejects_empty_malformed_non_object_and_extra_fields` | — |
| `ADAPTER-FINGERPRINT-01` | Fingerprint result | `tests/test_adapter_protocol.py::test_inspect_fingerprint_accepts_full_sha_short_sha_and_null` | `tests/fixtures/baseline/adapter-responses/valid-inspect-fingerprint.json` |
| `ADAPTER-UPDATE-CONTROL-01` | Update-control result | `tests/test_adapter_protocol.py::test_inspect_update_control_accepts_only_exact_allowed_values` | `tests/fixtures/baseline/adapter-responses/valid-inspect-update-control.json` |
| `ADAPTER-OWNERSHIP-01` | Ownership result | `tests/test_adapter_protocol.py::test_inspect_ownership_accepts_all_consistent_identity_states` | `tests/fixtures/baseline/adapter-responses/valid-inspect-ownership.json` |
| `ADAPTER-INSTALL-RESULT-01` | Install verification hints | `tests/test_adapter_protocol.py::test_install_accepts_empty_one_and_both_verification_hints` | `tests/fixtures/baseline/adapter-responses/valid-install.json` |
| `ADAPTER-STATUS-01` | Exit and envelope cross-rules | `tests/test_adapter_protocol.py::test_rejects_exit_envelope_mismatches_and_null_cross_rules` | — |
| `ADAPTER-REPLAY-01` | Ordered channel replay | `tests/test_adapter_protocol.py::test_messages_replay_by_channel_in_order` | — |
| `ADAPTER-CONTROLLED-FAILURE-01` | Controlled failure replay | `tests/test_adapter_protocol.py::test_controlled_failure_replays_messages_error_and_hints` | `tests/fixtures/baseline/adapter-responses/controlled-failure.json` |
| `ADAPTER-TERMINAL-01` | Terminal control rejection | `tests/test_adapter_protocol.py::test_rejects_terminal_controls_in_terminal_facing_protocol_strings` | — |
| `ADAPTER-SURROGATE-01` | Surrogate rejection | `tests/test_adapter_protocol.py::test_rejects_surrogate_escapes_in_terminal_facing_protocol_strings` | — |
| `ADAPTER-READER-BYTES-01` | Inclusive 1 MiB boundary | `tests/test_adapter_protocol.py::test_enforces_inclusive_response_size_boundary_before_replay` | `tests/fixtures/baseline/adapter-responses/size-1048576.json` |
| `ADAPTER-READER-UTF8-01` | UTF-8 byte counting | `tests/test_adapter_protocol.py::test_response_size_limit_counts_utf8_bytes_before_replay` | — |
| `ADAPTER-READER-CONSTANTS-01` | Adapter constants | `tests/test_adapter_protocol.py::test_rejects_non_standard_json_constants_without_replay` | `tests/fixtures/baseline/adapter-responses/non-standard-constant.json` |
| `ADAPTER-READER-DEPTH-01` | Adapter depth 64 | `tests/test_adapter_protocol.py::test_enforces_exact_json_nesting_boundary` | `tests/fixtures/baseline/adapter-responses/depth-64.json` |
| `ADAPTER-READER-DUPLICATES-01` | Adapter duplicate keys | `tests/test_adapter_protocol.py::test_rejects_duplicate_object_keys_recursively_without_replay` | `tests/fixtures/baseline/adapter-responses/duplicate-key.json` |
| `GENERATED-LAYOUT-01` | Canonical generated layout | `tests/baseline/cli-parity.test.js::PREPARE-TREE-01 prepare creates the canonical generated tree` | `tests/fixtures/baseline/generated-tree/no-hooks.txt` |
| `GENERATED-UNKNOWN-FIELDS-01` | Preserve unknown manifest fields | `tests/baseline/cli-parity.test.js::PREPARE-TREE-01 prepare creates the canonical generated tree` | `tests/fixtures/baseline/manifests/candidate-unknown-field.json` |
| `GENERATED-HOOKS-FORBID-01` | Hook-free policies | `tests/test_validate_generated_plugin.py::test_hook_policy_is_source_sensitive_and_fail_closed` | `tests/fixtures/baseline/generated-tree/no-hooks.txt` |
| `GENERATED-HOOKS-DEFAULT-01` | Default hook discovery | `tests/test_validate_generated_plugin.py::test_default_discovery_requires_hooks_json` | `tests/fixtures/baseline/generated-tree/default-hooks.txt` |
| `GENERATED-HOOKS-DECLARED-01` | Active declared hooks | `tests/test_validate_generated_plugin.py::test_upstream_hook_shapes_are_accepted` | `tests/fixtures/baseline/generated-tree/declared-hooks.txt` |
| `FS-ATOMIC-01` | Atomic prepare activation | `tests/baseline/cli-parity.test.js::FS-ATOMIC-01 failed prepare preserves the previous generated tree` | `tests/builders/baseline-scenario.sh` |
| `FS-CLEANUP-01` | Invocation-scoped cleanup | `tests/baseline/cli-parity.test.js::FS-CLEANUP-01 interrupted state cleanup is invocation-scoped` | `tests/builders/baseline-scenario.sh` |
| `FS-SYMLINK-01` | Hook containment and symlinks | `tests/baseline/cli-parity.test.js::FS-SYMLINK-01 escaping and broken symlinks fail closed` | `tests/builders/baseline-scenario.sh` |
| `FS-SELECTION-ATOMIC-01` | Atomic selection writer | `tests/test_selection_state.py::test_atomic_writer_preserves_valid_state_on_failure` | `tests/fixtures/baseline/selection/pinned-tag.json` |
| `FS-SELECTION-TYPES-01` | Selection writer path types | `tests/test_selection_state.py::test_writer_rejects_unexpected_state_and_parent_path_types` | — |
| `PREPARE-VALIDATE-01` | Validate before activation | `tests/baseline/cli-parity.test.js::PREPARE-VALIDATE-01 validation completes before activation` | `tests/builders/baseline-scenario.sh` |
| `PREPARE-DETERMINISTIC-01` | Deterministic prepare output | `tests/baseline/cli-parity.test.js::PREPARE-TREE-01 prepare creates the canonical generated tree` | `tests/fixtures/baseline/generated-tree/no-hooks.txt` |
| `PROBE-READONLY-01` | Read-only probe | `tests/baseline/cli-parity.test.js::PROBE-READONLY-01 probe is read-only` | `tests/builders/baseline-scenario.sh` |
| `PROBE-FAIL-CLOSED-01` | Probe fails closed | `tests/baseline/cli-parity.test.js::SEL-INVALID-01 malformed saved state fails before Git or adapter access` | `tests/fixtures/baseline/selection/wrong-schema-version.json` |
| `INSTALL-ORDER-01` | Install ordering | `tests/baseline/cli-parity.test.js::INSTALL-ORDER-01 install prepares and validates before adapter mutation` | `tests/builders/baseline-scenario.sh` |
| `INSTALL-VERIFY-01` | Installed fingerprint verification | `tests/baseline/cli-parity.test.js::LIFECYCLE-VERIFY-01 install and uninstall verify resulting state` | `tests/fixtures/baseline/bin/stateful-adapter` |
| `UPDATE-CONTROL-01` | Managed update control | `tests/baseline/cli-parity.test.js::UPDATE-CONTROL-01 update requires current managed control evidence` | `tests/fixtures/baseline/bin/stateful-adapter` |
| `UNINSTALL-OWNERSHIP-01` | Manager-only uninstall | `tests/baseline/cli-parity.test.js::UNINSTALL-OWNERSHIP-01 uninstall removes only manager-owned resources` | `tests/fixtures/baseline/bin/stateful-adapter` |
| `UNINSTALL-VERIFY-01` | Uninstall verification | `tests/baseline/cli-parity.test.js::LIFECYCLE-VERIFY-01 install and uninstall verify resulting state` | `tests/fixtures/baseline/bin/stateful-adapter` |
| `DIAG-INTENTIONAL-01` | Frozen actionable diagnostics | `tests/baseline/cli-parity.test.js::CLI-USAGE-01 invalid command and stray flag fail with exit 2` | — |
| `DIAG-INCIDENTAL-01` | Incidental operational wording | `tests/baseline/cli-parity.test.js::PREPARE-VALIDATE-01 validation completes before activation` | — |
| `PACKAGE-REPO-01` | Repo/copy entrypoint | `tests/baseline/cli-parity.test.js::CLI-MODE-HELP-01 help modes` | — |
| `PACKAGE-TARBALL-01` | Offline installed tarball entrypoint | `tests/baseline/packaged-cli.test.js::PACKAGE-CLI-01 offline installed tarball exposes help and version` | — |
