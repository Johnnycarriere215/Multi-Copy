"""Clipboard item model and JSON-backed history persistence."""

import json
import os
import time
import uuid

from . import settings


class ClipboardItem:
    """A single captured clipboard entry.

    ``source`` is ``"A"`` for the system clipboard or ``"B"`` for the
    secondary clipboard.
    """

    def __init__(self, text, source="A", item_id=None, timestamp=None, pinned=False):
        self.id = item_id or uuid.uuid4().hex
        self.text = text
        self.source = source
        self.timestamp = timestamp if timestamp is not None else time.time()
        self.pinned = pinned

    @property
    def preview(self):
        """A single-line, trimmed preview suitable for list rows."""
        collapsed = " ".join(self.text.split())
        return collapsed[:120] if collapsed else "(empty)"

    def to_dict(self):
        return {
            "id": self.id,
            "text": self.text,
            "source": self.source,
            "timestamp": self.timestamp,
            "pinned": self.pinned,
        }

    @classmethod
    def from_dict(cls, data):
        return cls(
            text=data.get("text", ""),
            source=data.get("source", "A"),
            item_id=data.get("id"),
            timestamp=data.get("timestamp"),
            pinned=data.get("pinned", False),
        )


class HistoryStore:
    """Ordered, de-duplicated, capped clipboard history persisted as JSON."""

    def __init__(self, max_items=200):
        self.max_items = max_items
        self.items = []  # newest first
        self.load()

    def load(self):
        try:
            with open(settings.HISTORY_PATH, "r", encoding="utf-8") as handle:
                raw = json.load(handle)
            self.items = [ClipboardItem.from_dict(entry) for entry in raw]
        except (FileNotFoundError, json.JSONDecodeError, OSError):
            self.items = []

    def save(self):
        try:
            with open(settings.HISTORY_PATH, "w", encoding="utf-8") as handle:
                json.dump([item.to_dict() for item in self.items], handle, indent=2)
        except OSError:
            pass

    def add(self, text, source="A"):
        """Add ``text`` to the front, collapsing an identical recent entry."""
        if not text:
            return None
        # Remove an existing identical, non-pinned entry so it moves to the top.
        self.items = [
            item for item in self.items
            if not (item.text == text and item.source == source and not item.pinned)
        ]
        item = ClipboardItem(text=text, source=source)
        self.items.insert(0, item)
        self._trim()
        self.save()
        return item

    def _trim(self):
        pinned = [i for i in self.items if i.pinned]
        unpinned = [i for i in self.items if not i.pinned]
        keep = max(0, self.max_items - len(pinned))
        self.items = pinned + unpinned[:keep]
        # Preserve newest-first ordering overall.
        self.items.sort(key=lambda i: i.timestamp, reverse=True)

    def remove(self, item_id):
        self.items = [i for i in self.items if i.id != item_id]
        self.save()

    def toggle_pinned(self, item_id):
        for item in self.items:
            if item.id == item_id:
                item.pinned = not item.pinned
        self.save()

    def clear(self, source=None):
        if source is None:
            self.items = [i for i in self.items if i.pinned]
        else:
            self.items = [i for i in self.items if i.source != source or i.pinned]
        self.save()

    def search(self, query):
        query = query.strip().lower()
        if not query:
            return list(self.items)
        return [i for i in self.items if query in i.text.lower()]
