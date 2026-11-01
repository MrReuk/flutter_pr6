import 'json_helpers.dart';

class Genre {
  final int id;
  final String name;
  final String description;
  final DateTime? deletedAt;

  const Genre({required this.id, required this.name, this.description = '', this.deletedAt});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      description: jsonString(json['description']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'description': description};

  bool get isDeleted => deletedAt != null;

  Genre copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Genre(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
