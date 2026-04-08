"""Main BarBridge Flet application — the floating Digital Timing Jig window."""

from __future__ import annotations

import threading
from pathlib import Path

import flet as ft

from barbridge.config import SessionConfig
from barbridge.constants import WINDOW_HEIGHT, WINDOW_TITLE, WINDOW_WIDTH
from barbridge.core.cache import cache_file_count, cache_size_bytes, purge_all, purge_stale_files
from barbridge.core.pipeline import ProcessingResult, process_file
from barbridge.ui.controls import SyncControls
from barbridge.ui.drop_zone import DropZone
from barbridge.ui.export_handle import ExportHandle
from barbridge.ui.status import StatusPanel
from barbridge.utils.ffmpeg import check_ffmpeg
from barbridge.utils.permissions import get_permission_status_message, is_macos


def run_app() -> None:
    """Launch the BarBridge GUI application."""
    ft.app(target=_main)


def _main(page: ft.Page) -> None:
    """Build and configure the main application window."""
    # Window setup
    page.title = WINDOW_TITLE
    page.window.width = WINDOW_WIDTH
    page.window.height = WINDOW_HEIGHT
    page.window.always_on_top = True
    page.window.resizable = False
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 20
    page.scroll = ft.ScrollMode.AUTO

    # Check dependencies
    ffmpeg_info = check_ffmpeg()

    # Build UI components
    status_panel = StatusPanel()
    export_handle = ExportHandle()
    controls = SyncControls()

    def on_file_dropped(file_path: Path) -> None:
        """Handle a file dropped into the drop zone."""
        export_handle.hide()
        status_panel.reset()

        config = SessionConfig(
            bpm=controls.bpm,
            beats_per_bar=controls.beats_per_bar,
            beat_value=controls.beat_value,
            destination_sample_rate=controls.destination_sample_rate,
        )

        start_time = controls.start_time_seconds

        def do_process() -> None:
            try:
                result = process_file(
                    input_path=file_path,
                    start_time=start_time,
                    config=config,
                    on_progress=lambda stage, val: page.run_thread(
                        lambda: status_panel.set_progress(stage, val)
                    ),
                )
                page.run_thread(lambda: _on_complete(result))
            except Exception as exc:
                page.run_thread(lambda: _on_error(str(exc)))

        threading.Thread(target=do_process, daemon=True).start()

    def _on_complete(result: ProcessingResult) -> None:
        drop_zone.set_ready(result.output_path.name)
        status_panel.set_details(result.summary)
        export_handle.show(result.output_path)

    def _on_error(message: str) -> None:
        drop_zone.set_error("Processing failed")
        status_panel.set_error(message)

    drop_zone = DropZone(on_file_dropped=on_file_dropped)

    # File picker for non-drag-and-drop fallback
    file_picker = ft.FilePicker(
        on_result=lambda e: (
            on_file_dropped(Path(e.files[0].path))
            if e.files else None
        ),
    )
    page.overlay.append(file_picker)

    browse_button = ft.TextButton(
        "or Browse Files",
        icon=ft.Icons.FOLDER_OPEN,
        on_click=lambda _: file_picker.pick_files(
            dialog_title="Select audio file",
            allowed_extensions=["wav", "aif", "aiff", "mid", "midi"],
        ),
    )

    # Dependency status
    dep_items = []
    if ffmpeg_info.available:
        dep_items.append(
            ft.Text(f"FFmpeg {ffmpeg_info.version}", size=10, color=ft.Colors.GREEN_400)
        )
    else:
        dep_items.append(
            ft.Text("FFmpeg: Not found", size=10, color=ft.Colors.RED_400)
        )

    if is_macos():
        perm_msg = get_permission_status_message()
        color = ft.Colors.GREEN_400 if "Granted" in perm_msg else ft.Colors.AMBER_400
        dep_items.append(ft.Text(perm_msg.split("\n")[0], size=10, color=color))

    # Cache info & purge button
    config = SessionConfig()

    def purge_cache(_: ft.ControlEvent) -> None:
        removed = purge_all(config.cache_dir)
        cache_label.value = f"Cache: 0 files"
        page.update()

    cache_count = cache_file_count(config.cache_dir)
    cache_label = ft.Text(f"Cache: {cache_count} files", size=10, color=ft.Colors.GREY_500)
    purge_button = ft.TextButton(
        "Purge",
        icon=ft.Icons.DELETE_SWEEP,
        on_click=purge_cache,
        style=ft.ButtonStyle(color=ft.Colors.GREY_500),
    )

    # Purge stale files on startup
    purge_stale_files(config.cache_dir)

    # Layout
    page.add(
        ft.Column(
            [
                # Title
                ft.Text(
                    WINDOW_TITLE,
                    size=22,
                    weight=ft.FontWeight.BOLD,
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Text(
                    "Digital Timing Jig",
                    size=12,
                    color=ft.Colors.GREY_500,
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Divider(height=1, color=ft.Colors.GREY_800),

                # Controls
                controls,
                ft.Divider(height=1, color=ft.Colors.GREY_800),

                # Drop Zone
                drop_zone,
                browse_button,

                # Status
                status_panel,

                # Export Handle
                export_handle,

                ft.Divider(height=1, color=ft.Colors.GREY_800),

                # Footer
                ft.Row(
                    dep_items,
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=16,
                ),
                ft.Row(
                    [cache_label, purge_button],
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=8,
                ),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=12,
        )
    )
