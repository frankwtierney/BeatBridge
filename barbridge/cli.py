"""Phase 1 CLI Prototype — processes a file from the command line.

Usage:
    python -m barbridge.cli input.wav --bpm 120 --time-sig 4/4 --bar-pos M3B1
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

from barbridge.config import SessionConfig
from barbridge.core.pipeline import process_file
from barbridge.utils.ffmpeg import check_ffmpeg


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="barbridge-cli",
        description="BarBridge CLI — Resample, tag, and rename audio files for DAW transfer.",
    )
    parser.add_argument(
        "input",
        type=Path,
        help="Path to the source audio file (.wav or .aif).",
    )
    parser.add_argument(
        "--bpm",
        type=float,
        default=120.0,
        help="Session tempo in BPM (default: 120).",
    )
    parser.add_argument(
        "--time-sig",
        type=str,
        default="4/4",
        help="Time signature, e.g. 4/4, 3/4, 6/8 (default: 4/4).",
    )
    parser.add_argument(
        "--bar-pos",
        type=str,
        default="M1B1",
        help="Bar position label, e.g. M3B1 (Measure 3, Beat 1). Used in output filename.",
    )
    parser.add_argument(
        "--start",
        type=float,
        default=0.0,
        help="Clip start time in seconds (default: 0.0).",
    )
    parser.add_argument(
        "--dest-sr",
        type=int,
        default=48000,
        help="Destination sample rate in Hz (default: 48000).",
    )
    parser.add_argument(
        "--dest-bd",
        type=int,
        default=24,
        help="Destination bit depth (default: 24).",
    )

    args = parser.parse_args(argv)

    # Validate input
    if not args.input.exists():
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    # Check FFmpeg
    ffmpeg = check_ffmpeg()
    if not ffmpeg.available:
        print(
            "Error: FFmpeg not found. Install it via `brew install ffmpeg`.",
            file=sys.stderr,
        )
        return 1

    # Parse time signature
    try:
        beats_str, value_str = args.time_sig.split("/")
        beats_per_bar = int(beats_str)
        beat_value = int(value_str)
    except ValueError:
        print(f"Error: Invalid time signature: {args.time_sig}", file=sys.stderr)
        return 1

    config = SessionConfig(
        bpm=args.bpm,
        beats_per_bar=beats_per_bar,
        beat_value=beat_value,
        destination_sample_rate=args.dest_sr,
        destination_bit_depth=args.dest_bd,
    )

    # Progress display
    def on_progress(stage: str, value: float) -> None:
        bar_len = 30
        filled = int(bar_len * value)
        bar = "#" * filled + "-" * (bar_len - filled)
        print(f"\r  [{bar}] {stage:<15} {value*100:5.1f}%", end="", flush=True)

    bar_pos = args.bar_pos
    bpm_int = int(args.bpm)

    print(f"BarBridge CLI")
    print(f"  Input:  {args.input}")
    print(f"  BPM:    {args.bpm}")
    print(f"  Time:   {args.time_sig}")
    print(f"  BarPos: {bar_pos}")
    print(f"  Dest:   {args.dest_sr}Hz / {args.dest_bd}-bit")
    print()

    try:
        result = process_file(
            input_path=args.input,
            start_time=args.start,
            config=config,
            on_progress=on_progress,
        )
    except Exception as exc:
        print(f"\nError: {exc}", file=sys.stderr)
        return 1

    # Rename output file with bar position and BPM tag
    original_output = result.output_path
    stem = args.input.stem
    suffix = original_output.suffix
    tagged_name = f"{stem}_{bar_pos}_{bpm_int}BPM{suffix}"
    tagged_path = original_output.parent / tagged_name

    shutil.move(str(original_output), str(tagged_path))

    print()
    print()
    print(result.summary)
    print(f"\nOutput file: {tagged_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
