const String kCloseAllStores = 'STORAGE-WORKER-CLOSE-ALL-STORES';

abstract class Operation {
  static const String failure = 'failure';

  static const String open = 'open';
  static const String close = 'close';

  static const String read = 'read';
  static const String write = 'write';
  static const String delete = 'delete';
}
