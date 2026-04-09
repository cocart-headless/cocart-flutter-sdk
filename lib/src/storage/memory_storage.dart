import 'storage_interface.dart';

/// In-memory storage for tests and server-side Dart usage.
///
/// Mirrors the TS SDK's `MemoryStorage` (Node/SSR fallback).
class MemoryStorage implements CoCartStorage {
  final _store = <String, String>{};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async => _store[key] = value;

  @override
  Future<void> delete(String key) async => _store.remove(key);
}
