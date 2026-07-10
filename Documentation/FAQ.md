# Frequently Asked Questions

## General

### What is Jacque-Copy?

Jacque-Copy is a macOS menu bar application that adds a second, completely independent clipboard to your Mac. Unlike clipboard history managers, it provides a true dual clipboard system where Clipboard A (system) and Clipboard B (secondary) never interfere with each other.

### How is this different from clipboard history?

Clipboard history apps capture a timeline of everything you copy. Jacque-Copy gives you two separate clipboards that work simultaneously. You can have "Apple" on Clipboard A and "Orange" on Clipboard B, and paste either one anytime without affecting the other.

### Is it free?

Yes! Jacque-Copy is free and open-source under the MIT License.

## Functionality

### Why does it need Accessibility permissions?

Jacque-Copy uses Accessibility permissions to intercept the Ctrl+C and Ctrl+V keyboard shortcuts globally. This is how it detects when you want to copy to or paste from Clipboard B. Without these permissions, the secondary clipboard cannot function.

### Can I change the shortcuts?

Yes! Go to Settings > Hotkeys to customize all shortcuts. The defaults are:
- Copy to B: ⌃C
- Paste from B: ⌃V

### Does it work with Universal Clipboard (Handoff)?

Jacque-Copy reads from the standard system pasteboard, so it works alongside Universal Clipboard for Clipboard A. Clipboard B content is stored locally only.

### Will it slow down my Mac?

No. Jacque-Copy is designed for near-zero CPU usage when idle and a memory footprint under 20 MB. It uses an event-driven architecture with no busy loops or excessive polling.

### What happens to Clipboard A when I use Clipboard B?

Clipboard A is never modified by Clipboard B operations. When you paste from Clipboard B, Jacque-Copy temporarily swaps the system pasteboard, triggers the paste, and immediately restores Clipboard A. This happens in milliseconds.

## Technical

### Where is my data stored?

All clipboard history is stored locally in:
```
~/Library/Application Support/JacqueCopy/History/
```

Settings are stored in `UserDefaults` (`~/Library/Preferences/com.jacquecopy.plist`).

### Is any data sent to the internet?

No. Jacque-Copy does not transmit any clipboard data over the network. The only network requests are for Sparkle update checks (if enabled).

### How much storage does history use?

By default, history is limited to 100 items per clipboard with a 50 MB total storage limit. These limits are configurable in Settings > Clipboard.

### Can I sync between Macs?

Currently, clipboard sync between Macs is not supported. Clipboard A works with Universal Clipboard, but Clipboard B is local only.

## Troubleshooting

### Hotkeys aren't working

1. Ensure Jacque-Copy is running (check the menu bar icon)
2. Verify Accessibility permissions in System Settings > Privacy & Security > Accessibility
3. Try restarting Jacque-Copy
4. Check if another app is capturing the same shortcuts

### The app won't start

Check Console.app for Jacque-Copy log messages. You can also enable diagnostic logging in Settings > Advanced.

### I found a bug

Please [open an issue](https://github.com/Johnnycarriere215/Multi-Copy/issues/new?template=bug_report.md) with details about what happened and your macOS version.
