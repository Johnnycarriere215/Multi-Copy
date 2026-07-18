# Jacque-Copy for Linux

A dual-clipboard manager for Linux desktops (X11).

- **Clipboard A** — your normal system clipboard (`Ctrl+C` / `Ctrl+V`).
- **Clipboard B** — an independent second clipboard driven by **`Alt+C`** (copy the
  current selection into B) and **`Alt+V`** (paste B into the focused app).

It also gives you a searchable **history browser** and a **tray icon**.

## Install

Download `jacque-copy_<version>_all.deb` from the
[Releases page](https://github.com/Johnnycarriere215/Multi-Copy/releases) and install it:

```bash
sudo apt install ./jacque-copy_1.0.0_all.deb
```

`apt` pulls in the dependencies automatically. Then launch **Jacque-Copy** from your
application menu, or run `jacque-copy` from a terminal.

### Dependencies

Installed automatically by `apt`:
`python3`, `python3-gi`, `gir1.2-gtk-3.0`, `gir1.2-keybinder-3.0`,
`gir1.2-ayatanaappindicator3-0.1`, `python3-xlib`.

## Usage

1. Select some text in any application.
2. Press **`Alt+C`** — it is captured into Clipboard B (your normal clipboard is left
   untouched).
3. Click where you want it and press **`Alt+V`** — Clipboard B is pasted.

The window shows both clipboards and a history of everything copied. Click a history row
to copy it back to the system clipboard, or use the row buttons to pin, send to
Clipboard B, or delete.

Closing the window keeps Jacque-Copy running in the tray. Quit from the tray menu.

## Notes

- **X11 only.** Global hotkeys rely on the X11 grab mechanism (Keybinder). On Wayland,
  global hotkeys are not available; run an X11 session for full functionality.
- Settings and history live under `~/.config/jacque-copy/` and
  `~/.local/share/jacque-copy/`.

## Build from source

```bash
cd linux
bash packaging/build-deb.sh          # → dist/jacque-copy_<version>_all.deb
```

Run without installing:

```bash
cd linux
python3 -m jacquecopy
```
