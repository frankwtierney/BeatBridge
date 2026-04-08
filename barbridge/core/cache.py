"""Cache management — automatic cleanup of temporary processed files."""

from __future__ import annotations

import time
from pathlib import Path

from barbridge.constants import CACHE_MAX_AGE_HOURS, OUTPUT_PREFIX


def purge_stale_files(cache_dir: Path, max_age_hours: int = CACHE_MAX_AGE_HOURS) -> list[Path]:
    """Delete processed files older than max_age_hours.

    Returns the list of files that were removed.
    """
    if not cache_dir.exists():
        return []

    cutoff = time.time() - (max_age_hours * 3600)
    removed: list[Path] = []

    for file_path in cache_dir.iterdir():
        if not file_path.is_file():
            continue
        if not file_path.name.startswith(OUTPUT_PREFIX):
            continue
        if file_path.stat().st_mtime < cutoff:
            file_path.unlink()
            removed.append(file_path)

    return removed


def purge_all(cache_dir: Path) -> list[Path]:
    """Remove all BarBridge-processed files from the cache directory.

    Called on app close to prevent storage bloat.
    Returns the list of files that were removed.
    """
    if not cache_dir.exists():
        return []

    removed: list[Path] = []
    for file_path in cache_dir.iterdir():
        if file_path.is_file() and file_path.name.startswith(OUTPUT_PREFIX):
            file_path.unlink()
            removed.append(file_path)

    return removed


def cache_size_bytes(cache_dir: Path) -> int:
    """Total size of all cached processed files in bytes."""
    if not cache_dir.exists():
        return 0
    return sum(
        f.stat().st_size
        for f in cache_dir.iterdir()
        if f.is_file() and f.name.startswith(OUTPUT_PREFIX)
    )


def cache_file_count(cache_dir: Path) -> int:
    """Number of processed files currently in the cache."""
    if not cache_dir.exists():
        return 0
    return sum(
        1 for f in cache_dir.iterdir()
        if f.is_file() and f.name.startswith(OUTPUT_PREFIX)
    )
