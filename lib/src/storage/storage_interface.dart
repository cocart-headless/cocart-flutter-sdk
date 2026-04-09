/// Abstract storage interface for persisting session data.
///
/// Mirrors the TS SDK's `EncryptedStorage` contract.
abstract class CoCartStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
