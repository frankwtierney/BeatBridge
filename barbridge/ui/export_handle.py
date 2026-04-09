"""Export Handle — the drag-out component for processed files."""

from __future__ import annotations

import platform
import subprocess
from pathlib import Path

import flet as ft


class ExportHandle:
    """A handle that appears after processing with Reveal and Copy Path buttons."""

    def __init__(self, page: ft.Page | None = None):
        self._page = page
        self._output_path: Path | None = None
        self._filename_text = ft.Text(
            "",
            size=13,
            weight=ft.FontWeight.W_500,
            color=ft.Colors.GREEN_300,
            text_align=ft.TextAlign.CENTER,
        )
        self._drag_icon = ft.Icon(
            ft.Icons.DRAG_INDICATOR,
            size=32,
            color=ft.Colors.GREEN_400,
        )
        self._reveal_button = ft.IconButton(
            icon=ft.Icons.FOLDER_OPEN,
            tooltip="Reveal in Finder",
            icon_color=ft.Colors.GREY_400,
            on_click=self._reveal_in_finder,
        )
        self._copy_button = ft.IconButton(
            icon=ft.Icons.COPY,
            tooltip="Copy file path",
            icon_color=ft.Colors.GREY_400,
            on_click=self._copy_path,
        )
        self._container = ft.Container(
            content=ft.Row(
                [
                    self._drag_icon,
                    ft.Column(
                        [
                            ft.Text("Drag to DAW", size=11, color=ft.Colors.GREY_500),
                            self._filename_text,
                        ],
                        spacing=2,
                        expand=True,
                    ),
                    self._reveal_button,
                    self._copy_button,
                ],
                alignment=ft.MainAxisAlignment.CENTER,
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=8,
            ),
            padding=12,
            border=ft.border.all(1, ft.Colors.GREEN_800),
            border_radius=8,
            bgcolor=ft.Colors.with_opacity(0.08, ft.Colors.GREEN),
            visible=False,
            width=420,
        )

    def build(self) -> ft.Control:
        return self._container

    def show(self, output_path: Path) -> None:
        self._output_path = output_path
        self._filename_text.value = output_path.name
        self._container.visible = True
        self._filename_text.update()
        self._container.update()

    def hide(self) -> None:
        self._output_path = None
        self._container.visible = False
        self._container.update()

    def _reveal_in_finder(self, e: ft.ControlEvent) -> None:
        if self._output_path and self._output_path.exists():
            if platform.system() == "Darwin":
                subprocess.run(["open", "-R", str(self._output_path)])
            elif platform.system() == "Linux":
                subprocess.run(["xdg-open", str(self._output_path.parent)])

    def _copy_path(self, e: ft.ControlEvent) -> None:
        if self._output_path and self._page:
            self._page.set_clipboard(str(self._output_path))
            self._copy_button.icon = ft.Icons.CHECK
            self._copy_button.icon_color = ft.Colors.GREEN_400
            self._copy_button.update()
