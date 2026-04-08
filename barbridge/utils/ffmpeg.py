"""FFmpeg availability checks and version detection."""

from __future__ import annotations

import subprocess
from dataclasses import dataclass

from barbridge.constants import FFMPEG_BINARY, FFPROBE_BINARY


@dataclass(frozen=True)
class FFmpegInfo:
    """Version and capability info for the local FFmpeg install."""

    version: str
    path: str
    available: bool


def check_ffmpeg() -> FFmpegInfo:
    """Detect whether FFmpeg is installed and return version info."""
    try:
        result = subprocess.run(
            [FFMPEG_BINARY, "-version"],
            capture_output=True,
            text=True,
            check=True,
        )
        first_line = result.stdout.split("\n")[0]
        # e.g. "ffmpeg version 6.1.1 Copyright ..."
        version = first_line.split("version")[-1].strip().split(" ")[0]

        # Resolve the binary path
        which = subprocess.run(
            ["which", FFMPEG_BINARY],
            capture_output=True,
            text=True,
        )
        path = which.stdout.strip() or FFMPEG_BINARY

        return FFmpegInfo(version=version, path=path, available=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        return FFmpegInfo(version="", path="", available=False)


def check_ffprobe() -> bool:
    """Check if ffprobe is available."""
    try:
        subprocess.run(
            [FFPROBE_BINARY, "-version"],
            capture_output=True,
            check=True,
        )
        return True
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False
