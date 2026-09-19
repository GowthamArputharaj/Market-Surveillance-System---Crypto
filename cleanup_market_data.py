#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parent
DATA_DIRS = ("hdb", "intraday", "log")
PRESERVE = {
    ROOT / "hdb" / "sym",
    ROOT / "intraday" / "sym",
}


def should_preserve(path: Path) -> bool:
    return path.resolve() in PRESERVE


def iter_delete_targets(root: Path) -> list[Path]:
    if not root.exists():
        return []

    targets: list[Path] = []
    for path in sorted(root.rglob("*"), key=lambda p: len(p.parts), reverse=True):
        if should_preserve(path):
            continue
        targets.append(path)
    return targets


def delete_path(path: Path, dry_run: bool) -> None:
    action = "Would delete" if dry_run else "Deleting"
    print(f"{action}: {path.relative_to(ROOT)}")

    if dry_run:
        return

    if path.is_dir():
        try:
            path.rmdir()
        except OSError:
            shutil.rmtree(path)
    else:
        path.unlink()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Delete MSS hdb/intraday/log data while preserving root sym files."
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Actually delete files. Without this flag, the script only prints what it would delete.",
    )
    args = parser.parse_args()

    dry_run = not args.yes
    for dirname in DATA_DIRS:
        data_root = ROOT / dirname
        for target in iter_delete_targets(data_root):
            delete_path(target, dry_run)

    if dry_run:
        print("\nDry run only. Re-run with --yes to delete these files.")
    else:
        print("\nCleanup complete. Preserved hdb/sym and intraday/sym.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
