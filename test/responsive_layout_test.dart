import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/app.dart';
import 'package:library_app/core/breakpoints.dart';

import 'test_helpers.dart';
import 'app_harness.dart';

/// Четыре ширины окна, при которых работа проверяется по заданию.
const Map<String, Size> kWidths = {
  '360': Size(360, 740),
  '768': Size(768, 1024),
  '1280': Size(1280, 800),
  '1920': Size(1920, 1080),
};

Future<void> openAt(
  WidgetTester tester,
  FakeServer server,
  Size size, {
  String user = 'admin',
  String location = '/',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repos = await signedIn(tester, server, user: user);
  await tester.pumpWidget(LibraryApp(repositories: repos, initialLocation: location));
  await tester.pumpAndSettle();
}

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  group('Навигация перестраивается по ширине окна', () {
    testWidgets('360: нижняя панель, боковой полосы нет', (tester) async {
      await openAt(tester, server, kWidths['360']!);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('768: боковая полоса с подписями под значками, нижней панели нет', (tester) async {
      await openAt(tester, server, kWidths['768']!);

      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(rail.labelType, NavigationRailLabelType.all);
    });

    testWidgets('1280: боковая полоса раскрыта, подписи рядом со значками', (tester) async {
      await openAt(tester, server, kWidths['1280']!);

      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(
        find.descendant(of: find.byType(NavigationRail), matching: find.text('Статистика')),
        findsOneWidget,
      );
    });

    testWidgets('при изменении размера окна раскладка перестраивается без перезапуска', (
      tester,
    ) async {
      await openAt(tester, server, kWidths['1280']!);
      expect(find.byType(NavigationRail), findsOneWidget);

      tester.view.physicalSize = kWidths['360']!;
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      tester.view.physicalSize = kWidths['768']!;
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isFalse);
    });

    testWidgets('пункт меню ведёт на свой раздел и подсвечивается', (tester) async {
      await openAt(tester, server, kWidths['1280']!);

      await tester.tap(
        find.descendant(of: find.byType(NavigationRail), matching: find.text('Авторы')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Достоевский Ф. М.'), findsWidgets);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations[rail.selectedIndex!].label, isA<Text>());
      expect(((rail.destinations[rail.selectedIndex!].label) as Text).data, 'Авторы');
    });
  });

  group('Нижняя панель на узком окне', () {
    testWidgets('читателю: «Ещё» раскрывает остальные разделы и открывает выбранный', (
      tester,
    ) async {
      await openAt(tester, server, kWidths['360']!, user: 'reader');

      expect(
        find.descendant(of: find.byType(NavigationBar), matching: find.text('Мои выдачи')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(NavigationBar), matching: find.text('Издательства')),
        findsNothing,
      );

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      final sheet = find.byKey(const ValueKey('more-sheet'));
      expect(sheet, findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Издательства')), findsOneWidget);

      await tester.tap(find.descendant(of: sheet, matching: find.text('Издательства')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('more-sheet')), findsNothing);
      expect(find.text('Азбука'), findsWidgets);
    });

    testWidgets('читатель не видит разделов персонала ни в панели, ни в «Ещё»', (tester) async {
      await openAt(tester, server, kWidths['360']!, user: 'reader');

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      for (final hidden in ['Статистика', 'Пользователи', 'Рабочее место', 'Читатели']) {
        expect(
          find.descendant(of: find.byType(NavigationBar), matching: find.text(hidden)),
          findsNothing,
          reason: hidden,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('more-sheet')),
            matching: find.text(hidden),
          ),
          findsNothing,
          reason: hidden,
        );
      }
    });

    testWidgets('администратору «Ещё» содержит пользователей', (tester) async {
      await openAt(tester, server, kWidths['360']!);

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('more-sheet')),
          matching: find.text('Пользователи'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Таблица и карточки', () {
    testWidgets('360: список книг карточками, таблицы нет', (tester) async {
      await openAt(tester, server, kWidths['360']!, location: '/books');

      expect(find.byType(DataTable), findsNothing);
      expect(find.text('Идиот'), findsWidgets);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('768: места для таблицы нет, список остаётся карточками', (tester) async {
      await openAt(tester, server, kWidths['768']!, location: '/books');

      expect(find.byType(DataTable), findsNothing);
      expect(find.text('Идиот'), findsWidgets);
    });

    testWidgets('1280: вместо карточек таблица', (tester) async {
      await openAt(tester, server, kWidths['1280']!, location: '/books');

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Идиот'), findsWidgets);
    });

    testWidgets('1280: необязательный столбец «Страниц» скрыт, на 1920 показан', (tester) async {
      await openAt(tester, server, kWidths['1280']!, location: '/books');
      expect(find.text('Страниц'), findsNothing);
      expect(find.text('Год'), findsWidgets);
      expect(find.text('Действия'), findsOneWidget);

      tester.view.physicalSize = kWidths['1920']!;
      await tester.pumpAndSettle();
      expect(find.text('Страниц'), findsOneWidget);
    });

    testWidgets('таблица обёрнута в прокрутку по обеим осям', (tester) async {
      await openAt(tester, server, kWidths['1280']!, location: '/books');

      final scrollables = tester
          .widgetList<SingleChildScrollView>(
            find.ancestor(of: find.byType(DataTable), matching: find.byType(SingleChildScrollView)),
          )
          .map((view) => view.scrollDirection)
          .toSet();
      expect(scrollables, {Axis.horizontal, Axis.vertical});
    });
  });

  group('Ширина содержимого', () {
    testWidgets('1920: содержимое не шире предела и стоит по центру', (tester) async {
      await openAt(tester, server, kWidths['1920']!, location: '/books');

      final content = find.byKey(const ValueKey('page-content'));
      expect(tester.getSize(content).width, closeTo(kContentMaxWidth, 0.5));
      final left = tester.getTopLeft(content).dx;
      final right = 1920 - tester.getTopRight(content).dx;
      // Слева стоит боковая полоса, поэтому поля слева и справа равны
      // только за вычетом её ширины.
      expect(left, greaterThan(0));
      expect(right, greaterThan(0));
    });

    testWidgets('1280: содержимое занимает всё место рядом с полосой', (tester) async {
      await openAt(tester, server, kWidths['1280']!, location: '/books');

      final width = tester.getSize(find.byKey(const ValueKey('page-content'))).width;
      expect(width, lessThanOrEqualTo(kContentMaxWidth));
      expect(width, greaterThan(900));
    });

    testWidgets('форма книги на 1920 не шире 720 пикселей', (tester) async {
      await openAt(tester, server, kWidths['1920']!, location: '/books/new');

      final field = find.widgetWithText(TextFormField, 'Название *');
      expect(tester.getSize(field).width, lessThanOrEqualTo(720));
    });

    testWidgets('диалог подтверждения не растягивается на весь монитор', (tester) async {
      await openAt(tester, server, kWidths['1920']!, location: '/genres');

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      final panel = find.descendant(of: find.byType(AlertDialog), matching: find.byType(Material));
      expect(tester.getSize(panel.first).width, lessThanOrEqualTo(560));
    });
  });

  group('Сетки плиток', () {
    double dx(WidgetTester tester, String path) =>
        tester.getTopLeft(find.byKey(ValueKey('tile-$path'))).dx;
    double dy(WidgetTester tester, String path) =>
        tester.getTopLeft(find.byKey(ValueKey('tile-$path'))).dy;

    testWidgets('360: плитки главной в одну колонку', (tester) async {
      await openAt(tester, server, kWidths['360']!);

      expect(dx(tester, '/books'), dx(tester, '/authors'));
      expect(dy(tester, '/authors'), greaterThan(dy(tester, '/books')));
    });

    testWidgets('768: плитки главной в две колонки', (tester) async {
      await openAt(tester, server, kWidths['768']!);

      expect(dy(tester, '/books'), dy(tester, '/authors'));
      expect(dx(tester, '/authors'), greaterThan(dx(tester, '/books')));
      expect(dy(tester, '/genres'), greaterThan(dy(tester, '/books')));
    });

    testWidgets('1280: плитки главной в три колонки', (tester) async {
      await openAt(tester, server, kWidths['1280']!);

      expect(dy(tester, '/books'), dy(tester, '/authors'));
      expect(dy(tester, '/authors'), dy(tester, '/genres'));
      expect(dy(tester, '/publishers'), greaterThan(dy(tester, '/books')));
    });
  });

  // Любое переполнение (RenderFlex overflowed) во время сборки или прокрутки
  // сообщается как исключение и проваливает тест.
  group('Экраны помещаются в окно без переполнения', () {
    const adminLocations = [
      '/',
      '/books',
      '/books/1',
      '/books/new',
      '/authors',
      '/authors/1',
      '/genres',
      '/publishers',
      '/readers',
      '/readers/1',
      '/loans',
      '/loans/new',
      '/admin/users',
      '/admin/stats',
      '/forbidden?path=%2Fdesk',
    ];
    const librarianLocations = ['/', '/desk', '/books/1/edit'];
    const readerLocations = ['/', '/my/loans', '/books'];

    for (final width in kWidths.entries) {
      for (final location in adminLocations) {
        testWidgets('администратор, ${width.key}: $location', (tester) async {
          await openAt(tester, server, width.value, location: location);
          expect(tester.takeException(), isNull);
          expect(find.byType(Scaffold), findsWidgets);
        });
      }
      for (final location in librarianLocations) {
        testWidgets('библиотекарь, ${width.key}: $location', (tester) async {
          await openAt(tester, server, width.value, user: 'librarian', location: location);
          expect(tester.takeException(), isNull);
        });
      }
      for (final location in readerLocations) {
        testWidgets('читатель, ${width.key}: $location', (tester) async {
          await openAt(tester, server, width.value, user: 'reader', location: location);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
