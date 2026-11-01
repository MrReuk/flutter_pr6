import 'page_result.dart';
import 'query_params.dart';

class AuthorQuery {
  static const List<String> sortFields = ['fullName', 'country', 'birthYear'];

  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const AuthorQuery({
    this.search = '',
    this.sortField = 'fullName',
    this.sortAscending = true,
    this.page = 1,
    this.size = kDefaultPageSize,
    this.includeDeleted = false,
  });

  factory AuthorQuery.fromParams(Map<String, String> params) {
    final sort = parseSortParam(params['sort'], sortFields, 'fullName');
    return AuthorQuery(
      search: params['search'] ?? '',
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePageParam(params['page']),
      size: parseSizeParam(params['size']),
      includeDeleted: params['deleted'] == '1',
    );
  }

  int get activeFilterCount => includeDeleted ? 1 : 0;

  Map<String, String> toParams() {
    return {
      if (search.isNotEmpty) 'search': search,
      if (sortField != 'fullName' || !sortAscending)
        'sort': formatSortParam(sortField, sortAscending),
      if (page > 1) 'page': '$page',
      if (size != kDefaultPageSize) 'size': '$size',
      if (includeDeleted) 'deleted': '1',
    };
  }

  String toLocation(String path) {
    final params = toParams();
    return Uri(path: path, queryParameters: params.isEmpty ? null : params).toString();
  }

  AuthorQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
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
      other is AuthorQuery &&
          other.search == search &&
          other.sortField == sortField &&
          other.sortAscending == sortAscending &&
          other.page == page &&
          other.size == size &&
          other.includeDeleted == includeDeleted;

  @override
  int get hashCode => Object.hash(search, sortField, sortAscending, page, size, includeDeleted);
}
