"""The main Jacque-Copy window: dual-clipboard header, search, and history."""

import time

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib, Pango  # noqa: E402

_CSS = b"""
.jc-card {
    background: @theme_base_color;
    border: 1px solid alpha(@theme_fg_color, 0.12);
    border-radius: 12px;
    padding: 12px;
}
.jc-card-a { border-left: 4px solid #6C5CE7; }
.jc-card-b { border-left: 4px solid #E0A317; }
.jc-card-title { font-weight: 700; font-size: 11px; opacity: 0.65; }
.jc-card-hint { font-size: 10px; opacity: 0.5; }
.jc-card-content { font-size: 13px; }
.jc-badge {
    font-weight: 800;
    font-size: 11px;
    color: #ffffff;
    border-radius: 8px;
    padding: 2px 9px;
    margin-right: 6px;
}
.jc-badge-a { background: #6C5CE7; }
.jc-badge-b { background: #E0A317; }
.jc-time { font-size: 10px; opacity: 0.5; }
.jc-empty { font-size: 14px; opacity: 0.5; }
.jc-status { font-size: 11px; opacity: 0.7; padding: 4px 8px; }
row:hover .jc-actions { opacity: 1; }
.jc-actions { opacity: 0.25; }
"""


def _install_css():
    provider = Gtk.CssProvider()
    provider.load_from_data(_CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
    )


def _accel_label(accel):
    """Turn a GTK accelerator string (e.g. ``<Ctrl><Shift>c``) into ``Ctrl+Shift+C``."""
    key, mods = Gtk.accelerator_parse(accel)
    if key == 0:
        return accel
    return Gtk.accelerator_get_label(key, mods)


def _relative_time(ts):
    delta = max(0, int(time.time() - ts))
    if delta < 60:
        return "just now"
    if delta < 3600:
        return f"{delta // 60}m ago"
    if delta < 86400:
        return f"{delta // 3600}h ago"
    return f"{delta // 86400}d ago"


