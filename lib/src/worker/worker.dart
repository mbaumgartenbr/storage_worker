@JS()
library storage_worker.worker;

import 'dart:collection' show MapMixin;
import 'dart:html' show DedicatedWorkerGlobalScope, MessageEvent;
import 'dart:indexed_db';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

import '../constants.dart';
import '../messaging/messaging.dart';

/* 
  * FILE SUMMARY (quickly navigate with "ctrl + f" and type one of the below)
  *
  * (1) JS Interop
  * (2) main
  * (3) StorageManager
  * (4) Store
*/

//*
//* (1) JS Interop -------------------------------------------------------------
//*

@JS('self')
external DedicatedWorkerGlobalScope get self;

@JS('Object.keys')
external Iterable<String> _getJsMapKeys(Object jsMap);

class JsMap extends MapMixin<String, dynamic> {
  JsMap(this._jsMap);

  final Object _jsMap;

  @override
  Iterable<String> get keys => _getJsMapKeys(_jsMap);

  @override
  dynamic operator [](Object? key) => getProperty(_jsMap, key.toString());

  @override
  void operator []=(String key, dynamic value) {
    setProperty(_jsMap, key, value);
  }

  @override
  void clear() {
    throw UnimplementedError('JsMap.clear() not implemented.');
  }

  @override
  remove(Object? key) {
    throw UnimplementedError('JsMap.remove() not implemented.');
  }
}

//*
//* (2) main -------------------------------------------------------------------
//*

final manager = _StorageManager._();

void main() {
  if (self.indexedDB == null) {
    postFailure(storeName: '', message: 'IndexedDB is not supported.');
    return self.close();
  }

  self.onMessage.listen((MessageEvent event) async {
    if (event.data is! String) {
      postFailure(
        storeName: '',
        message: 'Worker got an unexpected request: ${event.data}',
      );
      return;
    }

    final request = WorkerRequest.fromJson(event.data);

    await handleRequest(request);
  });
}

void postFailure({
  required String storeName,
  required String message,
}) {
  self.postMessage(
    WorkerResponse.failure(
      storeName: storeName,
      message: message,
    ).toJson(),
  );
}

Future<void> handleRequest(WorkerRequest request) async {
  switch (request.type) {
    case Operation.open:
      return manager.open(
        request.data.storeName,
      );
    case Operation.close:
      return manager.close(
        request.data.storeName,
      );
    case Operation.read:
      return manager.read(
        storeName: request.data.storeName,
        key: request.data.key!,
      );
    case Operation.write:
      return manager.write(
        storeName: request.data.storeName,
        key: request.data.key!,
        value: request.data.object!,
      );
    case Operation.delete:
      return manager.delete(
        storeName: request.data.storeName,
        key: request.data.key!,
      );
    default:
      postFailure(
        storeName: request.data.storeName,
        message: 'Unknown WorkerRequest type: ${request.type} '
            'for store: ${request.data.storeName}.',
      );
      return Future.value();
  }
}

//*
//* (3) StorageManager ---------------------------------------------------------
//*

class _StorageManager {
  _StorageManager._();

  final _stores = <String, _Store>{};

  bool storeExists(String storeName) => _stores[storeName] != null;

  Future<_Store> getStore(String storeName) async {
    await open(storeName);
    return _stores[storeName]!;
  }

  Future<void> open(String storeName) async {
    if (!storeExists(storeName)) {
      final db = await self.indexedDB!.open(
        storeName,
        version: 1,
        onUpgradeNeeded: allowInterop((event) {
          final _db = event.target.result as Database;

          if (!_db.objectStoreNames!.contains(storeName)) {
            _db.createObjectStore(storeName);
          }
        }),
      );
      _stores[storeName] = _Store._(db, name: storeName);
    }

    self.postMessage(
      WorkerResponse.open(storeName: storeName).toJson(),
    );
  }

  Future<void> close(String storeName) async {
    if (storeName == kCloseAllStores) {
      for (final store in _stores.values) {
        store.close();
      }
      self.postMessage(
        WorkerResponse.close(
          storeName: kCloseAllStores,
        ).toJson(),
      );
      return _stores.clear();
    }

    if (storeExists(storeName)) {
      _stores[storeName]!.close();
      _stores.remove(storeName);
    }
    // Either a success or not, we post so the completer completes.
    self.postMessage(
      WorkerResponse.close(storeName: storeName).toJson(),
    );
  }

  Future<void> read({
    required String storeName,
    required String key,
  }) async {
    final store = await manager.getStore(storeName);
    final object = await store.read(key);

    self.postMessage(
      WorkerResponse.read(
        storeName: storeName,
        key: key,
        object: object,
      ).toJson(),
    );
  }

  Future<void> write({
    required String storeName,
    required String key,
    required String value,
  }) async {
    final store = await getStore(storeName);

    await store.write(key, value);

    self.postMessage(
      WorkerResponse.write(storeName: storeName, key: key).toJson(),
    );
  }

  Future<void> delete({
    required String storeName,
    required String key,
  }) async {
    final store = await getStore(storeName);
    await store.delete(key);

    self.postMessage(
      WorkerResponse.delete(storeName: storeName, key: key).toJson(),
    );
  }
}

//*
//* (4) Store ------------------------------------------------------------------
//*

class _Store {
  const _Store._(this._db, {required this.name});

  final Database _db;
  final String name;

  ObjectStore get({required bool readOnly}) {
    return _db
        .transactionStore(name, readOnly ? 'readonly' : 'readwrite')
        .objectStore(name);
  }

  Future<String?> read(String key) async {
    final store = get(readOnly: true);

    String? json;

    await store.getObject(key).then(
          (value) => json = value,
          onError: (_) => json = null,
        );

    return json;
  }

  Future<void> write(String key, String value) async {
    await get(readOnly: false).put(value, key);
  }

  Future<void> delete(String key) async {
    await get(readOnly: false).delete(key);
  }

  void close() => _db.close();
}
