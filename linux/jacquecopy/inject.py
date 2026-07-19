"""Synthetic keyboard input via the X11 XTEST extension.

Used to trigger a real Ctrl+C in the focused application (to capture its
current selection into Clipboard B) and a real Ctrl+V (to paste Clipboard B).
"""

from Xlib import X, XK, display
from Xlib.ext import xtest


class KeyInjector:
    def __init__(self):
        self._display = None
        try:
            self._display = display.Display()
        except Exception:
            # No X11 display (e.g. Wayland or headless) — injection unavailable.
            self._display = None

    @property
    def available(self):
        return self._display is not None

    def _keycode(self, keysym_name):
        keysym = XK.string_to_keysym(keysym_name)
        return self._display.keysym_to_keycode(keysym)

    def _clear_modifiers(self):
        """Release every modifier that may be physically held by the hotkey.

        The trigger shortcut (e.g. Ctrl+Shift+C) still has its modifiers down
        when we inject, so a following "Ctrl+C" would be seen as "Ctrl+Shift+C".
        We synthesise releases for all common modifiers first so the injected
        combo is clean.
        """
        for name in (
            "Shift_L", "Shift_R", "Control_L", "Control_R",
            "Alt_L", "Alt_R", "Super_L", "Super_R", "Meta_L", "Meta_R",
        ):
            code = self._keycode(name)
            if code:
                xtest.fake_input(self._display, X.KeyRelease, code)
        self._display.sync()

    def send_ctrl(self, letter):
        """Send a clean Ctrl+<letter> (e.g. ``"c"`` or ``"v"``) to the focused window."""
        if not self._display:
            return False
        try:
            self._clear_modifiers()
            ctrl = self._keycode("Control_L")
            key = self._keycode(letter)
            xtest.fake_input(self._display, X.KeyPress, ctrl)
            xtest.fake_input(self._display, X.KeyPress, key)
            xtest.fake_input(self._display, X.KeyRelease, key)
            xtest.fake_input(self._display, X.KeyRelease, ctrl)
            self._display.sync()
            return True
        except Exception:
            return False

    def copy(self):
        return self.send_ctrl("c")

    def paste(self):
        return self.send_ctrl("v")
