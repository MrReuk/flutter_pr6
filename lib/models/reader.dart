import 'json_helpers.dart';

class LibraryCard {
  final int id;
  final String number;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  const LibraryCard({required this.id, required this.number, this.issuedAt, this.expiresAt});

  factory LibraryCard.fromJson(Map<String, dynamic> json) {
    return LibraryCard(
      id: jsonInt(json['id']),
      number: jsonString(json['number']),
      issuedAt: jsonDate(json['issuedAt']),
      expiresAt: jsonDate(json['expiresAt']),
    );
  }

  bool isExpiredAt(DateTime moment) {
    final end = expiresAt;
    return end != null && end.isBefore(moment);
  }
}

class Reader {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard? card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.card,
    this.deletedAt,
  });

  factory Reader.fromJson(Map<String, dynamic> json) {
    final rawCard = json['card'];
    return Reader(
      id: jsonInt(json['id']),
      fullName: jsonString(json['fullName']),
      email: jsonString(json['email']),
      phone: jsonString(json['phone']),
      card: rawCard is Map ? LibraryCard.fromJson(jsonMap(rawCard)) : null,
      deletedAt: jsonDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {'fullName': fullName, 'email': email, 'phone': phone};

  bool get isDeleted => deletedAt != null;

  Reader copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
