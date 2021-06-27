import 'dart:async' show Completer;
import 'dart:html' show Worker, MessageEvent;

import 'constants.dart';
import 'messaging/messaging.dart';

part 'store.dart';

/// An interface to communicate with a web worker database (IndexedDB).
///
/// Calling init() will throw if Web Workers are not supported in the current
/// platform, you can avoid it by checking [StorageWorker.isSupported] first.
///
/// If the worker side IndexedDB is not supported, the worker will terminate
/// immediately and a failure message will be posted which can be captured in
/// [onError].
///
/// You can create how many stores as you need to, just make sure to give them
/// unique names.
///
/// Make sure to generate the `worker.dart.js` file before running. I've
/// included a Makefile to compile the javascript code.
///
/// The messaging between main and worker threads is done with [WorkerRequest]
/// and [WorkerResponse] that get converted to json because of the
/// [structured clone algorithm](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm).
class StorageWorker {
  Worker? _worker;

  /// Checks if the current platform supports Web Workers.
  static bool get isSupported => Worker.supported;

  /// Subscribe to this stream for possible errors in the worker side.
  Stream<String> get onError => _onResponse
      .where((response) => response.type == Operation.failure)
      .map((response) => response.message!);

  /// Initializes the Web Worker.
  ///
  /// [scriptUrl] must be the location of your js file.
  /// Make sure to add it to the web folder when building for production.
  ///
  /// Remember to update [scriptUrl] depending on your environment. Or simply
  /// store the js file in the same path for production and development.
  ///
  /// If init was already called, calling it again will terminate the worker
  /// and spin up a new one.
  Future<void> init([String scriptUrl = 'lib/src/worker/worker.dart.js']) {
    if (!isSupported) {
      throw StorageWorkerError(
        'Web Workers are not supported in the current platform. '
        'Are you running from the web?',
      );
    }
    _worker?.terminate();
    _worker = Worker(scriptUrl);
    return Future.value();
  }

  /// Opens an IndexedDB database and objectStore.
  ///
  /// You can have as many stores as you need, just give them different names.
  Future<Store?> openStore(String storeName) async {
    final completer = Completer<Store?>();

    final streamSubscription = _on(Operation.open).listen((WorkerData data) {
      if (data.storeName == storeName) {
        completer.complete(
          Store(name: data.storeName).._storage = this,
        );
      } else {
        completer.completeError('Could not open the store: $storeName.');
      }
    });

    _worker!.postMessage(
      WorkerRequest.open(storeName: storeName).toJson(),
    );

    return completer.future..then((_) => streamSubscription.cancel());
  }

  /// Closes both database and objectStore related to [storeName].
  Future<void> closeStore(String storeName) async {
    final completer = Completer<void>();

    final streamSubscription = _on(Operation.close).listen((WorkerData data) {
      if (data.storeName == storeName) {
        completer.complete();
      } else {
        completer.completeError('Error closing store: $storeName');
      }
    });

    _worker!.postMessage(
      WorkerRequest.close(storeName: storeName).toJson(),
    );

    return completer.future..then((_) => streamSubscription.cancel());
  }

  /// Reads the value associated with [key] from the store [storeName].
  Future<Map<String, dynamic>?> read({
    required String storeName,
    required String key,
  }) async {
    final completer = Completer<Map<String, dynamic>?>();

    final streamSubscription = _on(Operation.read).listen((WorkerData data) {
      if (data.key == key) {
        completer.complete(data.objectAsMap());
      } else {
        completer.completeError(
          'Gotten key: ${data.key} (expected: $key) '
          'in response while reading from store: $storeName.',
        );
      }
    });

    _worker!.postMessage(
      WorkerRequest.read(storeName: storeName, key: key).toJson(),
    );

    return completer.future..then((_) => streamSubscription.cancel());
  }

  /// Writes [value] at [key] of the objectStore related to [storeName].
  Future<void> write({
    required String storeName,
    required String key,
    required Map<String, dynamic> value,
  }) async {
    final completer = Completer<void>();

    final streamSubscription = _on(Operation.write).listen((WorkerData data) {
      if (data.key == key) {
        completer.complete();
      } else {
        completer.completeError(
          'Gotten key: ${data.key} (expected: $key) '
          'in response while writing to store: $storeName.',
        );
      }
    });

    _worker!.postMessage(
      WorkerRequest.write(
        storeName: storeName,
        key: key,
        object: value,
      ).toJson(),
    );

    return completer.future..then((_) => streamSubscription.cancel());
  }

  Future<void> delete({
    required String storeName,
    required String key,
  }) async {
    final completer = Completer<void>();

    final streamSubscription = _on(Operation.delete).listen((WorkerData data) {
      if (data.key == key) {
        completer.complete();
      } else {
        completer.completeError(
          'Gotten key: ${data.key} (expected: $key) '
          'in response while deleting from store: $storeName.',
        );
      }
    });

    _worker!.postMessage(
      WorkerRequest.delete(storeName: storeName, key: key).toJson(),
    );

    return completer.future..then((_) => streamSubscription.cancel());
  }

  /// Closes all open stores and terminates worker.
  Future<void> dispose() async {
    final completer = Completer<void>();

    final streamSubscription = _on(Operation.close).listen((WorkerData data) {
      if (data.storeName == kCloseAllStores) {
        completer.complete();
      } else {
        completer.completeError(
          'Failed to close stores while disposing StorageWorker.',
        );
      }
    });

    _worker!.postMessage(
      WorkerRequest.close(storeName: kCloseAllStores).toJson(),
    );

    _worker!.terminate();
    _worker = null;
    return completer.future..then((_) => streamSubscription.cancel());
  }

  Stream<WorkerResponse> get _onResponse {
    _ensureInitialized();

    return _worker!.onMessage.map((MessageEvent event) {
      if (event.data is! String) {
        /// This should never happen if `worker.dart` posts only strings.
        return WorkerResponse.failure(
          storeName: '',
          message: 'StorageWorker got an invalid response from Web Worker.',
        );
      }
      return WorkerResponse.fromJson(event.data);
    });
  }

  Stream<WorkerData> _on(String operation) => _onResponse
      .where((response) => response.type == operation)
      .map((response) => response.data);

  void _ensureInitialized() {
    if (_worker == null) {
      throw StorageWorkerError('You must call StorageWorker.init() first.');
    }
  }
}

class StorageWorkerError implements Exception {
  const StorageWorkerError(this.message);
  final String message;
}
