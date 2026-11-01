import 'page_result.dart';
import 'query_params.dart';

class BookQuery {
  static const List<String> sortFields = ['title', 'year', 'pages'];
  static const Object _unset = Object();

  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;
  final bool onlyAvailable;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.onlyAvailable = false,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = kDefaultPageSize,
    this.includeDeleted = false,
  });

  factory BookQuery.fromParams(Map<String, String> params) {
    final sort = parseSortParam(params['sort'], sortFields, 'title');
    return BookQuery(
      search: params['search'] ?? '',
      genreId: parseIntParam(params['genreId']),
      publisherId: parseIntParam(params['publisherId']),
      yearFrom: parseIntParam(params['yearFrom']),
      yearTo: parseIntParam(params['yearTo']),
      onlyAvailable: params['available'] == '1',
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePageParam(params['page']),
      size: parseSizeParam(params['size']),
      includeDeleted: params['deleted'] == '1',
    );
  }

  int get activeFilterCount {
    final values = [genreId, publisherId, yearFrom, yearTo];
    return values.where((v) => v != null).length +
        (onlyAvailable ? 1 : 0) +
        (includeDeleted ? 1 : 0);
  }

  Map<String, String> toParams() {
    return {
      if (search.isNotEmpty) 'search': search,
      if (genreId != null) 'genreId': '$genreId',
      if (publisherId != null) 'publisherId': '$publisherId',
      if (yearFrom != null) 'yearFrom': '$yearFrom',
      if (yearTo != null) 'yearTo': '$yearTo',
      if (onlyAvailable) 'available': '1',
      if (sortField != 'title' || !sortAscending) 'sort': formatSortParam(sortField, sortAscending),
      if (page > 1) 'page': '$page',
      if (size != kDefaultPageSize) 'size': '$size',
      if (includeDeleted) 'deleted': '1',
    };
  }

  String toLocation(String path) {
    final params = toParams();
    return Uri(path: path, queryParameters: params.isEmpty ? null : params).toString();
  }

  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    bool? onlyAvailable,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: identical(genreId, _unset) ? this.genreId : genreId as int?,
      publisherId: identical(publisherId, _unset) ? this.publisherId : publisherId as int?,
      yearFrom: identical(yearFrom, _unset) ? this.yearFrom : yearFrom as int?,
      yearTo: identical(yearTo, _unset) ? this.yearTo : yearTo as int?,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookQuery &&
          other.search == search &&
          other.genreId == genreId &&
          other.publisherId == publisherId &&
          other.yearFrom == yearFrom &&
          other.yearTo == yearTo &&
          other.onlyAvailable == onlyAvailable &&
          other.sortField == sortField &&
          other.sortAscending == sortAscending &&
          other.page == page &&
          other.size == size &&
          other.includeDeleted == includeDeleted;

  @override
  int get hashCode => Object.hash(
    search,
    genreId,
    publisherId,
    yearFrom,
    yearTo,
    onlyAvailable,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
  );
}
