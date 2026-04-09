# Support & Versioning Policy

> **Note:** This SDK is currently in development.

## Versioning

This project follows [Semantic Versioning](https://semver.org/) (SemVer):

- **Major** (X.0.0) — Breaking changes
- **Minor** (x.Y.0) — New features (backward-compatible)
- **Patch** (x.y.Z) — Bug fixes and security patches

Only the latest major version receives active development.

### What constitutes a breaking change

- Removing or renaming public exports
- Changing required parameters
- Changing return types
- Removing public methods or classes
- Dropping Dart/Flutter SDK versions

### What is NOT a breaking change

- Adding optional parameters
- Adding new exports, types, or fields
- Internal refactors that don't affect the public API
- Adding Dart/Flutter SDK versions
- Bug fixes that match documented behavior

## SDK Lifecycle

| Phase | Description | Duration |
|---|---|---|
| **Active** | New features, bug fixes, security patches | Current major version |
| **Maintenance** | Security patches and critical fixes only | Previous major, 12 months |
| **Deprecated** | No updates; remains installable on pub.dev | After maintenance ends |

## Supported Flutter/Dart Versions

| Version | Status | SDK Support | Notes |
|---|---|---|---|
| Flutter 3.27.x | Latest stable | Supported | Tested in CI |
| Flutter 3.19.x | Previous stable | Supported | Tested in CI |
| Flutter < 3.10 | Older | Not supported | |
| Dart >= 3.0.0 | Required | Minimum version | |

## Deprecation Notices

Deprecations are communicated through:

1. Dart `@Deprecated` annotations
2. Changelog entries
3. At least one minor release before removal
4. Migration guides in `docs/`

## Getting Help

- **Documentation** — [https://cocartapi.com/docs](https://cocartapi.com/docs)
- **Community** — [https://cocartapi.com/community](https://cocartapi.com/community)
- **Issues** — [GitHub Issues](https://github.com/cocart-headless/cocart-flutter-sdk/issues)
