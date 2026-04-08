"""Visual status display — progress bar and processing details."""

from __future__ import annotations

import flet as ft


class StatusPanel(ft.UserControl):
    """Displays real-time processing status with a progress bar and detail text."""

    def __init__(self):
        super().__init__()
        self._progress_bar = ft.ProgressBar(
            width=400,
            value=0,
            color=ft.Colors.BLUE_400,
            bgcolor=ft.Colors.GREY_800,
        )
        self._stage_text = ft.Text(
            "Ready",
            size=13,
            color=ft.Colors.GREY_400,
            text_align=ft.TextAlign.CENTER,
        )
        self._detail_text = ft.Text(
            "",
            size=11,
            color=ft.Colors.GREY_500,
            text_align=ft.TextAlign.LEFT,
            selectable=True,
            no_wrap=False,
        )
        self._indicator = ft.Container(
            width=12,
            height=12,
            border_radius=6,
            bgcolor=ft.Colors.GREY_600,
        )

    def build(self) -> ft.Control:
        return ft.Column(
            [
                ft.Row(
                    [self._indicator, self._stage_text],
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=8,
                ),
                self._progress_bar,
                self._detail_text,
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=6,
        )

    def set_progress(self, stage: str, value: float) -> None:
        """Update the progress bar and stage label.

        Args:
            stage: Current processing stage name.
            value: Progress from 0.0 to 1.0.
        """
        self._progress_bar.value = value
        self._stage_text.value = stage

        if value >= 1.0:
            self._indicator.bgcolor = ft.Colors.GREEN_400
            self._progress_bar.color = ft.Colors.GREEN_400
        elif value > 0:
            self._indicator.bgcolor = ft.Colors.AMBER_400
            self._progress_bar.color = ft.Colors.BLUE_400
        else:
            self._indicator.bgcolor = ft.Colors.GREY_600

        self.update()

    def set_details(self, text: str) -> None:
        """Show processing details (file info, alignment summary, etc.)."""
        self._detail_text.value = text
        self.update()

    def set_error(self, message: str) -> None:
        """Show an error state."""
        self._indicator.bgcolor = ft.Colors.RED_400
        self._progress_bar.color = ft.Colors.RED_400
        self._progress_bar.value = 1.0
        self._stage_text.value = "Error"
        self._stage_text.color = ft.Colors.RED_400
        self._detail_text.value = message
        self.update()

    def reset(self) -> None:
        """Reset to idle state."""
        self._progress_bar.value = 0
        self._progress_bar.color = ft.Colors.BLUE_400
        self._indicator.bgcolor = ft.Colors.GREY_600
        self._stage_text.value = "Ready"
        self._stage_text.color = ft.Colors.GREY_400
        self._detail_text.value = ""
        self.update()
