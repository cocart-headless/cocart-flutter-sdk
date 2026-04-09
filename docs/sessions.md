# Sessions API

Sessions represent active cart instances on your WooCommerce store. The Sessions API is an admin-level endpoint that requires Consumer Key authentication.

## Admin Sessions Endpoint

### List All Sessions

```dart
final client = CoCart('https://your-store.com',
    CoCartOptions(consumerKey: 'ck_123...', consumerSecret: 'cs_456...'));

final sessions = await client.sessions().all();
```

## Storage Adapters

The SDK uses storage adapters to persist session data (cart keys, JWT tokens) across app restarts.

### SecureStorage (Default)

Uses `flutter_secure_storage` to persist data in the platform's secure keychain/keystore:

```dart
// Used automatically — no configuration needed
final client = CoCart('https://your-store.com');
await client.restoreSession();
```

- **iOS** — Keychain Services
- **Android** — EncryptedSharedPreferences (or Keystore)
- **Web** — localStorage (via flutter_secure_storage web implementation)
- **macOS** — Keychain Services
- **Windows** — Windows Credential Manager
- **Linux** — libsecret

### MemoryStorage

In-memory storage for testing or server-side Dart. Data does not persist across app restarts:

```dart
final client = CoCart('https://your-store.com',
    CoCartOptions(storage: MemoryStorage()));
```

### Custom Storage

Implement the `CoCartStorage` interface for any storage backend:

```dart
class SharedPrefsStorage implements CoCartStorage {
  final SharedPreferences _prefs;

  SharedPrefsStorage(this._prefs);

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async =>
      _prefs.setString(key, value);

  @override
  Future<void> delete(String key) async => _prefs.remove(key);
}

final prefs = await SharedPreferences.getInstance();
final client = CoCart('https://your-store.com',
    CoCartOptions(storage: SharedPrefsStorage(prefs)));
```

## Guest-to-Customer Flow

A common pattern in mobile apps: the user browses as a guest, then logs in.

```dart
final client = CoCart('https://your-store.com');

// 1. Restore any previous guest session
await client.restoreSession();

// 2. Browse and add items as a guest
await client.cart().addItem(123, 2);
print('Guest cart key: ${client.getCartKey()}');

// 3. User decides to log in — items transfer to their account
await client.login('email@example.com', 'password');
print('Authenticated: ${client.isAuthenticated()}');

// 4. Cart is now tied to the customer account
final cart = await client.cart().get();
print('Items: ${cart.getItemCount()}');

// 5. Logout — returns to guest mode
await client.logout();
print('Guest again: ${client.isGuest()}');
```

## Custom Storage Key

The key used to persist the cart key in storage defaults to `'cocart_cart_key'`. You can customize it:

```dart
final client = CoCart('https://your-store.com',
    CoCartOptions(storageKey: 'my_app_cart_key'));
```

This is useful when running multiple CoCart clients in the same app (e.g. multi-store).
