import 'page_result.dart';
import 'query_params.dart';

class SimpleQuery {
  final List<String> sortFields;
  final String defaultSort;
  final String search;
  final String filter;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const SimpleQuery({
    required this.sortFields,
    required this.defaultSort,
    required this.sortField,
    this.search = '',
    this.filter = '',
    this.sortAscending = true,
    this.page = 1,
    this.size = kDefaultPageSize,
    this.includeDeleted = false,
  });

  factory SimpleQuery.initial({required List<String> sortFields, required String defaultSort}) {
    return SimpleQuery(sortFields: sortFields, defaultSort: defaultSort, sortField: defaultSort);
  }

  factory SimpleQuery.fromParams(
    Map<String, String> params, {
    required List<String> sortFields,
    required String defaultSort,
  }) {
    final sort = parseSortParam(params['sort'], sortFields, defaultSort);
    return SimpleQuery(
      sortFields: sortFields,
      defaultSort: defaultSort,
      search: params['search'] ?? '',
      filter: params['filter'] ?? '',
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePageParam(params['page']),
      size: parseSizeParam(params['size']),
      includeDeleted: params['deleted'] == '1',
    );
  }

  int get activeFilterCount => (filter.isNotEmpty ? 1 : 0) + (includeDeleted ? 1 : 0);

  Map<String, String> toParams() {
    return {
      if (search.isNotEmpty) 'search': search,
      if (filter.isNotEmpty) 'filter': filter,
      if (sortField != defaultSort || !sortAscending)
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

  SimpleQuery copyWith({
    String? search,
    String? filter,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return SimpleQuery(
      sortFields: sortFields,
      defaultSort: defaultSort,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  SimpleQuery reset() {
    return SimpleQuery(
      sortFields: sortFields,
      defaultSort: defaultSort,
      sortField: sortField,
      sortAscending: sortAscending,
      size: size,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleQuery &&
          other.search == search &&
          other.filter == filter &&
          other.sortField == sortField &&
          other.sortAscending == sortAscending &&
          other.page == page &&
          other.size == size &&
          other.includeDeleted == includeDeleted;

  @override
  int get hashCode =>
      Object.hash(search, filter, sortField, sortAscending, page, size, includeDeleted);
}

const List<String> kGenreSortFields = ['name'];
const List<String> kPublisherSortFields = ['name', 'city', 'foundedYear'];
const List<String> kReaderSortFields = ['fullName', 'email'];
const List<String> kLoanSortFields = ['issuedAt', 'dueAt', 'returnedAt'];
