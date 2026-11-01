import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/auth/permissions.dart';
import 'package:library_app/auth/role.dart';
import 'package:library_app/core/breakpoints.dart';
import 'package:library_app/core/config.dart';
import 'package:library_app/widgets/library_scaffold.dart';

List<NavItem> _itemsOf(Role role) => visibleNavItems((permission) => roleCan(role, permission));

List<String> _paths(List<NavItem> items) => [for (final item in items) item.path];

void main() {
  group('Класс ширины окна', () {
    test('границы 600 и 1200 принадлежат старшему классу', () {
      expect(screenSizeForWidth(359.9), ScreenSize.compact);
      expect(screenSizeForWidth(599.9), ScreenSize.compact);
      expect(screenSizeForWidth(600), ScreenSize.medium);
      expect(screenSizeForWidth(768), ScreenSize.medium);
      expect(screenSizeForWidth(1199.9), ScreenSize.medium);
      expect(screenSizeForWidth(1200), ScreenSize.expanded);
      expect(screenSizeForWidth(1920), ScreenSize.expanded);
    });

    test('четыре проверяемые ширины попадают в разные классы навигации', () {
      expect(screenSizeForWidth(360), ScreenSize.compact);
      expect(screenSizeForWidth(768), ScreenSize.medium);
      expect(screenSizeForWidth(1280), ScreenSize.expanded);
      expect(screenSizeForWidth(1920), ScreenSize.expanded);
    });

    test('невыбранный вариант заменяется ближайшим меньшим', () {
      expect(pickByScreen(ScreenSize.expanded, compact: 1), 1);
      expect(pickByScreen(ScreenSize.expanded, compact: 1, medium: 2), 2);
      expect(pickByScreen(ScreenSize.expanded, compact: 1, medium: 2, expanded: 4), 4);
      expect(pickByScreen(ScreenSize.medium, compact: 1, expanded: 4), 1);
    });
  });

  group('Колонки сетки', () {
    test('на узком месте плитки идут в одну колонку, и колонок не меньше одной', () {
      expect(gridColumns(328, minTile: 240), 1);
      expect(gridColumns(10, minTile: 240), 1);
      expect(gridColumns(0, minTile: 240), 1);
    });

    test('число колонок растёт вместе с шириной', () {
      expect(gridColumns(639, minTile: 240), 2);
      expect(gridColumns(960, minTile: 240), 3);
      expect(gridColumns(1247, minTile: 240), 4);
      expect(gridColumns(1248, minTile: 240), 5);
    });

    test('промежутки между плитками учитываются', () {
      // Две плитки по 100 и промежуток 12 требуют 212, а не 200.
      expect(gridColumns(200, minTile: 100), 1);
      expect(gridColumns(212, minTile: 100), 2);
    });
  });

  group('Адрес API', () {
    test('адрес из параметра сборки используется без завершающей косой черты', () {
      expect(resolveApiBaseUrl('https://api.example.com/api'), 'https://api.example.com/api');
      expect(resolveApiBaseUrl('https://api.example.com/api/'), 'https://api.example.com/api');
      expect(resolveApiBaseUrl('  https://api.example.com/api  '), 'https://api.example.com/api');
    });

    test('без параметра сборки берётся адрес по умолчанию (в браузере /api)', () {
      expect(kSameOriginApi, '/api');
      expect(resolveApiBaseUrl(''), defaultApiBaseUrl);
      expect(resolveApiBaseUrl('   '), defaultApiBaseUrl);
    });

    test('в этой сборке тестов параметр не задан', () {
      expect(apiBaseUrl, defaultApiBaseUrl);
      expect(apiBaseUrl.endsWith('/'), isFalse);
    });
  });

  group('Разделы меню по ролям', () {
    test('число разделов у каждой роли', () {
      expect(_itemsOf(Role.reader), hasLength(6));
      expect(_itemsOf(Role.librarian), hasLength(8));
      expect(_itemsOf(Role.admin), hasLength(9));
    });

    test('читатель не получает разделов персонала ни в какой раскладке', () {
      final paths = _paths(_itemsOf(Role.reader));
      expect(paths, contains('/my/loans'));
      for (final hidden in ['/readers', '/loans', '/desk', '/admin/users', '/admin/stats']) {
        expect(paths, isNot(contains(hidden)), reason: hidden);
      }
      final split = splitForBottomBar(_itemsOf(Role.reader));
      expect(_paths([...split.primary, ...split.more]), isNot(contains('/admin/stats')));
    });

    test('читателю в нижней панели нужны «Мои выдачи», остальное уходит в «Ещё»', () {
      final split = splitForBottomBar(_itemsOf(Role.reader));
      expect(_paths(split.primary), ['/', '/books', '/authors', '/my/loans']);
      expect(_paths(split.more), ['/genres', '/publishers']);
    });

    test('библиотекарю в нижней панели нужны выдачи и рабочее место', () {
      final split = splitForBottomBar(_itemsOf(Role.librarian));
      expect(_paths(split.primary), ['/', '/books', '/loans', '/desk']);
      expect(_paths(split.more), ['/authors', '/genres', '/publishers', '/readers']);
    });

    test('администратору в нижней панели нужны выдачи и статистика', () {
      final split = splitForBottomBar(_itemsOf(Role.admin));
      expect(_paths(split.primary), ['/', '/books', '/loans', '/admin/stats']);
      expect(split.more, hasLength(5));
    });

    test('если разделов не больше пяти, «Ещё» не нужен', () {
      final items = _itemsOf(Role.reader).take(5).toList();
      final split = splitForBottomBar(items);
      expect(split.primary, hasLength(5));
      expect(split.more, isEmpty);
    });

    test('в нижней панели всегда пять мест: четыре раздела и «Ещё»', () {
      for (final role in Role.values) {
        final split = splitForBottomBar(_itemsOf(role));
        expect(split.primary.length + 1, 5, reason: role.label);
        expect(split.more, isNotEmpty, reason: role.label);
      }
    });
  });

  group('Выбранный раздел меню', () {
    final items = _itemsOf(Role.admin);

    test('вложенные адреса относятся к своему разделу', () {
      expect(items[selectedNavIndex(items, '/books')!].label, 'Книги');
      expect(items[selectedNavIndex(items, '/books/12')!].label, 'Книги');
      expect(items[selectedNavIndex(items, '/books/12/edit')!].label, 'Книги');
      expect(items[selectedNavIndex(items, '/admin/users')!].label, 'Пользователи');
    });

    test('главная выбирается только по точному адресу', () {
      expect(items[selectedNavIndex(items, '/')!].label, 'Главная');
      expect(selectedNavIndex(items, '/nothing'), isNull);
    });

    test('похожее начало адреса не считается совпадением', () {
      expect(selectedNavIndex(items, '/booksearch'), isNull);
      expect(selectedNavIndex(items, '/forbidden'), isNull);
    });
  });
}