class MainWindow(Gtk.ApplicationWindow):
    def __init__(self, application, engine):
        super().__init__(application=application, title="Jacque-Copy")
        self.engine = engine
        copy_label = _accel_label(engine.settings.get("hotkey_copy_b"))
        paste_label = _accel_label(engine.settings.get("hotkey_paste_b"))
        self._b_hint = f"{copy_label} / {paste_label}"
        self._status_default = (
            f"{copy_label} copies the selection to Clipboard B  ·  {paste_label} pastes it"
        )
        self.set_default_size(460, 620)
        self.set_icon_name("jacque-copy")
        _install_css()

        header = Gtk.HeaderBar(title="Jacque-Copy", subtitle="Dual clipboard", show_close_button=True)
        self.set_titlebar(header)

        clear_btn = Gtk.Button.new_from_icon_name("edit-clear-all-symbolic", Gtk.IconSize.BUTTON)
        clear_btn.set_tooltip_text("Clear history")
        clear_btn.connect("clicked", self._on_clear_history)
        header.pack_end(clear_btn)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        outer.set_border_width(12)
        self.add(outer)

        outer.pack_start(self._build_clipboard_cards(), False, False, 0)

        self.search = Gtk.SearchEntry()
        self.search.set_placeholder_text("Search clipboard history…")
        self.search.connect("search-changed", lambda *_: self.refresh())
        outer.pack_start(self.search, False, False, 0)

        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.listbox = Gtk.ListBox()
        self.listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        self.listbox.connect("row-activated", self._on_row_activated)
        scroller.add(self.listbox)
        outer.pack_start(scroller, True, True, 0)

        self.status = Gtk.Label(xalign=0)
        self.status.get_style_context().add_class("jc-status")
        self.status.set_text(self._status_default)
        outer.pack_start(self.status, False, False, 0)

        self.connect("key-press-event", self._on_key_press)
        self.engine.add_listener(self.refresh)
        self.refresh()
        self.show_all()

    # -- header cards ----------------------------------------------------

    def _build_clipboard_cards(self):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10, homogeneous=True)
        self.card_a_content = Gtk.Label(xalign=0, label="(empty)")
        self.card_b_content = Gtk.Label(xalign=0, label="(empty)")
        row.pack_start(self._card("Clipboard A · system", "Ctrl+C / Ctrl+V", self.card_a_content, "jc-card-a"), True, True, 0)
        row.pack_start(self._card("Clipboard B · secondary", self._b_hint, self.card_b_content, "jc-card-b"), True, True, 0)
        return row

    def _card(self, title, hint, content_label, style):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        box.get_style_context().add_class("jc-card")
        box.get_style_context().add_class(style)
        title_lbl = Gtk.Label(xalign=0, label=title)
        title_lbl.get_style_context().add_class("jc-card-title")
        hint_lbl = Gtk.Label(xalign=0, label=hint)
        hint_lbl.get_style_context().add_class("jc-card-hint")
        content_label.get_style_context().add_class("jc-card-content")
        content_label.set_ellipsize(Pango.EllipsizeMode.END)
        content_label.set_lines(2)
        content_label.set_line_wrap(True)
        content_label.set_max_width_chars(24)
        box.pack_start(title_lbl, False, False, 0)
        box.pack_start(content_label, False, False, 2)
        box.pack_start(hint_lbl, False, False, 0)
        return box

    # -- history list ----------------------------------------------------

    def refresh(self):
        self.card_a_content.set_text(self._short(self.engine.clipboard_a_text))
        self.card_b_content.set_text(self._short(self.engine.clipboard_b_text))

        for child in self.listbox.get_children():
            self.listbox.remove(child)

        query = self.search.get_text()
        items = self.engine.history.search(query)
        if not items:
            placeholder = Gtk.Label(label="Nothing here yet" if not query else "No matches")
            placeholder.get_style_context().add_class("jc-empty")
            placeholder.set_margin_top(40)
            self.listbox.add(placeholder)
        else:
            for item in items:
                self.listbox.add(self._build_row(item))
        self.listbox.show_all()
        return False

    def _build_row(self, item):
        row = Gtk.ListBoxRow()
        row.item = item
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        hbox.set_border_width(6)

        badge = Gtk.Label(label=item.source)
        badge.get_style_context().add_class("jc-badge")
        badge.get_style_context().add_class("jc-badge-a" if item.source == "A" else "jc-badge-b")
        badge.set_valign(Gtk.Align.START)
        hbox.pack_start(badge, False, False, 0)

        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
        preview = Gtk.Label(xalign=0, label=item.preview)
        preview.set_ellipsize(Pango.EllipsizeMode.END)
        preview.set_max_width_chars(40)
        when = Gtk.Label(xalign=0, label=_relative_time(item.timestamp))
        when.get_style_context().add_class("jc-time")
        text_box.pack_start(preview, False, False, 0)
        text_box.pack_start(when, False, False, 0)
        hbox.pack_start(text_box, True, True, 0)

        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=2)
        actions.get_style_context().add_class("jc-actions")
        actions.set_valign(Gtk.Align.CENTER)
        pin_icon = "starred-symbolic" if item.pinned else "non-starred-symbolic"
        actions.pack_start(self._icon_button(pin_icon, "Pin", lambda *_: self._pin(item)), False, False, 0)
        actions.pack_start(self._icon_button("go-jump-symbolic", "Send to Clipboard B", lambda *_: self._to_b(item)), False, False, 0)
        actions.pack_start(self._icon_button("user-trash-symbolic", "Delete", lambda *_: self._delete(item)), False, False, 0)
        hbox.pack_start(actions, False, False, 0)

        row.add(hbox)
        return row

    def _icon_button(self, icon_name, tooltip, callback):
        btn = Gtk.Button.new_from_icon_name(icon_name, Gtk.IconSize.MENU)
        btn.set_relief(Gtk.ReliefStyle.NONE)
        btn.set_tooltip_text(tooltip)
        btn.connect("clicked", callback)
        return btn

    # -- actions ---------------------------------------------------------

    def _on_row_activated(self, _listbox, row):
        if hasattr(row, "item"):
            self.engine.copy_to_system(row.item.text)
            self._flash("Copied to system clipboard (A)")

    def _to_b(self, item):
        self.engine.set_b_manual(item.text)
        self._flash("Sent to Clipboard B")

    def _pin(self, item):
        self.engine.history.toggle_pinned(item.id)
        self.refresh()

    def _delete(self, item):
        self.engine.history.remove(item.id)
        self.refresh()

    def _on_clear_history(self, _btn):
        dialog = Gtk.MessageDialog(
            transient_for=self, modal=True, message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.OK_CANCEL, text="Clear clipboard history?",
        )
        dialog.format_secondary_text("Pinned items are kept.")
        if dialog.run() == Gtk.ResponseType.OK:
            self.engine.history.clear()
            self.refresh()
        dialog.destroy()

    def _flash(self, message):
        self.status.set_text(message)
        GLib.timeout_add_seconds(
            3, lambda: (self.status.set_text(self._status_default), False)[1]
        )

    def _on_key_press(self, _widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.hide()
            return True
        return False

    @staticmethod
    def _short(text):
        if not text:
            return "(empty)"
        return " ".join(text.split())[:80]
