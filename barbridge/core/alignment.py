"""Bar-alignment calculation engine — the heart of the Timing Jig."""

from __future__ import annotations

from dataclasses import dataclass

from barbridge.config import SessionConfig


@dataclass(frozen=True)
class AlignmentResult:
    """Describes the padding needed to snap a clip to a bar boundary."""

    original_start_seconds: float
    bar_duration_seconds: float
    offset_into_bar: float
    padding_seconds: float
    target_bar_number: int

    @property
    def aligned_start_seconds(self) -> float:
        """The start time after padding is applied (always a bar boundary)."""
        return self.original_start_seconds - self.offset_into_bar


def calculate_alignment(
    start_time: float,
    config: SessionConfig,
) -> AlignmentResult:
    """Calculate how much silence to prepend so the clip starts on a bar line.

    Args:
        start_time: The clip's original start position in seconds
            (as reported by the source DAW).
        config: Session configuration containing BPM and time signature.

    Returns:
        An AlignmentResult with the computed padding.

    The key formula:
        offset = start_time mod bar_duration
        padding = offset  (we prepend this much silence)

    If the clip already starts on a bar boundary (offset ≈ 0), padding is zero.
    """
    bar_dur = config.bar_duration

    if bar_dur <= 0:
        raise ValueError("Bar duration must be positive (check BPM and time signature).")

    # How far into the current bar the clip starts
    offset = start_time % bar_dur

    # Snap threshold: if within 1 ms of a bar line, treat as aligned
    if offset < 0.001 or (bar_dur - offset) < 0.001:
        offset = 0.0

    # Which bar number this falls on (1-indexed)
    target_bar = int(start_time // bar_dur) + 1

    return AlignmentResult(
        original_start_seconds=start_time,
        bar_duration_seconds=bar_dur,
        offset_into_bar=offset,
        padding_seconds=offset,
        target_bar_number=target_bar,
    )


def bars_to_seconds(bar_number: float, config: SessionConfig) -> float:
    """Convert a bar position (1-indexed, fractional) to seconds.

    Example: bar 5.2 at 120 BPM / 4/4 = 4 full bars + 0.2 bars
        = 4 * 2.0 + 0.2 * 2.0 = 8.4 seconds
    """
    return (bar_number - 1) * config.bar_duration


def seconds_to_bars(seconds: float, config: SessionConfig) -> float:
    """Convert a time in seconds to a bar position (1-indexed, fractional)."""
    return (seconds / config.bar_duration) + 1
