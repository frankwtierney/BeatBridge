"""macOS permission handling — guides users through Full Disk Access setup."""

from __future__ import annotations

import os
import platform
import subprocess
import sys


def is_macos() -> bool:
    return platform.system() == "Darwin"


def check_full_disk_access() -> bool:
    """Test whether the app has sufficient file access.

    On macOS, DAW project folders are often sandboxed. We attempt to read
    a known protected path to check if Full Disk Access is granted.
    On non-macOS, we assume access is fine.
    """
    if not is_macos():
        return True

    # Try reading a path that requires FDA
    test_paths = [
        os.path.expanduser("~/Library/Application Support/Logic"),
        os.path.expanduser("~/Library/Application Support/REAPER"),
    ]

    for path in test_paths:
        if os.path.exists(path):
            try:
                os.listdir(path)
                return True
            except PermissionError:
                return False

    # If neither DAW directory exists yet, we can't test — assume OK
    return True


def request_full_disk_access() -> None:
    """Open macOS System Settings to the Full Disk Access pane.

    This is the only programmatic way to guide users — macOS does not allow
    apps to grant themselves access.
    """
    if not is_macos():
        return

    subprocess.run([
        "open",
        "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
    ])


def get_permission_status_message() -> str:
    """Return a human-readable status string for the UI."""
    if not is_macos():
        return "Non-macOS platform — no special permissions needed."

    if check_full_disk_access():
        return "Full Disk Access: Granted"
    else:
        return (
            "Full Disk Access: Not Granted\n"
            "BarBridge needs Full Disk Access to read/write files across DAW sandboxes.\n"
            "Go to System Settings > Privacy & Security > Full Disk Access and enable BarBridge."
        )
