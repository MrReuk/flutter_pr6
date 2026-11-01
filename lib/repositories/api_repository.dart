import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/json_helpers.dart';
import '../models/page_result.dart';
import 'entity_repository.dart';

const int kReferencePageSize = 100;
const Duration kCacheLifetime = Duration(minutes: 5);

abstract class ApiRepository<T, Q> implements EntityRepository<T, Q>, CachedRepository {
  ApiRepository({
    required this.dio,
    required this.resource,
    this.cacheAll = false,
    this.cacheLifetime = kCacheLifetime,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Dio dio;
  final String resource;
  final bool cacheAll;
  final Duration cacheLifetime;
  final DateTime Function() _now;

  CancelToken? _findToken;
  Future<List<T>>? _cache;
  DateTime _cachedAt = DateTime.fromMillisecondsSinceEpoch(0);

  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toBody(T item);
  int idOf(T item);
  Map<String, dynamic> queryOf(Q query);

  Future<String?> deleteBlocker(int id, {required bool permanent}) async => null;

  PageResult<T> parsePage(Object? data) {
    final map = jsonMap(data);
    final raw = map['items'];
    if (raw is! List) {
      throw const FormatException('В ответе нет списка items');
    }
    return PageResult<T>(
      items: [for (final element in raw) fromJson(jsonMap(element))],
      page: jsonInt(map['page'], 1),
      size: jsonInt(map['size'], kDefaultPageSize),
      total: jsonInt(map['total']),
    );
  }

  @override
  void invalidate() {
    _cache = null;
  }

  @override
  Future<PageResult<T>> find(Q query) {
    _findToken?.cancel('Запрос устарел');
    final token = _findToken = CancelToken();
    return guard(() async {
      final response = await dio.get<dynamic>(
        '/$resource',
        queryParameters: queryOf(query),
        cancelToken: token,
      );
      return parsePage(response.data);
    });
  }

  @override
  Future<List<T>> findAll() async {
    if (!cacheAll) return _loadAll();

    final fresh = _cache != null && _now().difference(_cachedAt) < cacheLifetime;
    if (!fresh) {
      _cache = _loadAll();
      _cachedAt = _now();
    }
    final pending = _cache!;
    try {
      return await pending;
    } catch (_) {
      if (identical(_cache, pending)) _cache = null;
      rethrow;
    }
  }

  Future<List<T>> _loadAll() {
    return guard(() async {
      final items = <T>[];
      var page = 1;
      while (true) {
        final response = await dio.get<dynamic>(
          '/$resource',
          queryParameters: {'includeDeleted': 'true', 'size': kReferencePageSize, 'page': page},
        );
        final chunk = parsePage(response.data);
        items.addAll(chunk.items);
        if (chunk.items.isEmpty || page >= chunk.totalPages) break;
        page++;
      }
      return List<T>.unmodifiable(items);
    });
  }

  @override
  Future<T?> findById(int id) async {
    try {
      return await guard<T?>(() async {
        final response = await dio.get<dynamic>(
          '/$resource/$id',
          queryParameters: {'includeDeleted': 'true'},
        );
        return fromJson(jsonMap(response.data));
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<T> create(T item) {
    return guard(() async {
      try {
        final response = await dio.post<dynamic>('/$resource', data: toBody(item));
        return fromJson(jsonMap(response.data));
      } finally {
        invalidate();
      }
    });
  }

  @override
  Future<T> update(T item) {
    return guard(() async {
      try {
        final response = await dio.put<dynamic>('/$resource/${idOf(item)}', data: toBody(item));
        return fromJson(jsonMap(response.data));
      } finally {
        invalidate();
      }
    });
  }

  Future<void> _ensureNotBlocked(int id, {required bool permanent}) async {
    final blocker = await deleteBlocker(id, permanent: permanent);
    if (blocker != null) throw ConflictException(blocker);
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _ensureNotBlocked(id, permanent: false);
      try {
        await dio.delete<dynamic>('/$resource/$id');
      } finally {
        invalidate();
      }
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _ensureNotBlocked(id, permanent: true);
      try {
        await dio.delete<dynamic>('/$resource/$id', queryParameters: {'hard': 'true'});
      } finally {
        invalidate();
      }
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      try {
        await dio.post<dynamic>('/$resource/$id/restore');
      } finally {
        invalidate();
      }
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final allowed = <int>[];
      for (final id in ids) {
        if (await deleteBlocker(id, permanent: false) == null) allowed.add(id);
      }
      if (allowed.isEmpty) return 0;
      try {
        final response = await dio.post<dynamic>('/$resource/bulk-delete', data: {'ids': allowed});
        return jsonInt(jsonMap(response.data)['deleted']);
      } finally {
        invalidate();
      }
    });
  }
}

Map<String, dynamic> pagingQuery({
  required String search,
  required String sortField,
  required bool sortAscending,
  required int page,
  required int size,
  required bool includeDeleted,
}) {
  return {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    'page': page,
    'size': size,
    if (includeDeleted) 'includeDeleted': 'true',
  };
}
