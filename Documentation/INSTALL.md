# Installation

Jacque-Copy runs on both **macOS** and **Windows**. Pick your platform below.

## Supported Platforms

| | macOS | Windows |
|---|---|---|
| **OS** | 14.0 (Sonoma) or later | 10 (1809) or later |
| **CPU** | Intel (x86_64) & Apple Silicon (arm64) | x64 & ARM64 |
| **Permission** | Accessibility (for the Clipboard B hotkeys) | None required |

---

## Download & Install

### macOS

1. Go to the [**latest release**](https://github.com/Johnnycarriere215/Multi-Copy/releases/latest).
2. Under **Assets**, download **`JacqueCopy-{version}.dmg`**.
3. Open the downloaded DMG.
4. Drag **Jacque-Copy** into the **Applications** folder.
5. Launch it from Applications, Spotlight, or Launchpad. It lives in your **menu bar** (look for the gold-accented clipboard icon).
6. Grant **Accessibility** permission when prompted (see below) — this is what powers the ⌃C / ⌃V shortcuts.

> First-open warning? Because this is a downloaded app, macOS may say it "cannot be opened because the developer cannot be verified." Right-click the app → **Open** → **Open**, or allow it under **System Settings → Privacy & Security**.

### Windows

1. Go to the [**latest release**](https://github.com/Johnnycarriere215/Multi-Copy/releases/latest).
2. Under **Assets**, download **`JacqueCopy-{version}-windows.zip`**.
3. Right-click the ZIP → **Extract All…** and choose any folder (e.g. your Documents or a permanent Apps folder — don't run it from inside the ZIP).
4. Open the extracted folder and run **`JacqueCopy.exe`**. It runs from the **system tray** (bottom-right, near the clock).
5. No special permissions are required.

> SmartScreen warning? Because the app isn't code-signed yet, Windows may show "Windows protected your PC." Click **More info → Run anyway**.

### Verify your download (optional)

Every release ships a `SHA256SUMS` file. To confirm your download wasn't corrupted:

```bash
# macOS
shasum -a 256 JacqueCopy-1.0.0.dmg
```
```powershell
# Windows (PowerShell)
Get-FileHash .\JacqueCopy-1.0.0-windows.zip -Algorithm SHA256
```

Compare the output against the matching line in `SHA256SUMS` on the release page.

---

## First Launch & Default Shortcuts

Your normal copy & paste (⌘C/⌘V on macOS, Ctrl+C/Ctrl+V on Windows) keeps working exactly as before — that's **Clipboard A**. Jacque-Copy adds **Clipboard B** on its own keys:

| Action | macOS | Windows |
|---|---|---|
| **Copy to Clipboard B** | **⌃C** | **Alt+C** |
| **Paste from Clipboard B** | **⌃V** | **Alt+V** |
| Clear Clipboard B | ⌃⌥X | Ctrl+Alt+X |
| Swap Clipboards A ↔ B | ⌃⌥S | Ctrl+Alt+S |

All shortcuts are remappable in **Settings → Hotkeys**.

### macOS — Accessibility permission

Jacque-Copy needs Accessibility access to detect the Clipboard B hotkeys globally.

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Toggle **Jacque-Copy** to **ON** (or click **+**, then add it from Applications).
3. Quit and reopen Jacque-Copy so the permission takes effect.

Windows needs no equivalent permission.

---

## Updating

- **macOS** — Jacque-Copy uses Sparkle for in-app updates. Click the menu bar icon → **Settings → Updates → Check for Updates**, or let it check automatically.
- **Windows** — download the newer `-windows.zip` from the [Releases page](https://github.com/Johnnycarriere215/Multi-Copy/releases/latest), extract it, and replace the old `JacqueCopy.exe`.

---

## Uninstalling

### macOS
1. Quit Jacque-Copy from the menu bar.
2. Drag it from **Applications** to the Trash.
3. Optionally remove its data:
   ```bash
   rm -rf ~/Library/Application\ Support/JacqueCopy
   rm -rf ~/Library/Preferences/com.jacquecopy.plist
   ```

### Windows
1. Right-click the tray icon → **Quit**.
2. Delete the extracted folder containing `JacqueCopy.exe`.
3. Optionally remove its data:
   ```powershell
   Remove-Item -Recurse -Force "$env:APPDATA\JacqueCopy"
   ```

---

## Build from Source

Prefer to compile it yourself? See [BUILD.md](BUILD.md).

---

## Verify It Works

1. Copy some text the normal way (⌘C / Ctrl+C) — it's on **Clipboard A**.
2. Select different text and press the **Clipboard B copy** key (⌃C / Alt+C).
3. Paste with ⌘V / Ctrl+V → you get the **first** text (Clipboard A).
4. Paste with ⌃V / Alt+V → you get the **second** text (Clipboard B).

Two independent clipboards, neither overwriting the other. That's it.
