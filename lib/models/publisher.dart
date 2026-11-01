import 'json_helpers.dart';

class Publisher {
  final int id;
  final String name;
  final String city;
  final int? foundedYear;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    this.city = '',
    this.foundedYear,
    this.deletedAt,
  });

  factory Publisher.fromJson(Map<String, dynamic> json) {
    return Publisher(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      city: jsonString(json['city']),
      foundedYear: jsonIntOrNull(json['foundedYear']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'city': city, 'foundedYear': foundedYear};

  bool get isDeleted => deletedAt != null;

  Publisher copyWith({
    int? id,
    String? name,
    String? city,
    int? foundedYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      foundedYear: foundedYear ?? this.foundedYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
