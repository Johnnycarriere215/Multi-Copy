"""Jacque-Copy application: window, tray icon, global hotkeys, lifecycle."""

import os

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gio, GLib  # noqa: E402

# Ayatana is the modern AppIndicator on Mint/Ubuntu; fall back to the classic.
try:
    gi.require_version("AyatanaAppIndicator3", "0.1")
    from gi.repository import AyatanaAppIndicator3 as AppIndicator
except (ValueError, ImportError):  # pragma: no cover
    gi.require_version("AppIndicator3", "0.1")
    from gi.repository import AppIndicator3 as AppIndicator

from . import APP_ID, APP_NAME
from .engine import ClipboardEngine
from .hotkeys import HotkeyManager
from .settings import Settings
from .ui.window import MainWindow


def _icon_dir():
    """Locate the icons directory whether installed or run from source."""
    candidates = [
        "/usr/share/icons/hicolor/scalable/apps",
        os.path.join(os.path.dirname(__file__), "..", "data", "icons"),
    ]
    for path in candidates:
        if os.path.exists(os.path.join(path, "jacque-copy.svg")) or \
           os.path.exists(os.path.join(path, "jacque-copy.png")):
            return os.path.abspath(path)
    return os.path.abspath(candidates[-1])


class JacqueCopyApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.window = None
        self.settings = None
        self.engine = None
        self.hotkeys = None
        self.indicator = None
        self._b_menu_item = None

    # -- lifecycle -------------------------------------------------------

    def do_startup(self):
        Gtk.Application.do_startup(self)

        icon_theme = Gtk.IconTheme.get_default()
        icon_theme.append_search_path(_icon_dir())

        self.settings = Settings()
        self.engine = ClipboardEngine(self.settings)
        self.engine.start_monitoring()
        self.engine.add_listener(self._update_tray)

        self.hotkeys = HotkeyManager(
            self.settings,
            on_copy=self.engine.copy_selection_to_b,
            on_paste=self.engine.paste_from_b,
        )
        if not self.hotkeys.start():
            GLib.idle_add(self._warn_hotkeys)

        self._build_indicator()

        # Keep running in the background even when the window is closed.
        self.hold()

    def do_activate(self):
        if not self.window:
            self.window = MainWindow(self, self.engine)
            self.window.connect("delete-event", self._on_window_close)
        if self.settings.get("start_minimized"):
            self.window.hide()
        else:
            self.window.present()

    # -- tray indicator --------------------------------------------------

    def _build_indicator(self):
        self.indicator = AppIndicator.Indicator.new_with_path(
            APP_ID, "jacque-copy",
            AppIndicator.IndicatorCategory.APPLICATION_STATUS,
            _icon_dir(),
        )
        self.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE)
        self.indicator.set_title(APP_NAME)

        menu = Gtk.Menu()

        show_item = Gtk.MenuItem(label="Show Jacque-Copy")
        show_item.connect("activate", lambda *_: self._show_window())
        menu.append(show_item)

        menu.append(Gtk.SeparatorMenuItem())

        self._b_menu_item = Gtk.MenuItem(label="Clipboard B: (empty)")
        self._b_menu_item.set_sensitive(False)
        menu.append(self._b_menu_item)

        clear_b = Gtk.MenuItem(label="Clear Clipboard B")
        clear_b.connect("activate", lambda *_: self.engine.clear_b())
        menu.append(clear_b)

        menu.append(Gtk.SeparatorMenuItem())

        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", lambda *_: self.quit_app())
        menu.append(quit_item)

        menu.show_all()
        self.indicator.set_menu(menu)
        self.indicator.set_secondary_activate_target(show_item)

    def _update_tray(self):
        if self._b_menu_item:
            text = self.engine.clipboard_b_text
            preview = " ".join(text.split())[:40] if text else "(empty)"
            self._b_menu_item.set_label(f"Clipboard B: {preview}")
        return False

    # -- window handling -------------------------------------------------

    def _show_window(self):
        if not self.window:
            self.do_activate()
        self.window.present()

    def _on_window_close(self, window, _event):
        # Hide to tray instead of quitting.
        window.hide()
        return True

    def _warn_hotkeys(self):
        if self.window:
            self.window.status.set_text(
                "⚠ Could not register Alt+C / Alt+V — another app may have grabbed them"
            )
        return False

    def quit_app(self):
        if self.hotkeys:
            self.hotkeys.stop()
        self.release()
        self.quit()


def main():
    app = JacqueCopyApp()
    return app.run(None)


if __name__ == "__main__":
    raise SystemExit(main())
