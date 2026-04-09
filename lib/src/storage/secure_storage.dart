import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_interface.dart';

/// Default storage implementation using `flutter_secure_storage`.
///
/// Mirrors the TS SDK's `EncryptedStorage` backed by `localStorage`.
class SecureStorage implements CoCartStorage {
  final FlutterSecureStorage _storage;

  SecureStorage([String? encryptionKey])
      : _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
