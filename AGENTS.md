# CoCart Flutter SDK

Official Flutter/Dart SDK for the CoCart REST API.

- **Package:** `cocart`
- **Version:** 1.0.0
- **Distribution:** pub.dev
- **Requires:** Dart 3.0+, Flutter 3.10+
- **License:** MIT

---

## Commands

```bash
flutter pub get                                          # install dependencies
flutter test                                             # run all tests
flutter test test/resources/cart_resource_test.dart     # run a single test file
flutter test -k "addItem validates product ID"           # run tests matching a name
dart analyze --fatal-infos                              # lint / static analysis
dart format .                                           # format all files
```

---

## Tech Stack

| | |
|---|---|
| Language | Dart 3.0+ |
| Runtime | Flutter 3.10+ |
| Tests | flutter_test (built-in) |
| Mocking | mocktail 1.0+ |
| HTTP | `http` 1.2+ |
| Storage | `flutter_secure_storage` 9.0+ |
| Lint rules | `package:lints/recommended.yaml` (`analysis_options.yaml`) |
| Build | Flutter pub |

---

## Project Structure

```
lib/
  cocart.dart              # barrel export (public API)
  src/
    cocart_client.dart     # main CoCart client class
    cocart_options.dart    # CoCartOptions
    auth/
      auth_manager.dart    # auth priority, cart key capture, session restore
    http/
      http_client.dart     # http wrapper, retries, ETag, events
      response.dart        # CoCartResponse wrapper
    resources/
      cart_resource.dart
      products_resource.dart
      sessions_resource.dart
      jwt_resource.dart
    storage/
      storage_interface.dart
      secure_storage.dart  # default (flutter_secure_storage)
      memory_storage.dart  # for tests
    errors/                # CoCartException subclasses
    utilities/
      currency_formatter.dart
    validation/
      validators.dart
test/
  auth/
  http/
  resources/
  validation/
  mocks/
    mock_http_client.dart
```

---

## Code Style

- **File names:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Methods, variables:** `camelCase`
- **`final`** for fields that don't change after construction
- **`??`** null coalescing, **`?.`** null-safe access throughout
- All async methods return `Future<T>`
- Lint config in `analysis_options.yaml` — do not add rules beyond `package:lints/recommended.yaml` without discussion

---

## Git

- **Commit style:** Imperative, capital first letter — `Add X`, `Added X`, `Fix X`
- **Co-author footer:** `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`

---

## Testing

| | |
|---|---|
| Framework | flutter_test |
| Location | `test/` (mirrors `lib/src/` structure) |
| File pattern | `*_test.dart` |
| Structure | `void main() { group('...', () { test('...', () { ... }); }); }` |
| Mocking | mocktail — `MockHttpClient` in `test/mocks/` |
| Coverage | not configured |

Run a single test by name: `flutter test -k "description string"`. Use `setUp()` for shared test initialisation.
