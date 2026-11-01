import 'json_helpers.dart';

class Author {
  final int id;
  final String fullName;
  final String country;
  final int? birthYear;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.fullName,
    this.country = '',
    this.birthYear,
    this.deletedAt,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: jsonInt(json['id']),
      fullName: jsonString(json['fullName']),
      country: jsonString(json['country']),
      birthYear: jsonIntOrNull(json['birthYear']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'country': country,
    'birthYear': birthYear,
  };

  bool get isDeleted => deletedAt != null;

  Author copyWith({
    int? id,
    String? fullName,
    String? country,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
