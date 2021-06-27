part of messaging;

class WorkerRequest {
  const WorkerRequest._({
    required this.type,
    required this.data,
  });

  final String type;
  final WorkerData data;

  Map<String, dynamic> toMap() => {
        'type': type,
        'data': data.toMap(),
      };

  factory WorkerRequest.fromMap(Map<String, dynamic> map) {
    return WorkerRequest._(
      type: map['type'],
      data: WorkerData.fromMap(map['data']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WorkerRequest.fromJson(String json) {
    return WorkerRequest.fromMap(jsonDecode(json));
  }

  WorkerRequest.open({
    required String storeName,
  })  : type = Operation.open,
        data = WorkerData(storeName: storeName);

  WorkerRequest.close({
    required String storeName,
  })  : type = Operation.close,
        data = WorkerData(storeName: storeName);

  WorkerRequest.read({
    required String storeName,
    required String key,
  })  : type = Operation.read,
        data = WorkerData(storeName: storeName, key: key);

  WorkerRequest.write({
    required String storeName,
    required String key,
    required Map<String, dynamic> object,
  })  : type = Operation.write,
        data = WorkerData(
          storeName: storeName,
          key: key,
          object: jsonEncode(object),
        );

  WorkerRequest.delete({
    required String storeName,
    required String key,
  })  : type = Operation.delete,
        data = WorkerData(storeName: storeName, key: key);
}
