"""User settings and standard XDG file locations."""

import json
import os

_CONFIG_HOME = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
_DATA_HOME = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")

CONFIG_DIR = os.path.join(_CONFIG_HOME, "jacque-copy")
DATA_DIR = os.path.join(_DATA_HOME, "jacque-copy")
SETTINGS_PATH = os.path.join(CONFIG_DIR, "settings.json")
HISTORY_PATH = os.path.join(DATA_DIR, "history.json")
AUTOSTART_PATH = os.path.join(_CONFIG_HOME, "autostart", "jacque-copy.desktop")

DEFAULTS = {
    "max_history": 200,
    "monitor_system_clipboard": True,
    "restore_clipboard_after_paste": True,
    "start_minimized": False,
    "launch_at_login": False,
    "hotkey_copy_b": "<Alt>c",
    "hotkey_paste_b": "<Alt>v",
}


class Settings:
    """Small JSON-backed settings object with attribute-style access."""

    def __init__(self):
        os.makedirs(CONFIG_DIR, exist_ok=True)
        os.makedirs(DATA_DIR, exist_ok=True)
        self._values = dict(DEFAULTS)
        self.load()

    def load(self):
        try:
            with open(SETTINGS_PATH, "r", encoding="utf-8") as handle:
                stored = json.load(handle)
            if isinstance(stored, dict):
                for key, value in stored.items():
                    if key in DEFAULTS:
                        self._values[key] = value
        except (FileNotFoundError, json.JSONDecodeError, OSError):
            pass

    def save(self):
        try:
            with open(SETTINGS_PATH, "w", encoding="utf-8") as handle:
                json.dump(self._values, handle, indent=2)
        except OSError:
            pass

    def get(self, key):
        return self._values.get(key, DEFAULTS.get(key))

    def set(self, key, value):
        self._values[key] = value
        self.save()
