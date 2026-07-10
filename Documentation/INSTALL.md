# Installation

## Supported Platforms

- macOS 14.0 (Sonoma) or later
- Intel (x86_64) and Apple Silicon (arm64)

## Installation Methods

### Method 1: GitHub Releases (Recommended)

1. Visit the [Releases page](https://github.com/Johnnycarriere215/Multi-Copy/releases/latest)
2. Download `JacqueCopy-{version}.dmg`
3. Open the DMG file
4. Drag **Jacque-Copy** to the **Applications** folder
5. Launch Jacque-Copy from Applications, Spotlight, or Launchpad

### Method 2: Build from Source

See [BUILD.md](BUILD.md) for detailed instructions.

## First Launch

1. On first launch, Jacque-Copy will appear in your menu bar (look for the clipboard icon with a gold accent)
2. Grant **Accessibility** permissions when prompted -- this is required for the secondary clipboard shortcuts
3. The default shortcuts are:
   - **⌃C**: Copy to Clipboard B
   - **⌃V**: Paste from Clipboard B

## Accessibility Permissions

Jacque-Copy requires Accessibility permissions to intercept keyboard events globally. This allows interception of Ctrl+C and Ctrl+V to power the secondary clipboard.

To grant permissions:
1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Toggle Jacque-Copy to **ON**
3. You may need to quit and reopen Jacque-Copy

If you see the prompt but didn't get a chance to enable it:
1. Go to System Settings → Privacy & Security → Accessibility
2. Click the **+** button
3. Navigate to Applications and select Jacque-Copy

## Updating

Jacque-Copy uses Sparkle for automatic updates. By default, it checks for updates periodically and notifies you when a new version is available.

To manually check for updates:
1. Click the Jacque-Copy menu bar icon
2. Go to Settings → Updates
3. Click "Check for Updates"

## Uninstalling

1. Quit Jacque-Copy from the menu bar
2. Drag Jacque-Copy from Applications to the Trash
3. Optionally remove data:
   ```bash
   rm -rf ~/Library/Application\ Support/JacqueCopy
   rm -rf ~/Library/Preferences/com.jacquecopy.plist
   ```

## Verification

After installation, verify everything is working:

1. Copy some text with ⌘C → You should see it in the menu bar preview
2. Select some text and press ⌃C → The menu bar should show content in Clipboard B
3. Press ⌘V → It should paste Clipboard A's content
4. Press ⌃V → It should paste Clipboard B's content
