int jsonInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

int? jsonIntOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String jsonString(Object? value, [String fallback = '']) {
  if (value is String) return value;
  if (value == null) return fallback;
  return '$value';
}

List<int> jsonIntList(Object? value) {
  if (value is! List) return <int>[];
  return <int>[
    for (final element in value)
      if (element is int) element else if (element is num) element.toInt(),
  ];
}

int? jsonRefId(Object? value) {
  if (value is Map) return jsonIntOrNull(value['id']);
  return jsonIntOrNull(value);
}

List<int> jsonRefIds(Object? value) {
  if (value is! List) return <int>[];
  return <int>[for (final element in value) ?jsonRefId(element)];
}

DateTime? jsonDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

Map<String, dynamic> jsonMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}
