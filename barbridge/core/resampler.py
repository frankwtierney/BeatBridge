"""Audio processing engine — silence padding, resampling, and stitching via FFmpeg."""

from __future__ import annotations

import subprocess
from pathlib import Path

from barbridge.constants import FFMPEG_BINARY, OUTPUT_PREFIX


class ResamplerError(Exception):
    """Raised when an FFmpeg operation fails."""


def pad_and_resample(
    input_path: Path,
    output_path: Path,
    padding_seconds: float,
    target_sample_rate: int | None = None,
    target_bit_depth: int | None = None,
    channels: int | None = None,
) -> Path:
    """Add silence to the beginning of an audio file and optionally resample.

    This is the core "Clean Cut" operation:
    1. Generate silence of the required duration.
    2. Concatenate silence + original audio.
    3. If target_sample_rate differs from source, resample in the same pass.

    Args:
        input_path: Source audio file.
        output_path: Where to write the processed file.
        padding_seconds: Seconds of silence to prepend.
        target_sample_rate: Desired output sample rate (Hz). None = keep original.
        target_bit_depth: Desired output bit depth. None = keep original.
        channels: Number of audio channels. None = keep original.

    Returns:
        Path to the output file.
    """
    _ensure_ffmpeg()

    if padding_seconds < 0:
        raise ResamplerError("Padding duration cannot be negative.")

    # Determine output PCM format from bit depth
    pcm_format = _bit_depth_to_pcm(target_bit_depth) if target_bit_depth else None

    if padding_seconds > 0:
        return _pad_and_convert(
            input_path, output_path, padding_seconds,
            target_sample_rate, pcm_format, channels,
        )
    else:
        return _convert_only(
            input_path, output_path,
            target_sample_rate, pcm_format, channels,
        )


def _pad_and_convert(
    input_path: Path,
    output_path: Path,
    padding_seconds: float,
    sample_rate: int | None,
    pcm_format: str | None,
    channels: int | None,
) -> Path:
    """Prepend silence and convert in a single FFmpeg pass using the adelay filter."""
    # Use the lavfi virtual device to generate silence, then concatenate
    # via the concat demuxer. This is more reliable than filter-based approaches.

    # Build the FFmpeg command using the adelay filter approach:
    # Input the file, apply a delay (which prepends silence).
    delay_ms = int(padding_seconds * 1000)

    cmd = [
        FFMPEG_BINARY, "-y",
        "-i", str(input_path),
        "-af", f"adelay={delay_ms}|{delay_ms},apad=pad_dur=0",
    ]

    # Apply conversion options
    if sample_rate:
        cmd.extend(["-ar", str(sample_rate)])
    if pcm_format:
        cmd.extend(["-acodec", pcm_format])
    if channels:
        cmd.extend(["-ac", str(channels)])

    cmd.append(str(output_path))
    _run_ffmpeg(cmd)
    return output_path


def _convert_only(
    input_path: Path,
    output_path: Path,
    sample_rate: int | None,
    pcm_format: str | None,
    channels: int | None,
) -> Path:
    """Resample / re-encode without adding padding."""
    cmd = [FFMPEG_BINARY, "-y", "-i", str(input_path)]

    if sample_rate:
        cmd.extend(["-ar", str(sample_rate)])
    if pcm_format:
        cmd.extend(["-acodec", pcm_format])
    if channels:
        cmd.extend(["-ac", str(channels)])

    cmd.append(str(output_path))
    _run_ffmpeg(cmd)
    return output_path


def generate_output_path(input_path: Path, cache_dir: Path) -> Path:
    """Create a deterministic output filename inside the cache directory."""
    stem = input_path.stem
    suffix = input_path.suffix
    return cache_dir / f"{OUTPUT_PREFIX}{stem}{suffix}"


def _bit_depth_to_pcm(bit_depth: int) -> str:
    """Map bit depth to an FFmpeg PCM codec name."""
    mapping = {
        16: "pcm_s16le",
        24: "pcm_s24le",
        32: "pcm_s32le",
    }
    codec = mapping.get(bit_depth)
    if codec is None:
        raise ResamplerError(
            f"Unsupported bit depth: {bit_depth}. Supported: {sorted(mapping.keys())}"
        )
    return codec


def _ensure_ffmpeg() -> None:
    """Check that FFmpeg is reachable."""
    try:
        subprocess.run(
            [FFMPEG_BINARY, "-version"],
            capture_output=True, check=True,
        )
    except FileNotFoundError:
        raise ResamplerError(
            f"'{FFMPEG_BINARY}' not found on PATH. "
            "Install it via `brew install ffmpeg` or download from https://ffmpeg.org."
        )


def _run_ffmpeg(cmd: list[str]) -> subprocess.CompletedProcess:
    """Execute an FFmpeg command and handle errors."""
    try:
        return subprocess.run(cmd, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError as exc:
        raise ResamplerError(f"FFmpeg failed:\n{exc.stderr.strip()}")
