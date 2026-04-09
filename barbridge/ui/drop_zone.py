"""Smart Drop Zone — accepts files dragged from Logic Pro, Finder, or any macOS app."""

from __future__ import annotations

from pathlib import Path
from typing import Callable

import flet as ft
import flet_dropzone as ftd

from barbridge.constants import SUPPORTED_EXTENSIONS


def create_drop_zone(
    on_file_dropped: Callable[[Path], None],
    width: int = 420,
    height: int = 160,
) -> tuple[ftd.Dropzone, ft.Text, ft.Icon, ft.Container]:
    """Build an OS-level drop zone that receives files from external apps."""
    status_text = ft.Text(
        "Drop .wav, .aif, or .mid file here",
        size=16,
        weight=ft.FontWeight.W_500,
        text_align=ft.TextAlign.CENTER,
        color=ft.Colors.GREY_400,
    )
    icon = ft.Icon(
        ft.Icons.AUDIO_FILE,
        size=48,
        color=ft.Colors.GREY_400,
    )
    container = ft.Container(
        content=ft.Column(
            [icon, status_text],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=12,
        ),
        width=width,
        height=height,
        border=ft.Border.all(width=2, color=ft.Colors.GREY_600),
        border_radius=12,
        alignment=ft.Alignment(0, 0),
        bgcolor=ft.Colors.with_opacity(0.05, ft.Colors.WHITE),
    )

    def _on_dropped(e: ftd.DropzoneEvent) -> None:
        if not e.files:
            return
        file_path = Path(e.files[0])
        if file_path.suffix.lower() in SUPPORTED_EXTENSIONS:
            status_text.value = f"Processing: {file_path.name}"
            status_text.color = ft.Colors.AMBER_300
            icon.color = ft.Colors.AMBER_300
            container.border = ft.Border.all(width=2, color=ft.Colors.AMBER_400)
            on_file_dropped(file_path)
        else:
            status_text.value = f"Unsupported: {file_path.suffix}"
            status_text.color = ft.Colors.RED_300
            icon.color = ft.Colors.RED_300

    def _on_entered(e) -> None:
        container.border = ft.Border.all(width=3, color=ft.Colors.BLUE_400)
        container.bgcolor = ft.Colors.with_opacity(0.1, ft.Colors.BLUE)
        status_text.value = "Release to process"
        status_text.color = ft.Colors.BLUE_300
        icon.color = ft.Colors.BLUE_300

    def _on_exited(e) -> None:
        _reset_visuals(container, status_text, icon)

    dropzone = ftd.Dropzone(
        content=container,
        allowed_file_types=["wav", "aif", "aiff", "mid", "midi"],
        on_dropped=_on_dropped,
        on_entered=_on_entered,
        on_exited=_on_exited,
    )

    return dropzone, status_text, icon, container


def set_drop_zone_ready(
    container: ft.Container, status_text: ft.Text, icon: ft.Icon, filename: str,
) -> None:
    status_text.value = f"Ready: {filename}"
    status_text.color = ft.Colors.GREEN_400
    icon.color = ft.Colors.GREEN_400
    icon.name = ft.Icons.CHECK_CIRCLE
    container.border = ft.Border.all(width=2, color=ft.Colors.GREEN_600)


def set_drop_zone_error(
    container: ft.Container, status_text: ft.Text, icon: ft.Icon, message: str,
) -> None:
    status_text.value = message
    status_text.color = ft.Colors.RED_400
    icon.color = ft.Colors.RED_400
    icon.name = ft.Icons.ERROR
    container.border = ft.Border.all(width=2, color=ft.Colors.RED_600)


def reset_drop_zone(
    container: ft.Container, status_text: ft.Text, icon: ft.Icon,
) -> None:
    icon.name = ft.Icons.AUDIO_FILE
    _reset_visuals(container, status_text, icon)


def _reset_visuals(
    container: ft.Container, status_text: ft.Text, icon: ft.Icon,
) -> None:
    container.border = ft.Border.all(width=2, color=ft.Colors.GREY_600)
    container.bgcolor = ft.Colors.with_opacity(0.05, ft.Colors.WHITE)
    status_text.value = "Drop .wav, .aif, or .mid file here"
    status_text.color = ft.Colors.GREY_400
    icon.color = ft.Colors.GREY_400
