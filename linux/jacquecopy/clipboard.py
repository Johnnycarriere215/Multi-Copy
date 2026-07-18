"""Access to the X11 selections via GTK.

CLIPBOARD is the ordinary Ctrl+C/Ctrl+V selection (Clipboard A / system).
PRIMARY is the highlight-to-select buffer, used as a fallback source.
"""

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk  # noqa: E402


class SystemClipboard:
    def __init__(self):
        self._clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
        self._primary = Gtk.Clipboard.get(Gdk.SELECTION_PRIMARY)

    def read_text(self):
        """Return the current CLIPBOARD text, or ``None``."""
        return self._clipboard.wait_for_text()

    def read_primary_text(self):
        """Return the current PRIMARY selection text, or ``None``."""
        return self._primary.wait_for_text()

    def set_text(self, text):
        """Own the CLIPBOARD and serve ``text`` to other applications."""
        if text is None:
            return
        self._clipboard.set_text(text, -1)
        # Ask the clipboard manager to persist the value after we exit.
        self._clipboard.store()
