from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from pathlib import Path


MAX_JSON_NESTING = 256
MISSING = object()


def reject_constant(constant: str) -> None:
    raise ValueError(f"non-standard numeric constant: {constant}")


def nesting_exceeds_limit(value: object) -> bool:
    stack = [(value, 0)]
    while stack:
        current, depth = stack.pop()
        if isinstance(current, dict):
            next_depth = depth + 1
            if next_depth > MAX_JSON_NESTING:
                return True
            stack.extend((child, next_depth) for child in current.values())
        elif isinstance(current, list):
            next_depth = depth + 1
            if next_depth > MAX_JSON_NESTING:
                return True
            stack.extend((child, next_depth) for child in current)
    return False


def load_manifest(path: Path) -> dict[str, object]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle, parse_constant=reject_constant)
    except RecursionError as exc:
        raise ValueError(f"JSON nesting exceeds limit in {path}") from exc
    except json.JSONDecodeError as exc:
        raise ValueError(
            f"invalid manifest JSON in {path}: "
            f"line {exc.lineno} column {exc.colno}: {exc.msg}"
        ) from exc
    except (OSError, UnicodeError) as exc:
        raise ValueError(f"cannot read manifest JSON in {path}: {exc}") from exc
    except ValueError as exc:
        raise ValueError(f"invalid manifest JSON in {path}: {exc}") from exc

    if nesting_exceeds_limit(data):
        raise ValueError(f"JSON nesting exceeds limit in {path}")
    if not isinstance(data, dict):
        raise ValueError(f"manifest must be a JSON object: {path}")
    return data


def resolve_contained(
    root: Path, path: Path, label: str, *, strict: bool
) -> Path:
    try:
        resolved_root = root.resolve(strict=True)
        resolved = path.resolve(strict=strict)
        resolved.relative_to(resolved_root)
    except (OSError, RuntimeError, ValueError) as exc:
        raise ValueError(f"{label} escapes or could not be resolved: {path}") from exc
    return resolved


def checked_file(root: Path, relative: Path) -> Path:
    source = root / relative
    resolved = resolve_contained(root, source, "declared hook source", strict=True)
    if not resolved.is_file():
        raise ValueError(f"declared hook source is not a regular file: {source}")
    return source


def checked_destination(root: Path, relative: Path) -> Path:
    destination = root / relative
    resolve_contained(
        root, destination.parent, "declared hook destination parent", strict=False
    )
    if os.path.lexists(destination):
        if destination.is_symlink():
            raise ValueError(
                f"declared hook destination must not be a symlink: {destination}"
            )
        resolved = resolve_contained(
            root, destination, "declared hook destination", strict=True
        )
        if not resolved.is_file():
            raise ValueError(
                f"declared hook destination is not a regular file: {destination}"
            )
    else:
        resolve_contained(
            root, destination, "declared hook destination", strict=False
        )
    return destination


def validate_declared_file(upstream: Path, raw: str, index: int) -> None:
    if not raw.startswith("./"):
        raise ValueError(
            f"declared hook path must start with ./: hooks declaration index {index}"
        )
    checked_file(upstream, Path(raw[2:]))


def classify(
    manifest: dict[str, object], source: str, upstream: Path
) -> dict[str, object]:
    if source == "fallback":
        if "hooks" in manifest:
            raise ValueError("fallback manifest must not declare hooks")
        return {"copy_hooks_subtree": False, "declared_paths": []}
    hooks = manifest.get("hooks", MISSING)
    default_config = upstream / "hooks" / "hooks.json"
    hooks_root = upstream / "hooks"
    hooks_root_present = os.path.lexists(hooks_root)
    if hooks is MISSING or hooks == []:
        return {
            "copy_hooks_subtree": default_config.is_file(),
            "declared_paths": [],
        }
    if hooks == {}:
        return {"copy_hooks_subtree": False, "declared_paths": []}
    if isinstance(hooks, str):
        paths = [hooks]
    elif isinstance(hooks, list) and hooks and all(
        isinstance(value, str) for value in hooks
    ):
        paths = hooks
    elif isinstance(hooks, dict) or (
        isinstance(hooks, list)
        and hooks
        and all(isinstance(value, dict) for value in hooks)
    ):
        return {"copy_hooks_subtree": hooks_root_present, "declared_paths": []}
    else:
        raise ValueError("unsupported or mixed hooks declaration")
    for index, raw in enumerate(paths):
        validate_declared_file(upstream, raw, index)
    return {"copy_hooks_subtree": hooks_root_present, "declared_paths": paths}


def validate_subtree_symlinks(tree: Path, containment_root: Path) -> None:
    resolved_root = containment_root.resolve(strict=True)
    if tree.is_symlink():
        raw_tree_target = Path(os.readlink(tree))
        if raw_tree_target.is_absolute():
            raise ValueError(f"absolute subtree symlink is not allowed: {tree}")
    try:
        resolved_tree = tree.resolve(strict=True)
        resolved_tree.relative_to(resolved_root)
    except (OSError, RuntimeError, ValueError) as exc:
        raise ValueError(f"hook subtree escapes or is broken: {tree}") from exc
    if not resolved_tree.is_dir():
        raise ValueError(f"hook subtree is not a directory: {tree}")
    for path in tree.rglob("*"):
        if not path.is_symlink():
            continue
        raw_target = Path(os.readlink(path))
        if raw_target.is_absolute():
            raise ValueError(f"absolute symlink is not allowed: {path}")
        try:
            resolved_target = path.resolve(strict=True)
            resolved_target.relative_to(resolved_root)
        except (OSError, RuntimeError, ValueError) as exc:
            raise ValueError(f"symlink escapes or is broken: {path}") from exc


def materialize(
    plan: dict[str, object], source_root: Path, candidate_root: Path
) -> None:
    if plan["copy_hooks_subtree"]:
        validate_subtree_symlinks(source_root / "hooks", source_root)
        shutil.copytree(
            source_root / "hooks",
            candidate_root / "hooks",
            symlinks=True,
            dirs_exist_ok=True,
        )
        validate_subtree_symlinks(candidate_root / "hooks", candidate_root)
    declared_paths = plan["declared_paths"]
    if not isinstance(declared_paths, list):
        raise ValueError("internal hook plan has invalid declared paths")
    for raw in declared_paths:
        if not isinstance(raw, str):
            raise ValueError("internal hook plan has a non-string declared path")
        relative = Path(raw[2:])
        source = checked_file(source_root, relative)
        destination = checked_destination(candidate_root, relative)
        destination.parent.mkdir(parents=True, exist_ok=True)
        if not os.path.lexists(destination):
            shutil.copy2(source, destination, follow_symlinks=False)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument("--manifest", required=True)
    parser.add_argument(
        "--manifest-source", choices=("upstream", "fallback"), required=True
    )
    parser.add_argument("--upstream-root", required=True)
    parser.add_argument("--candidate-root", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        source_root = Path(args.upstream_root).resolve(strict=True)
        candidate_root = Path(args.candidate_root).resolve(strict=True)
        manifest = load_manifest(Path(args.manifest))
        plan = classify(manifest, args.manifest_source, source_root)
    except (OSError, RuntimeError, UnicodeError, ValueError) as exc:
        print(f"hook classification failed: {exc}", file=sys.stderr)
        return 1

    try:
        materialize(plan, source_root, candidate_root)
    except (OSError, RuntimeError, UnicodeError, ValueError) as exc:
        print(f"hook materialization failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
