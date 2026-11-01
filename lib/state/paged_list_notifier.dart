import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../repositories/entity_repository.dart';
import '../repositories/repository_exception.dart';
import 'load_status.dart';

typedef DeleteSummary = ({int requested, int deleted, String? error});

String describeError(Object error) {
  return error is RepositoryException ? error.message : '$error';
}

class PagedListNotifier<T, Q> extends ChangeNotifier {
  PagedListNotifier({
    required Q initialQuery,
    required EntityRepository<T, Q> repository,
    required int Function(T item) idOf,
  }) : _query = initialQuery,
       _repository = repository,
       _idOf = idOf;

  final EntityRepository<T, Q> _repository;
  final int Function(T item) _idOf;

  Q _query;
  PageResult<T> _result = PageResult<T>.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  bool _offline = false;
  final Set<int> _selected = {};
  int _requestId = 0;
  bool _disposed = false;

  Q get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;

  /// Последняя загрузка не удалась из-за недоступного сервера (а не из-за ответа с ошибкой).
  bool get offline => _offline;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    final requestId = ++_requestId;
    _status = LoadStatus.loading;
    _error = null;
    _offline = false;
    notifyListeners();

    try {
      final loaded = await _repository.find(_query);
      if (requestId != _requestId) return;
      _result = loaded;
      _status = LoadStatus.success;
    } catch (e) {
      if (requestId != _requestId) return;
      _error = 'Не удалось загрузить список: ${describeError(e)}';
      _offline = e is NetworkException;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(Q next, {bool force = false}) async {
    if (!force && next == _query) return;
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void setAllSelected(bool value) {
    final ids = _result.items.map(_idOf);
    if (value) {
      _selected.addAll(ids);
    } else {
      _selected.removeAll(ids);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<String?> softDelete(int id) => _perform(() => _repository.softDelete(id), id);

  Future<String?> hardDelete(int id) => _perform(() => _repository.hardDelete(id), id);

  Future<String?> restore(int id) => _perform(() => _repository.restore(id), id);

  Future<DeleteSummary> deleteSelected() async {
    final ids = _selected.toList();
    try {
      final count = await _repository.deleteMany(ids);
      _selected.clear();
      await load();
      return (requested: ids.length, deleted: count, error: null);
    } catch (e) {
      final message = describeError(e);
      await load();
      return (requested: ids.length, deleted: 0, error: message);
    }
  }

  Future<String?> _perform(Future<void> Function() action, int id) async {
    try {
      await action();
    } catch (e) {
      return describeError(e);
    }
    _selected.remove(id);
    await load();
    return null;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
