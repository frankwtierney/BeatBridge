# BarBridge v1.0

A standalone **Digital Timing Jig** for macOS that automates the alignment, resampling, and metadata tagging of audio/MIDI clips for seamless transfer between DAWs (Logic Pro to Reaper).

## What It Does

BarBridge solves the "small gaps" problem: BPM drift, sample rate mismatch, and bar-alignment errors that break creative flow when moving clips between DAWs.

1. **Drop** a `.wav`, `.aif`, or `.mid` file into the floating window
2. **Set** your BPM, time signature, and clip start time
3. **BarBridge** pads silence to snap the clip to the nearest bar line, resamples if needed (e.g. 44.1k to 48k), and stamps BWF/iXML metadata with the tempo
4. **Drag** the processed file into Reaper — it snaps to the grid automatically

## Requirements

- **Python** 3.10+
- **FFmpeg** — `brew install ffmpeg`
- **BWF MetaEdit** (optional, for professional BWF tagging) — `brew install bwfmetaedit`

## Install

```bash
pip install -e .
```

## Usage

### GUI (default)
```bash
python -m barbridge
# or
barbridge
```

### CLI Prototype
```bash
python -m barbridge --cli input.wav --bpm 120 --time-sig 4/4 --start 8.4 --dest-sr 48000
```

## Project Structure

```
barbridge/
├── __main__.py        # Entry point (GUI or --cli)
├── app.py             # Flet GUI application
├── cli.py             # Phase 1 CLI prototype
├── config.py          # Session configuration dataclass
├── constants.py       # App-wide constants
├── core/
│   ├── analyzer.py    # Audio/MIDI file analysis (ffprobe)
│   ├── alignment.py   # Bar-alignment calculation engine
│   ├── resampler.py   # FFmpeg silence-padding & resampling
│   ├── metadata.py    # BWF/iXML metadata injection
│   ├── pipeline.py    # Full processing orchestrator
│   └── cache.py       # Temp file cache management
├── ui/
│   ├── drop_zone.py   # Drag-and-drop input area
│   ├── controls.py    # BPM, time sig, sample rate inputs
│   ├── status.py      # Progress bar & status display
│   └── export_handle.py  # Drag-out handle for processed files
└── utils/
    ├── ffmpeg.py       # FFmpeg availability detection
    └── permissions.py  # macOS Full Disk Access handler
```
