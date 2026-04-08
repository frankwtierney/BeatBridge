"""Application-wide constants and defaults."""

from pathlib import Path

APP_NAME = "BarBridge"
APP_VERSION = "1.0.0"

# Supported input formats
SUPPORTED_AUDIO_EXTENSIONS = {".wav", ".aif", ".aiff"}
SUPPORTED_MIDI_EXTENSIONS = {".mid", ".midi"}
SUPPORTED_EXTENSIONS = SUPPORTED_AUDIO_EXTENSIONS | SUPPORTED_MIDI_EXTENSIONS

# Default session parameters
DEFAULT_BPM = 120.0
DEFAULT_BEATS_PER_BAR = 4
DEFAULT_BEAT_VALUE = 4  # denominator of time signature
DEFAULT_SAMPLE_RATE = 48000
DEFAULT_BIT_DEPTH = 24

# Common sample rates (Hz)
SAMPLE_RATES = [44100, 48000, 88200, 96000]

# Common time signatures: (beats_per_bar, beat_value)
TIME_SIGNATURES = [
    (3, 4),
    (4, 4),
    (5, 4),
    (6, 8),
    (7, 8),
]

# Cache settings
CACHE_DIR_NAME = ".barbridge_cache"
CACHE_MAX_AGE_HOURS = 24

# FFmpeg binary name (expects it on PATH or bundled)
FFMPEG_BINARY = "ffmpeg"
FFPROBE_BINARY = "ffprobe"

# BWF MetaEdit binary name
BWFMETAEDIT_BINARY = "bwfmetaedit"

# UI constants
WINDOW_WIDTH = 480
WINDOW_HEIGHT = 640
WINDOW_TITLE = f"{APP_NAME} v{APP_VERSION}"

# Processing output prefix
OUTPUT_PREFIX = "BB_"
