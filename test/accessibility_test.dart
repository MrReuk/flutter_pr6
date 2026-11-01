import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/app.dart';

import 'app_harness.dart';
import 'test_helpers.dart';

Future<void> _open(
  WidgetTester tester,
  FakeServer server, {
  required Size size,
  String? user = 'admin',
  String location = '/',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repos = await signedIn(tester, server, user: user);
  await tester.pumpWidget(LibraryApp(repositories: repos, initialLocation: location));
  await tester.pumpAndSettle();
}

EditableText _field(WidgetTester tester, String key) {
  return tester.widget<EditableText>(
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText)),
  );
}

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  group('Подсказки у значков без подписи', () {
    const places = {
      'главная': '/',
      'книги': '/books',
      'авторы': '/authors',
      'выдачи': '/loans',
      'пользователи': '/admin/users',
      'форма книги': '/books/new',
    };

    for (final place in places.entries) {
      for (final size in const [Size(360, 740), Size(1280, 800)]) {
        testWidgets('${place.key}, ${size.width.toInt()}: у каждой кнопки-значка есть подсказка', (
          tester,
        ) async {
          await _open(tester, server, size: size, location: place.value);

          final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
          for (final button in buttons) {
            expect(button.tooltip, isNotNull, reason: 'кнопка ${button.icon} без подсказки');
            expect(button.tooltip, isNotEmpty);
          }
        });
      }
    }

    testWidgets('кнопка показа пароля подписана и меняет подпись', (tester) async {
      await _open(tester, server, size: const Size(1280, 800), user: null, location: '/login');

      expect(find.byTooltip('Показать пароль'), findsOneWidget);
      await tester.tap(find.byTooltip('Показать пароль'));
      await tester.pump();
      expect(find.byTooltip('Скрыть пароль'), findsOneWidget);
    });
  });

  group('Управление с клавиатуры', () {
    testWidgets('в форме входа курсор сразу в логине, Tab ведёт к паролю, Shift+Tab обратно', (
      tester,
    ) async {
      await _open(tester, server, size: const Size(1280, 800), user: null, location: '/login');

      expect(_field(tester, 'login-username').focusNode.hasFocus, isTrue);
      expect(_field(tester, 'login-password').focusNode.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_field(tester, 'login-username').focusNode.hasFocus, isFalse);
      expect(_field(tester, 'login-password').focusNode.hasFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(_field(tester, 'login-username').focusNode.hasFocus, isTrue);
    });

    testWidgets('форму входа можно отправить клавишей Enter из поля пароля', (tester) async {
      await _open(tester, server, size: const Size(1280, 800), user: null, location: '/login');

      await tester.enterText(find.byKey(const ValueKey('login-username')), 'reader');
      await tester.enterText(find.byKey(const ValueKey('login-password')), 'reader123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Здравствуйте, Смирнов П. А.!'), findsOneWidget);
    });
  });
}
