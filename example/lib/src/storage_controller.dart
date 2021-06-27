import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:storage_worker/storage_worker.dart';

class StorageController {
  final failures = ValueNotifier<List<String>>([]);

  final text = ValueNotifier<String>('Nothing');

  late StorageWorker _storage;

  Store? _store;

  late final _errorStreamSubscription = _storage.onError.listen((err) {
    failures.value = [...failures.value, err];
  });

  Future<void> openStore([String storeName = 'store']) async {
    _store ??= await _storage.openStore(storeName).catchError((msg) {
      failures.value = [...failures.value, msg];
    });
    text.value = _store != null
        ? '${_store!.name} is open'
        : 'Error opening classes_store';
  }

  Future<void> closeStore([String storeName = 'store']) async {
    await _storage.closeStore(storeName).catchError((msg) {
      failures.value = [...failures.value, msg];
    });
    text.value = 'Store: "$storeName" is now closed.';
    _store = null;
  }

  Future<void> put({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    if (_store == null) return _onError('You must open the store first.');

    await _store!.write(key: key, value: value).then(
          (_) => text.value = 'Wrote value: $value\nAt key: $key',
          onError: (msg) => failures.value = [...failures.value, msg],
        );
  }

  Future<void> get(String key) async {
    if (_store == null) return _onError('You must open the store first.');

    Map<String, dynamic>? object;
    await _store!.read(key).then(
          (value) => object = value,
          onError: _onError,
        );
    if (object == null) {
      _onError('Got null object for key: Key');
    } else {
      text.value = object!.entries
          .map<String>((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    }
  }

  Future<void> delete(String key) async {
    if (_store == null) return _onError('You must open the store first.');

    await _store!.delete(key).then(
          (_) => text.value = 'Deleted key: $key',
          onError: (msg) => failures.value = [...failures.value, msg],
        );
  }

  void _onError(String message) {
    failures.value = [...failures.value, message];
  }

  Future<void> init() async {
    _storage = StorageWorker();
    return _storage.init();
  }

  void dispose() {
    _errorStreamSubscription.cancel();
    text.dispose();
    failures.dispose();
    _storage.dispose();
  }
}
