"""Analyzes incoming audio/MIDI files to extract format metadata."""

from __future__ import annotations

import json
import subprocess
from dataclasses import dataclass
from pathlib import Path

from barbridge.constants import (
    FFPROBE_BINARY,
    SUPPORTED_AUDIO_EXTENSIONS,
    SUPPORTED_MIDI_EXTENSIONS,
)


@dataclass(frozen=True)
class AudioFileInfo:
    """Immutable snapshot of an audio file's properties."""

    path: Path
    sample_rate: int
    bit_depth: int
    channels: int
    duration_seconds: float
    codec: str
    format_name: str

    @property
    def is_wav(self) -> bool:
        return self.path.suffix.lower() == ".wav"

    @property
    def is_aiff(self) -> bool:
        return self.path.suffix.lower() in {".aif", ".aiff"}


@dataclass(frozen=True)
class MidiFileInfo:
    """Basic info about a MIDI file."""

    path: Path
    num_tracks: int
    ticks_per_beat: int
    duration_seconds: float


class AnalysisError(Exception):
    """Raised when file analysis fails."""


def analyze_file(path: Path) -> AudioFileInfo | MidiFileInfo:
    """Detect the type and properties of a dropped file.

    Returns an AudioFileInfo for .wav/.aif files, or MidiFileInfo for .mid files.
    Raises AnalysisError if the file is unsupported or cannot be read.
    """
    path = Path(path)
    suffix = path.suffix.lower()

    if suffix in SUPPORTED_AUDIO_EXTENSIONS:
        return _analyze_audio(path)
    elif suffix in SUPPORTED_MIDI_EXTENSIONS:
        return _analyze_midi(path)
    else:
        raise AnalysisError(
            f"Unsupported file type: {suffix}. "
            f"Expected one of: {', '.join(sorted(SUPPORTED_AUDIO_EXTENSIONS | SUPPORTED_MIDI_EXTENSIONS))}"
        )


def _analyze_audio(path: Path) -> AudioFileInfo:
    """Use ffprobe to extract audio file metadata."""
    cmd = [
        FFPROBE_BINARY,
        "-v", "quiet",
        "-print_format", "json",
        "-show_format",
        "-show_streams",
        str(path),
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    except FileNotFoundError:
        raise AnalysisError(
            f"'{FFPROBE_BINARY}' not found. Please install FFmpeg "
            "(e.g. `brew install ffmpeg`)."
        )
    except subprocess.CalledProcessError as exc:
        raise AnalysisError(f"ffprobe failed on {path.name}: {exc.stderr.strip()}")

    data = json.loads(result.stdout)

    # Find the audio stream
    audio_stream = None
    for stream in data.get("streams", []):
        if stream.get("codec_type") == "audio":
            audio_stream = stream
            break

    if audio_stream is None:
        raise AnalysisError(f"No audio stream found in {path.name}")

    sample_rate = int(audio_stream.get("sample_rate", 0))
    channels = int(audio_stream.get("channels", 0))
    codec = audio_stream.get("codec_name", "unknown")

    # Bit depth: try bits_per_raw_sample first, then bits_per_sample
    bit_depth = int(
        audio_stream.get("bits_per_raw_sample")
        or audio_stream.get("bits_per_sample")
        or 0
    )

    # Duration: prefer stream duration, fall back to format duration
    duration = float(
        audio_stream.get("duration")
        or data.get("format", {}).get("duration")
        or 0.0
    )

    format_name = data.get("format", {}).get("format_name", "unknown")

    return AudioFileInfo(
        path=path,
        sample_rate=sample_rate,
        bit_depth=bit_depth,
        channels=channels,
        duration_seconds=duration,
        codec=codec,
        format_name=format_name,
    )


def _analyze_midi(path: Path) -> MidiFileInfo:
    """Use the mido library to read MIDI file properties."""
    try:
        import mido
    except ImportError:
        raise AnalysisError("mido library not installed. Run: pip install mido")

    try:
        mid = mido.MidiFile(str(path))
    except Exception as exc:
        raise AnalysisError(f"Failed to read MIDI file {path.name}: {exc}")

    return MidiFileInfo(
        path=path,
        num_tracks=len(mid.tracks),
        ticks_per_beat=mid.ticks_per_beat,
        duration_seconds=mid.length,
    )
