import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/app.dart';
import 'package:library_app/widgets/state_views.dart';

import 'app_harness.dart';
import 'test_helpers.dart';

void main() {
  group('Повтор запроса при потере связи', () {
    testWidgets('с автоповтором запрос уходит снова через каждый интервал', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Сервер недоступен',
              onRetry: () => retries++,
              autoRetryEvery: const Duration(seconds: 5),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('auto-retry-note')), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(retries, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(retries, 1);
      await tester.pump(const Duration(seconds: 10));
      expect(retries, 3);
    });

    testWidgets('без автоповтора запрос уходит только по кнопке', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(message: 'Ошибка сервера', onRetry: () => retries++),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('auto-retry-note')), findsNothing);
      await tester.pump(const Duration(seconds: 30));
      expect(retries, 0);

      await tester.tap(find.text('Повторить'));
      expect(retries, 1);
    });

    testWidgets('после возвращения сервера список загружается сам, без перезагрузки страницы', (
      tester,
    ) async {
      useLargeScreen(tester);
      final server = FakeServer();
      final repos = await signedIn(tester, server);
      server.down = true;

      await tester.pumpWidget(LibraryApp(repositories: repos, initialLocation: '/books'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Не удалось загрузить список'), findsOneWidget);
      expect(find.byKey(const ValueKey('auto-retry-note')), findsOneWidget);
      expect(find.text('Идиот'), findsNothing);

      // Связь появилась. Кнопку никто не нажимает.
      server.down = false;
      await tester.pump(kAutoRetryInterval + const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Идиот'), findsWidgets);
      expect(find.byKey(const ValueKey('auto-retry-note')), findsNothing);
    });

    testWidgets('ответ с ошибкой сервера не запускает автоповтор', (tester) async {
      useLargeScreen(tester);
      final server = FakeServer();
      final repos = await signedIn(tester, server);
      server.malformed = true;

      await tester.pumpWidget(LibraryApp(repositories: repos, initialLocation: '/books'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Не удалось загрузить список'), findsOneWidget);
      expect(find.byKey(const ValueKey('auto-retry-note')), findsNothing);
    });
  });
}
