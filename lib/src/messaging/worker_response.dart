part of messaging;

class WorkerResponse {
  const WorkerResponse({
    required this.type,
    required this.data,
    this.message,
  });

  final String type;
  final WorkerData data;

  /// If [message] is not null, this response is a FAILURE.
  final String? message;

  Map<String, dynamic> toMap() => {
        'type': type,
        'data': data.toMap(),
        if (message != null) 'message': message,
      };

  factory WorkerResponse.fromMap(Map<String, dynamic> map) {
    return WorkerResponse(
      type: map['type'],
      data: WorkerData.fromMap(map['data']),
      message: map['message'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WorkerResponse.fromJson(String json) {
    return WorkerResponse.fromMap(jsonDecode(json));
  }

  WorkerResponse.open({
    required String storeName,
    this.message,
  })  : type = Operation.open,
        data = WorkerData(storeName: storeName);

  WorkerResponse.close({
    required String storeName,
    this.message,
  })  : type = Operation.close,
        data = WorkerData(storeName: storeName);

  WorkerResponse.read({
    required String storeName,
    required String key,
    required String? object,
    this.message,
  })  : type = Operation.read,
        data = WorkerData(storeName: storeName, key: key, object: object);

  WorkerResponse.write({
    required String storeName,
    required String key,
    this.message,
  })  : type = Operation.write,
        data = WorkerData(storeName: storeName, key: key);

  WorkerResponse.delete({
    required String storeName,
    required String key,
    this.message,
  })  : type = Operation.delete,
        data = WorkerData(storeName: storeName, key: key);

  WorkerResponse.failure({
    required String storeName,
    required this.message,
  })  : type = Operation.failure,
        data = WorkerData(storeName: storeName);
}
