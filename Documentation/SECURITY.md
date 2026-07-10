# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅ Yes    |

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Please report security issues privately to the maintainers.

We aim to respond within 48 hours and publish fixes as quickly as possible.

## Security Principles

### Local-First

Jacque-Copy stores all clipboard data locally. No clipboard content is ever transmitted over the network. The app does not include analytics, telemetry, or any backend service.

### Sensitive Data Exclusion

The app automatically excludes known sensitive pasteboard types:
- `org.nspasteboard.TransientType` (temporary data)
- `org.nspasteboard.ConcealedType` (sensitive data)
- `com.agilebits.onepassword` (password manager data)
- `com.1password`
- Custom auto-generated types

### File Permissions

All application data is stored in `~/Library/Application Support/JacqueCopy/` with standard macOS file permissions. History files are stored as JSON files readable only by the current user.

### Accessibility Permissions

The app requires Accessibility permissions for global hotkey interception. These permissions are requested explicitly and the user must grant them manually in System Settings. The permission can be revoked at any time.

### No Embedded Web Content

The application does not render web content or execute JavaScript. All UI is native SwiftUI/AppKit.

## Security Recommendations for Users

1. **Keep macOS updated** — Security updates protect the Accessibility API
2. **Review Accessibility permissions** — Periodically check which apps have Accessibility access
3. **Use FileVault** — Encrypts your disk, protecting stored clipboard history
4. **Lock your screen** — Prevents physical access to clipboard data
5. **Consider disabling history** — If you copy sensitive data frequently, reduce history size or disable it
