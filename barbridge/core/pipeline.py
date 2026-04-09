"""Processing pipeline — orchestrates the full analyze → align → resample → tag flow."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from barbridge.config import SessionConfig
from barbridge.core.alignment import AlignmentResult, calculate_alignment
from barbridge.core.analyzer import AudioFileInfo, MidiFileInfo, analyze_file, AnalysisError
from barbridge.core.metadata import inject_bwf_metadata
from barbridge.core.resampler import generate_output_path, pad_and_resample


@dataclass
class ProcessingResult:
    """Complete result of running a file through the BarBridge pipeline."""

    input_path: Path
    output_path: Path
    file_info: AudioFileInfo | MidiFileInfo
    alignment: AlignmentResult
    resampled: bool
    metadata_injected: bool

    @property
    def summary(self) -> str:
        lines = [
            f"Input:    {self.input_path.name}",
            f"Output:   {self.output_path.name}",
        ]
        if isinstance(self.file_info, AudioFileInfo):
            lines.append(f"Format:   {self.file_info.codec} / {self.file_info.sample_rate}Hz / {self.file_info.bit_depth}-bit")
        lines.extend([
            f"Padding:  {self.alignment.padding_seconds:.3f}s",
            f"Bar:      {self.alignment.target_bar_number}",
            f"Resample: {'Yes' if self.resampled else 'No'}",
            f"Tagged:   {'Yes' if self.metadata_injected else 'No'}",
        ])
        return "\n".join(lines)


# Type alias for progress callbacks: (stage_name, progress_0_to_1)
ProgressCallback = Callable[[str, float], None]


def process_file(
    input_path: Path,
    start_time: float,
    config: SessionConfig,
    on_progress: ProgressCallback | None = None,
) -> ProcessingResult:
    """Run a file through the full BarBridge pipeline.

    Steps:
        1. Analyze — detect format, sample rate, bit depth
        2. Align  — calculate padding to snap to bar boundary
        3. Pad & Resample — prepend silence, convert sample rate if needed
        4. Tag — inject BWF/iXML metadata with BPM

    Args:
        input_path: The source audio file dropped by the user.
        start_time: The clip's start position in seconds (from the source DAW).
        config: Current session configuration (BPM, time sig, destination format).
        on_progress: Optional callback for UI progress updates.

    Returns:
        ProcessingResult with all details of what was done.
    """
    _progress(on_progress, "Analyzing", 0.0)

    # 1. Analyze
    file_info = analyze_file(input_path)

    if isinstance(file_info, MidiFileInfo):
        raise AnalysisError(
            "MIDI file processing is not yet supported in the pipeline. "
            "Please drop a .wav or .aif file."
        )

    _progress(on_progress, "Analyzing", 0.2)

    # 2. Calculate alignment
    alignment = calculate_alignment(start_time, config)

    _progress(on_progress, "Aligning", 0.3)

    # 3. Determine if resampling is needed
    needs_resample = file_info.sample_rate != config.destination_sample_rate
    target_sr = config.destination_sample_rate if needs_resample else None
    target_bd = config.destination_bit_depth if needs_resample else None

    # 4. Pad and resample
    output_path = generate_output_path(input_path, config.cache_dir)
    _progress(on_progress, "Processing", 0.4)

    pad_and_resample(
        input_path=input_path,
        output_path=output_path,
        padding_seconds=alignment.padding_seconds,
        target_sample_rate=target_sr,
        target_bit_depth=target_bd,
        channels=file_info.channels,
    )

    _progress(on_progress, "Processing", 0.7)

    # 5. Inject BWF metadata (WAV only)
    metadata_injected = False
    if output_path.suffix.lower() == ".wav":
        time_ref_samples = int(alignment.aligned_start_seconds * config.destination_sample_rate)
        inject_bwf_metadata(
            file_path=output_path,
            bpm=config.bpm,
            time_reference=time_ref_samples,
        )
        metadata_injected = True

    _progress(on_progress, "Complete", 1.0)

    return ProcessingResult(
        input_path=input_path,
        output_path=output_path,
        file_info=file_info,
        alignment=alignment,
        resampled=needs_resample,
        metadata_injected=metadata_injected,
    )


def _progress(callback: ProgressCallback | None, stage: str, value: float) -> None:
    if callback is not None:
        callback(stage, value)
