#!/usr/bin/env python3
"""Audit Mizan Flutter package boundaries without modifying the repository."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "app_main"
PACKAGES = ROOT / "packages"
FEATURE_ROOT = PACKAGES / "features"
FEATURE_NAMES = {
    path.name
    for path in FEATURE_ROOT.iterdir()
    if path.is_dir() and (path / "pubspec.yaml").exists()
}

DEPENDENCY_RE = re.compile(r"^\s{2}([a-zA-Z0-9_]+):(?:\s|$)")
PATH_DEP_RE = re.compile(r"^\s{4}path:\s+(.+)$")

ALLOWED_FEATURE_EDGES = {
    # Temporary exceptions recorded in the modular architecture contract.
    # New exceptions require updating the contract and this audit together.
}


def package_name(pubspec: Path) -> str:
    for line in pubspec.read_text().splitlines():
        if line.startswith("name:"):
            return line.split(":", 1)[1].strip()
    return pubspec.parent.name


def dependencies(pubspec: Path) -> set[str]:
    values: set[str] = set()
    in_deps = False
    for line in pubspec.read_text().splitlines():
        if line == "dependencies:":
            in_deps = True
            continue
        if in_deps and line and not line.startswith(" "):
            break
        if in_deps:
            match = DEPENDENCY_RE.match(line)
            if match:
                values.add(match.group(1))
    return values


def dart_imports(package_dir: Path) -> list[tuple[Path, str]]:
    results: list[tuple[Path, str]] = []
    for path in package_dir.glob("lib/**/*.dart"):
        text = path.read_text(errors="replace")
        if "supabase_flutter" in text:
            results.append((path, "supabase_flutter"))
    return results


def main() -> int:
    print(f"root={ROOT}")
    print(f"feature_packages={len(FEATURE_NAMES)}")
    print("--- feature dependency edges")
    violations = 0
    for pubspec in sorted(FEATURE_ROOT.glob("*/pubspec.yaml")):
        source = package_name(pubspec)
        for dependency in sorted(dependencies(pubspec)):
            if dependency in FEATURE_NAMES:
                marker = "allowed" if (source, dependency) in ALLOWED_FEATURE_EDGES else "violation"
                print(f"{marker}: {source} -> {dependency}")
                if marker == "violation":
                    violations += 1
    print("--- direct Supabase imports in feature packages")
    supabase_imports = 0
    for package_dir in sorted(FEATURE_ROOT.iterdir()):
        if not package_dir.is_dir():
            continue
        for path, _ in dart_imports(package_dir):
            print(f"direct-supabase: {path.relative_to(ROOT)}")
            supabase_imports += 1
    print("--- summary")
    print(f"feature_dependency_violations={violations}")
    print(f"direct_supabase_import_files={supabase_imports}")
    print("policy=feature packages should depend on public contracts, not private feature implementations")
    # This is initially diagnostic rather than blocking so the existing app can be
    # migrated in controlled waves. CI can switch to blocking after exceptions are removed.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
