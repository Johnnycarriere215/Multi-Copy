# Build Instructions

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- [SwiftLint](https://github.com/realm/SwiftLint) (optional, for linting)

## Quick Start

### Using Xcode

1. Clone the repository:
   ```bash
   git clone https://github.com/Johnnycarriere215/Multi-Copy.git
   cd jacque-copy
   ```

2. Open the project in Xcode:
   ```bash
   open JacqueCopy.xcodeproj
   ```
   
   Or with Swift Package Manager:
   ```bash
   xed .
   ```

3. Select the **JacqueCopy** scheme and your development team in the Signing & Capabilities tab.

4. Build and run:
   - Press **⌘R** to build and run
   - Press **⌘B** to build only

### Using Command Line

```bash
# Build
swift build -c release

# Run
swift run -c release

# Test
swift test

# Build for release with archiving
xcodebuild -project JacqueCopy.xcodeproj \
  -scheme JacqueCopy \
  -configuration Release \
  -archivePath build/JacqueCopy.xcarchive \
  archive
```

## Signing & Notarization

### Development Signing

For local development, Xcode will automatically manage signing. Ensure you're signed into Xcode with your Apple ID.

### Release Signing

For distribution, you'll need:

1. An Apple Developer account
2. A "Developer ID Application" certificate
3. Appropriate provisioning profiles

Set the following in Xcode:
- Signing Certificate: `Developer ID Application`
- Team: Your development team

### Notarization

```bash
# Create archive
xcodebuild -project JacqueCopy.xcodeproj \
  -scheme JacqueCopy \
  -configuration Release \
  -archivePath build/JacqueCopy.xcarchive \
  archive

# Export app
xcodebuild -exportArchive \
  -archivePath build/JacqueCopy.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist Scripts/exportOptions.plist

# Notarize
xcrun notarytool submit build/export/JacqueCopy.app \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "@keychain:AC_PASSWORD" \
  --wait

# Staple
xcrun stapler staple build/export/JacqueCopy.app
```

## Package for Distribution

### Create DMG

```bash
./Scripts/create-dmg.sh
```

This generates `JacqueCopy-{version}.dmg` in the `build/` directory.

### Create ZIP

```bash
./Scripts/create-zip.sh
```

This generates `JacqueCopy-{version}.zip` in the `build/` directory.

### Generate Release Assets

```bash
./Scripts/release.sh 1.0.0
```

This creates all release assets: DMG, ZIP, checksums, and release notes.

## Dependencies

Dependencies are managed via Swift Package Manager:

| Package | Version | Purpose |
|---------|---------|---------|
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | 2.0+ | Global hotkey management |
| [Sparkle](https://github.com/sparkle-project/Sparkle) | 2.6+ | Automatic updates |

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `JACQUECOPY_ENV` | Build environment (`development`/`production`) | `development` |

### Build Settings

| Setting | Description |
|---------|-------------|
| `SWIFT_ACTIVE_COMPILATION_CONDITIONS` | Adds `DEBUG` conditional for development |
| `MACOSX_DEPLOYMENT_TARGET` | Minimum deployment target: 14.0 |
| `ENABLE_HARDENED_RUNTIME` | Enabled for notarization compatibility |

## Troubleshooting

### Build fails with "No such module"

Ensure dependencies are resolved:
```bash
swift package resolve
```

### Accessibility permissions not working

If hotkeys aren't working, ensure Jacque-Copy is enabled in:
System Settings → Privacy & Security → Accessibility

### Sparkle updates not working

Set up the `SUFeedURL` in `Info.plist` to point to your appcast URL. For local testing, use a local XML feed.
