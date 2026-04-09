"""Global Sync Controls — BPM, Time Signature, Sample Rate, and Start Time inputs."""

from __future__ import annotations

from typing import Callable

import flet as ft

from barbridge.constants import (
    DEFAULT_BPM,
    DEFAULT_SAMPLE_RATE,
    SAMPLE_RATES,
    TIME_SIGNATURES,
)


class SyncControls:
    """Panel of user-adjustable session parameters."""

    def __init__(self, on_change: Callable[[], None] | None = None):
        self._on_change = on_change

        self.bpm_field = ft.TextField(
            label="BPM",
            value=str(DEFAULT_BPM),
            width=100,
            text_align=ft.TextAlign.CENTER,
            keyboard_type=ft.KeyboardType.NUMBER,
            on_change=self._handle_change,
        )

        time_sig_options = [
            ft.dropdown.Option(f"{n}/{d}") for n, d in TIME_SIGNATURES
        ]
        self.time_sig_dropdown = ft.Dropdown(
            label="Time Sig",
            value="4/4",
            width=100,
            options=time_sig_options,
            on_select=self._handle_change,
        )

        sr_options = [
            ft.dropdown.Option(str(sr)) for sr in SAMPLE_RATES
        ]
        self.sample_rate_dropdown = ft.Dropdown(
            label="Dest. Rate (Hz)",
            value=str(DEFAULT_SAMPLE_RATE),
            width=140,
            options=sr_options,
            on_select=self._handle_change,
        )

        self.start_time_field = ft.TextField(
            label="Start (seconds)",
            value="0.0",
            width=140,
            text_align=ft.TextAlign.CENTER,
            keyboard_type=ft.KeyboardType.NUMBER,
            on_change=self._handle_change,
        )

    def build(self) -> ft.Control:
        return ft.Column(
            [
                ft.Text("Session Settings", size=14, weight=ft.FontWeight.BOLD),
                ft.Row(
                    [self.bpm_field, self.time_sig_dropdown],
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=16,
                ),
                ft.Row(
                    [self.sample_rate_dropdown, self.start_time_field],
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=16,
                ),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=8,
        )

    def _handle_change(self, e: ft.ControlEvent) -> None:
        if self._on_change:
            self._on_change()

    @property
    def bpm(self) -> float:
        try:
            val = float(self.bpm_field.value)
            return max(1.0, min(999.0, val))
        except (ValueError, TypeError):
            return DEFAULT_BPM

    @property
    def beats_per_bar(self) -> int:
        ts = self.time_sig_dropdown.value or "4/4"
        return int(ts.split("/")[0])

    @property
    def beat_value(self) -> int:
        ts = self.time_sig_dropdown.value or "4/4"
        return int(ts.split("/")[1])

    @property
    def destination_sample_rate(self) -> int:
        try:
            return int(self.sample_rate_dropdown.value)
        except (ValueError, TypeError):
            return DEFAULT_SAMPLE_RATE

    @property
    def start_time_seconds(self) -> float:
        try:
            return max(0.0, float(self.start_time_field.value))
        except (ValueError, TypeError):
            return 0.0
