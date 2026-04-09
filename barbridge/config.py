"""Runtime configuration for a BarBridge session."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from barbridge.constants import (
    CACHE_DIR_NAME,
    CACHE_MAX_AGE_HOURS,
    DEFAULT_BEAT_VALUE,
    DEFAULT_BEATS_PER_BAR,
    DEFAULT_BPM,
    DEFAULT_SAMPLE_RATE,
    DEFAULT_BIT_DEPTH,
)


@dataclass
class SessionConfig:
    """Holds the user-adjustable parameters for the current session."""

    bpm: float = DEFAULT_BPM
    beats_per_bar: int = DEFAULT_BEATS_PER_BAR
    beat_value: int = DEFAULT_BEAT_VALUE
    destination_sample_rate: int = DEFAULT_SAMPLE_RATE
    destination_bit_depth: int = DEFAULT_BIT_DEPTH
    cache_dir: Path = field(default_factory=lambda: Path.home() / CACHE_DIR_NAME)
    cache_max_age_hours: int = CACHE_MAX_AGE_HOURS

    def __post_init__(self) -> None:
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    @property
    def bar_duration(self) -> float:
        """Duration of one bar in seconds.

        Formula: (60 / BPM) * beats_per_bar
        """
        return (60.0 / self.bpm) * self.beats_per_bar

    @property
    def time_signature_label(self) -> str:
        return f"{self.beats_per_bar}/{self.beat_value}"
