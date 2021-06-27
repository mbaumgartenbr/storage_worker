part of messaging;

class WorkerData {
  const WorkerData({
    required this.storeName,
    this.key,
    this.object,
  });

  final String storeName;

  /// Key to READ or DELETE.
  final String? key;

  /// Json encoded Map to WRITE at [key].
  final String? object;

  Map<String, dynamic>? objectAsMap() {
    return object == null ? null : jsonDecode(object!);
  }

  Map<String, dynamic> toMap() => {
        'storeName': storeName,
        if (key != null) 'key': key,
        if (object != null) 'object': object,
      };

  factory WorkerData.fromMap(Map<String, dynamic> map) {
    return WorkerData(
      storeName: map['storeName'],
      key: map['key'],
      object: map['object'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WorkerData.fromJson(String json) {
    return WorkerData.fromMap(jsonDecode(json));
  }

  @override
  String toString() =>
      'WorkerData(storeName: $storeName, key: $key, object: $object)';
}
