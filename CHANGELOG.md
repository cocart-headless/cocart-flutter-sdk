# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — Unreleased

### Added

- `CoCart` client with fluent configuration API
- `CoCartOptions` with full config support (auth, HTTP, storage, debug)
- Authentication: Guest, Basic Auth, JWT (with auto-refresh), Consumer Keys
- Auth priority: JWT > Basic Auth > Consumer Keys > Guest
- Runtime auth switching with automatic credential clearing
- `CartResource` with 30+ cart operations (add, update, remove, coupons, shipping, fees, cross-sells)
- `ProductsResource` with browse, filter, categories, brands, attributes, reviews
- `SessionsResource` for admin session management
- `JwtResource` with login, logout, refresh, validate, token expiry, auto-refresh
- `CoCartResponse` with dot-notation `.get()` access and convenience helpers
- Client-side input validation (`validateProductId`, `validateQuantity`, `validateEmail`)
- `CurrencyFormatter` for formatting smallest-unit integers into currency strings
- ETag / conditional request support with automatic caching
- Event system (`request`, `response`, `error`)
- Response transformer support
- `SecureStorage` (default) using `flutter_secure_storage`
- `MemoryStorage` for testing and server-side Dart
- Custom `CoCartStorage` interface for pluggable storage
- Guest session persistence and `restoreSession()`
- Legacy CoCart plugin mode with `VersionError` guard
- Custom auth header name for proxy support
- Debug logging mode
- Retry logic with configurable max retries
- Error hierarchy: `CoCartException`, `AuthException`, `NetworkException`, `RateLimitException`, `VersionError`, `ValidationError`
- Comprehensive unit tests
- Example app
- Full documentation
