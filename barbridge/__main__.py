"""Entry point for `python -m barbridge`.

Launches the GUI app by default. Pass --cli to use the command-line prototype.
"""

from __future__ import annotations

import sys


def main() -> None:
    if "--cli" in sys.argv:
        sys.argv.remove("--cli")
        from barbridge.cli import main as cli_main
        sys.exit(cli_main())
    else:
        from barbridge.app import run_app
        run_app()


if __name__ == "__main__":
    main()
