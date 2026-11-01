import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/models/simple_query.dart';

void main() {
  SimpleQuery parse(Map<String, String> params) =>
      SimpleQuery.fromParams(params, sortFields: kReaderSortFields, defaultSort: 'fullName');

  test('Параметры адреса разбираются в условия отбора', () {
    final q = parse({
      'search': 'иван',
      'filter': 'expired',
      'sort': 'email,desc',
      'page': '2',
      'size': '25',
      'deleted': '1',
    });

    expect(q.search, 'иван');
    expect(q.filter, 'expired');
    expect(q.sortField, 'email');
    expect(q.sortAscending, isFalse);
    expect(q.page, 2);
    expect(q.size, 25);
    expect(q.includeDeleted, isTrue);
    expect(q.activeFilterCount, 2);
  });

  test('Неизвестная сортировка заменяется сортировкой по умолчанию', () {
    final q = parse({'sort': 'unknown,desc'});

    expect(q.sortField, 'fullName');
  });

  test('Условия отбора переживают запись в адрес и чтение обратно', () {
    final original = parse({'search': 'а', 'filter': 'active', 'page': '3'});
    final location = original.toLocation('/readers');
    final restored = parse(Uri.parse(location).queryParameters);

    expect(restored, original);
  });

  test('Значения по умолчанию не попадают в адрес', () {
    final q = SimpleQuery.initial(sortFields: kReaderSortFields, defaultSort: 'fullName');

    expect(q.toLocation('/readers'), '/readers');
  });

  test('Смена условий возвращает на первую страницу, сброс очищает отбор', () {
    final q = parse({'page': '4', 'search': 'а', 'filter': 'active'});

    expect(q.copyWith(search: 'б').page, 1);
    final reset = q.reset();
    expect(reset.search, '');
    expect(reset.filter, '');
    expect(reset.includeDeleted, isFalse);
  });
}
