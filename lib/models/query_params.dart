import 'page_result.dart';

int? parseIntParam(String? raw) => raw == null ? null : int.tryParse(raw);

int parsePageParam(String? raw) {
  final page = parseIntParam(raw) ?? 1;
  return page < 1 ? 1 : page;
}

int parseSizeParam(String? raw) {
  final size = parseIntParam(raw) ?? kDefaultPageSize;
  return kPageSizes.contains(size) ? size : kDefaultPageSize;
}

({String field, bool ascending}) parseSortParam(
  String? raw,
  List<String> allowed,
  String fallback,
) {
  final parts = (raw ?? '').split(',');
  final field = allowed.contains(parts.first) ? parts.first : fallback;
  final ascending = !(parts.length > 1 && parts[1] == 'desc');
  return (field: field, ascending: ascending);
}

String formatSortParam(String field, bool ascending) => '$field,${ascending ? 'asc' : 'desc'}';
