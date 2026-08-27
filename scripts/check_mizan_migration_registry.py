#!/usr/bin/env python3
"""Validate Mizan's canonical Supabase migration registry."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS = ROOT / "app_main" / "supabase" / "migrations"
REGISTRY = ROOT / "app_main" / "supabase" / "MIGRATION_REGISTRY.md"
MIGRATION_RE = re.compile(r"^(\d{14}_[a-z0-9_]+)\.sql$")
REGISTRY_RE = re.compile(r"`(\d{14}_[a-z0-9_]+\.sql)`")
REQUIRED_HEADER_FIELDS = ("-- owner:", "-- prerequisites:", "-- changes:", "-- security:", "-- verification:", "-- rollback:")


def main() -> int:
    files = sorted(path.name for path in MIGRATIONS.glob("*.sql"))
    ids = [MIGRATION_RE.match(name).group(1) for name in files if MIGRATION_RE.match(name)]
    errors: list[str] = []
    if len(ids) != len(set(ids)):
        errors.append("duplicate migration IDs detected")
    registered = set(REGISTRY_RE.findall(REGISTRY.read_text()))
    missing = [name for name in files if name not in registered]
    unknown = sorted(registered.difference(files))
    if missing:
        errors.append("unregistered migrations: " + ", ".join(missing))
    if unknown:
        errors.append("registry references missing files: " + ", ".join(unknown))
    latest_id = max(ids) if ids else ""
    for path in MIGRATIONS.glob("*.sql"):
        match = MIGRATION_RE.match(path.name)
        if not match:
            errors.append(f"invalid migration filename: {path.name}")
            continue
        # Existing historical migrations predate the header standard. Enforce it
        # for new migration IDs after the registry baseline.
        if match.group(1) > "20260827293000_manual_balance_adjustment_workflow" and not all(
            field in path.read_text(errors="replace")[:1200] for field in REQUIRED_HEADER_FIELDS
        ):
            errors.append(f"new migration lacks required header fields: {path.name}")
    print(f"migration_files={len(files)}")
    print(f"registered_files={len(registered)}")
    print(f"latest_migration={latest_id}.sql" if latest_id else "latest_migration=none")
    print(f"errors={len(errors)}")
    for error in errors:
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
