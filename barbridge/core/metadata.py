"""BWF/iXML metadata injection — stamps timing data into file headers."""

from __future__ import annotations

import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

from barbridge.constants import BWFMETAEDIT_BINARY


class MetadataError(Exception):
    """Raised when metadata operations fail."""


def inject_bwf_metadata(
    file_path: Path,
    bpm: float,
    time_reference: int | None = None,
    description: str | None = None,
) -> None:
    """Write BPM and timing metadata into a WAV file's BWF header.

    Uses BWF MetaEdit CLI to stamp:
    - BPM in the description/IXML field
    - Time reference (sample-accurate start position) for DAW grid alignment.

    Args:
        file_path: Path to the WAV file to tag.
        bpm: Tempo in beats per minute.
        time_reference: Sample offset for the BWF time reference field.
            If None, defaults to 0 (file starts at session origin).
        description: Optional text for the BWF Description field.
    """
    if not file_path.suffix.lower() == ".wav":
        raise MetadataError("BWF metadata injection is only supported for WAV files.")

    if time_reference is None:
        time_reference = 0

    if description is None:
        description = f"BarBridge | {bpm} BPM"

    # Try BWF MetaEdit first, fall back to manual iXML
    if _bwfmetaedit_available():
        _inject_via_bwfmetaedit(file_path, bpm, time_reference, description)
    else:
        _inject_via_ixml_manual(file_path, bpm, time_reference, description)


def _bwfmetaedit_available() -> bool:
    """Check if BWF MetaEdit CLI is installed."""
    try:
        subprocess.run(
            [BWFMETAEDIT_BINARY, "--version"],
            capture_output=True,
            check=True,
        )
        return True
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False


def _inject_via_bwfmetaedit(
    file_path: Path,
    bpm: float,
    time_reference: int,
    description: str,
) -> None:
    """Use BWF MetaEdit CLI to write metadata."""
    cmd = [
        BWFMETAEDIT_BINARY,
        "--Description", description,
        "--TimeReference", str(time_reference),
        str(file_path),
    ]
    try:
        subprocess.run(cmd, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError as exc:
        raise MetadataError(f"BWF MetaEdit failed: {exc.stderr.strip()}")


def _inject_via_ixml_manual(
    file_path: Path,
    bpm: float,
    time_reference: int,
    description: str,
) -> None:
    """Fallback: build an iXML chunk and inject it into the WAV file.

    This provides DAW-readable tempo metadata even without BWF MetaEdit.
    The iXML chunk is a standard extension recognized by Reaper, Pro Tools,
    and other professional DAWs.
    """
    ixml = _build_ixml(bpm, time_reference, description)
    _write_ixml_chunk(file_path, ixml)


def _build_ixml(bpm: float, time_reference: int, description: str) -> bytes:
    """Construct an iXML document with tempo and timing info."""
    root = ET.Element("BWFXML")
    ET.SubElement(root, "IXML_VERSION").text = "2.10"

    speed = ET.SubElement(root, "SPEED")
    ET.SubElement(speed, "MASTER_SPEED").text = str(bpm)

    bext = ET.SubElement(root, "BEXT")
    ET.SubElement(bext, "BWF_DESCRIPTION").text = description
    ET.SubElement(bext, "BWF_TIME_REFERENCE").text = str(time_reference)

    return ET.tostring(root, encoding="unicode", xml_declaration=True).encode("utf-8")


def _write_ixml_chunk(file_path: Path, ixml_data: bytes) -> None:
    """Insert or replace the iXML chunk in a WAV/RIFF file.

    WAV files are structured as RIFF containers with chunks.
    We append an 'iXML' chunk at the end and update the RIFF size.
    """
    import struct

    with open(file_path, "r+b") as f:
        # Verify RIFF header
        header = f.read(12)
        if header[:4] != b"RIFF" or header[8:12] != b"WAVE":
            raise MetadataError(f"{file_path.name} is not a valid WAV file.")

        # Read entire file
        f.seek(0)
        data = bytearray(f.read())

    # Remove existing iXML chunk if present
    data = _remove_chunk(data, b"iXML")

    # Build new iXML chunk
    chunk_id = b"iXML"
    # Pad to even length per RIFF spec
    padded_data = ixml_data
    if len(padded_data) % 2 != 0:
        padded_data += b"\x00"
    chunk_size = struct.pack("<I", len(ixml_data))
    chunk = chunk_id + chunk_size + padded_data

    # Append chunk to file
    data.extend(chunk)

    # Update RIFF size (bytes 4-7)
    new_riff_size = len(data) - 8
    data[4:8] = struct.pack("<I", new_riff_size)

    with open(file_path, "wb") as f:
        f.write(data)


def _remove_chunk(data: bytearray, chunk_id: bytes) -> bytearray:
    """Remove a named chunk from RIFF data if it exists."""
    import struct

    pos = 12  # Skip RIFF header
    while pos < len(data) - 8:
        cid = data[pos:pos + 4]
        csize = struct.unpack("<I", data[pos + 4:pos + 8])[0]
        # Account for padding
        total = 8 + csize + (csize % 2)
        if cid == chunk_id:
            del data[pos:pos + total]
            return data
        pos += total
    return data
