"""Global X11 hotkeys via Keybinder (GNOME/X11 grab helper)."""

import gi

gi.require_version("Keybinder", "3.0")
from gi.repository import Keybinder  # noqa: E402


class HotkeyManager:
    def __init__(self, settings, on_copy, on_paste):
        self.settings = settings
        self._on_copy = on_copy
        self._on_paste = on_paste
        self._bound = []
        Keybinder.init()

    def start(self):
        """Bind the configured accelerators. Returns True if both succeeded."""
        copy_key = self.settings.get("hotkey_copy_b")
        paste_key = self.settings.get("hotkey_paste_b")
        ok_copy = self._bind(copy_key, lambda *_: self._on_copy())
        ok_paste = self._bind(paste_key, lambda *_: self._on_paste())
        return ok_copy and ok_paste

    def _bind(self, keystring, handler):
        if not keystring:
            return False
        if Keybinder.bind(keystring, handler):
            self._bound.append(keystring)
            return True
        return False

    def stop(self):
        for keystring in self._bound:
            try:
                Keybinder.unbind(keystring)
            except Exception:
                pass
        self._bound = []

    def rebind(self):
        self.stop()
        return self.start()
