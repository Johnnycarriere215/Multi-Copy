"""The dual-clipboard engine.

Coordinates the system clipboard (A), the secondary clipboard (B), history,
and the Alt+C / Alt+V capture-and-paste flows. All public mutations happen on
the GLib main loop, so UI listeners can update widgets safely.
"""

from gi.repository import GLib

from .clipboard import SystemClipboard
from .inject import KeyInjector
from .store import HistoryStore

# Delay (ms) to let the focused app respond to an injected Ctrl+C / Ctrl+V
# before we read or restore the clipboard.
_CAPTURE_DELAY_MS = 160
_RESTORE_DELAY_MS = 220
_POLL_INTERVAL_MS = 500


class ClipboardEngine:
    def __init__(self, settings):
        self.settings = settings
        self.clipboard = SystemClipboard()
        self.injector = KeyInjector()
        self.history = HistoryStore(max_items=settings.get("max_history"))

        self.clipboard_a_text = None   # current system clipboard
        self.clipboard_b_text = None   # secondary clipboard
        self._last_seen_text = None    # for change detection
        self._busy = False             # pause monitor during A<->B juggling
        self._listeners = []

        # Seed from whatever is on the clipboard right now.
        current = self.clipboard.read_text()
        if current:
            self.clipboard_a_text = current
            self._last_seen_text = current

    # -- listeners -------------------------------------------------------

    def add_listener(self, callback):
        self._listeners.append(callback)

    def _notify(self):
        for callback in list(self._listeners):
            GLib.idle_add(callback)

    # -- monitoring ------------------------------------------------------

    def start_monitoring(self):
        GLib.timeout_add(_POLL_INTERVAL_MS, self._poll_system_clipboard)

    def _poll_system_clipboard(self):
        if self._busy or not self.settings.get("monitor_system_clipboard"):
            return True
        text = self.clipboard.read_text()
        if text and text != self._last_seen_text:
            self._last_seen_text = text
            self.clipboard_a_text = text
            self.history.add(text, source="A")
            self._notify()
        return True  # keep the timeout alive

    # -- secondary clipboard (B) ----------------------------------------

    def copy_selection_to_b(self):
        """Alt+C: capture the focused app's current selection into Clipboard B.

        Injects a real Ctrl+C, reads the result, stores it to B, then restores
        the system clipboard so Clipboard A is left untouched.
        """
        backup = self.clipboard.read_text()
        if not self.injector.available:
            # Fallback: use the X11 PRIMARY selection (highlighted text).
            text = self.clipboard.read_primary_text()
            if text:
                self._set_b(text)
            return

        self._busy = True
        self.injector.copy()

        def finish():
            captured = self.clipboard.read_text()
            if not captured:
                captured = self.clipboard.read_primary_text()
            if captured:
                self._set_b(captured)
            # Restore Clipboard A.
            if backup is not None:
                self.clipboard.set_text(backup)
                self._last_seen_text = backup
                self.clipboard_a_text = backup
            self._busy = False
            self._notify()
            return False

        GLib.timeout_add(_CAPTURE_DELAY_MS, finish)

    def paste_from_b(self):
        """Alt+V: paste Clipboard B into the focused application."""
        if not self.clipboard_b_text:
            return
        if not self.injector.available:
            return

        backup = self.clipboard.read_text()
        self._busy = True
        self.clipboard.set_text(self.clipboard_b_text)

        def do_paste():
            self.injector.paste()
            if self.settings.get("restore_clipboard_after_paste") and backup is not None:
                def restore():
                    self.clipboard.set_text(backup)
                    self._last_seen_text = backup
                    self.clipboard_a_text = backup
                    self._busy = False
                    self._notify()
                    return False
                GLib.timeout_add(_RESTORE_DELAY_MS, restore)
            else:
                self._last_seen_text = self.clipboard_b_text
                self.clipboard_a_text = self.clipboard_b_text
                self._busy = False
                self._notify()
            return False

        # Give the clipboard a moment to take ownership before pasting.
        GLib.timeout_add(60, do_paste)

    def set_b_manual(self, text):
        """Set Clipboard B directly (e.g. from a history row)."""
        self._set_b(text)
        self._notify()

    def _set_b(self, text):
        self.clipboard_b_text = text
        self.history.add(text, source="B")

    # -- clipboard A helpers (used by the UI) ----------------------------

    def copy_to_system(self, text):
        """Put ``text`` on the system clipboard (Clipboard A)."""
        self.clipboard.set_text(text)
        self._last_seen_text = text
        self.clipboard_a_text = text
        self.history.add(text, source="A")
        self._notify()

    def clear_b(self):
        self.clipboard_b_text = None
        self._notify()
