part of 'storage_worker.dart';

/// This class represents both database & objectStore from IndexedDb.
class Store {
  Store({required this.name});

  StorageWorker? _storage;

  /// The name of this store to use in IndexedDB.
  final String name;

  Future<Map<String, dynamic>?> read(String key) async {
    _ensureNotDisposed();
    return _storage!.read(storeName: name, key: key);
  }

  Future<void> write({
    required String key,
    required Map<String, dynamic> value,
  }) {
    _ensureNotDisposed();
    return _storage!.write(storeName: name, key: key, value: value);
  }

  Future<void> delete(String key) {
    _ensureNotDisposed();
    return _storage!.delete(storeName: name, key: key);
  }

  /// Closes this store and invalidates this instance.
  Future<void> dispose() async {
    await _storage?.closeStore(name).catchError(print);
    _storage = null;
  }

  void _ensureNotDisposed() {
    if (_storage == null) {
      throw StorageWorkerError('This store was disposed and must not be used.');
    }
  }
}
