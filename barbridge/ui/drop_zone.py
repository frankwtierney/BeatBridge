"""Smart Drop Zone — the drag-and-drop input area for BarBridge."""

from __future__ import annotations

from pathlib import Path
from typing import Callable

import flet as ft

from barbridge.constants import SUPPORTED_EXTENSIONS


class DropZone(ft.UserControl):
    """A drag-and-drop target that accepts audio/MIDI files.

    Provides visual feedback during drag hover and validates file types
    before passing them to the on_file_dropped callback.
    """

    def __init__(
        self,
        on_file_dropped: Callable[[Path], None],
        width: int = 420,
        height: int = 160,
    ):
        super().__init__()
        self._on_file_dropped = on_file_dropped
        self._width = width
        self._height = height
        self._is_hovering = False
        self._status_text = ft.Text(
            "Drop .wav, .aif, or .mid file here",
            size=16,
            weight=ft.FontWeight.W_500,
            text_align=ft.TextAlign.CENTER,
            color=ft.Colors.GREY_400,
        )
        self._icon = ft.Icon(
            ft.Icons.AUDIO_FILE,
            size=48,
            color=ft.Colors.GREY_400,
        )
        self._container: ft.Container | None = None

    def build(self) -> ft.Control:
        self._container = ft.Container(
            content=ft.Column(
                [self._icon, self._status_text],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=12,
            ),
            width=self._width,
            height=self._height,
            border=ft.border.all(2, ft.Colors.GREY_600),
            border_radius=12,
            alignment=ft.alignment.center,
            bgcolor=ft.Colors.with_opacity(0.05, ft.Colors.WHITE),
        )

        return ft.DragTarget(
            content=self._container,
            on_accept=self._on_accept,
            on_will_accept=self._on_will_accept,
            on_leave=self._on_leave,
        )

    def _on_will_accept(self, e: ft.DragTargetAcceptEvent) -> None:
        """Visual feedback when a file hovers over the drop zone."""
        self._is_hovering = True
        if self._container:
            self._container.border = ft.border.all(3, ft.Colors.BLUE_400)
            self._container.bgcolor = ft.Colors.with_opacity(0.1, ft.Colors.BLUE)
        self._status_text.value = "Release to process"
        self._status_text.color = ft.Colors.BLUE_300
        self._icon.color = ft.Colors.BLUE_300
        self.update()

    def _on_leave(self, e) -> None:
        """Reset visuals when drag leaves."""
        self._is_hovering = False
        self._reset_visuals()
        self.update()

    def _on_accept(self, e: ft.DragTargetAcceptEvent) -> None:
        """Handle a dropped file."""
        self._is_hovering = False
        self._reset_visuals()

        file_path = Path(e.data) if isinstance(e.data, str) else None

        if file_path and file_path.suffix.lower() in SUPPORTED_EXTENSIONS:
            self._status_text.value = f"Processing: {file_path.name}"
            self._status_text.color = ft.Colors.AMBER_300
            self._icon.color = ft.Colors.AMBER_300
            self.update()
            self._on_file_dropped(file_path)
        else:
            self._status_text.value = "Unsupported file type"
            self._status_text.color = ft.Colors.RED_300
            self._icon.color = ft.Colors.RED_300
            self.update()

    def _reset_visuals(self) -> None:
        if self._container:
            self._container.border = ft.border.all(2, ft.Colors.GREY_600)
            self._container.bgcolor = ft.Colors.with_opacity(0.05, ft.Colors.WHITE)
        self._status_text.value = "Drop .wav, .aif, or .mid file here"
        self._status_text.color = ft.Colors.GREY_400
        self._icon.color = ft.Colors.GREY_400

    def set_ready(self, filename: str) -> None:
        """Update the drop zone to show a successfully processed file."""
        self._status_text.value = f"Ready: {filename}"
        self._status_text.color = ft.Colors.GREEN_400
        self._icon.color = ft.Colors.GREEN_400
        self._icon.name = ft.Icons.CHECK_CIRCLE
        self.update()

    def set_error(self, message: str) -> None:
        """Show an error state in the drop zone."""
        self._status_text.value = message
        self._status_text.color = ft.Colors.RED_400
        self._icon.color = ft.Colors.RED_400
        self._icon.name = ft.Icons.ERROR
        self.update()

    def reset(self) -> None:
        """Reset to initial state."""
        self._icon.name = ft.Icons.AUDIO_FILE
        self._reset_visuals()
        self.update()
