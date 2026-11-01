import 'json_helpers.dart';

class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    this.copiesAvailable = 0,
    this.deletedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final authors = json.containsKey('authors') ? json['authors'] : json['authorIds'];
    final genres = json.containsKey('genres') ? json['genres'] : json['genreIds'];
    final publisher = json.containsKey('publisher') ? json['publisher'] : json['publisherId'];

    return Book(
      id: jsonInt(json['id']),
      title: jsonString(json['title']),
      isbn: jsonString(json['isbn']),
      year: jsonInt(json['year']),
      pages: jsonInt(json['pages']),
      publisherId: jsonRefId(publisher) ?? 0,
      authorIds: jsonRefIds(authors),
      genreIds: jsonRefIds(genres),
      copiesTotal: jsonInt(json['copiesTotal']),
      copiesAvailable: jsonInt(json['copiesAvailable']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'isbn': isbn,
    'year': year,
    'pages': pages,
    'publisherId': publisherId,
    'authorIds': authorIds,
    'genreIds': genreIds,
    'copiesTotal': copiesTotal,
  };

  bool get isDeleted => deletedAt != null;

  Book copyWith({
    int? id,
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
