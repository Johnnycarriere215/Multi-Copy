# Contributing

Thank you for your interest in contributing to Jacque-Copy! This document provides guidelines for contributing.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/jacque-copy.git`
3. Create a branch: `git checkout -b feature/my-feature`
4. Make your changes
5. Build and test: see [BUILD.md](Documentation/BUILD.md)

## Development Environment

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Coding Standards

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftUI for UI, AppKit only where required
- Follow MVVM architecture
- Use dependency injection
- Document public APIs with documentation comments
- No force unwrapping (`!`) without guard
- No `TODO` comments in production code

### Style

- 4-space indentation
- 120 character line limit
- Sorted imports
- `MARK` comments for organization

## Testing

- Unit tests for all business logic
- Integration tests for pasteboard operations
- Performance tests for critical paths

Run tests:
```bash
swift test
```

## Pull Request Process

1. Update documentation if needed
2. Add tests for new functionality
3. Ensure CI passes
4. Request review from maintainers
5. Squash commits before merging

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add clipboard swap feature
fix: resolve pasteboard timing issue
docs: update build instructions
test: add history store unit tests
refactor: extract pasteboard manager
```

## Release Process

Releases are managed by maintainers. Version numbers follow [Semantic Versioning](https://semver.org/).

## Questions?

Open a [Discussion](https://github.com/jacquecopy/jacque-copy/discussions) or join us on the issue tracker.
