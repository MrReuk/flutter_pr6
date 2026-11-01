import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/widgets/deferred_screen.dart';

Widget _app(DeferredScreen screen) => MaterialApp(home: screen);

void main() {
  testWidgets('пока раздел загружается, виден индикатор, затем сам экран', (tester) async {
    final loading = Completer<void>();
    await tester.pumpWidget(
      _app(
        DeferredScreen(
          title: 'Раздел',
          load: () => loading.future,
          builder: (_) => const Scaffold(body: Text('Раздел готов')),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Раздел готов'), findsNothing);

    loading.complete();
    await tester.pump();
    await tester.pump();

    expect(find.text('Раздел готов'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('сбой загрузки показывает ошибку, повтор открывает раздел', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _app(
        DeferredScreen(
          title: 'Раздел',
          load: () async {
            attempts++;
            if (attempts == 1) throw Exception('нет сети');
          },
          builder: (_) => const Scaffold(body: Text('Раздел готов')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Не удалось загрузить раздел'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('Раздел готов'), findsOneWidget);
  });

  testWidgets('библиотека запрашивается один раз, перерисовка её не перезагружает', (tester) async {
    var attempts = 0;
    final screen = DeferredScreen(
      title: 'Раздел',
      load: () async => attempts++,
      builder: (_) => const Scaffold(body: Text('Раздел готов')),
    );
    await tester.pumpWidget(_app(screen));
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(_app(screen));
    await tester.pump();

    expect(attempts, 1);
  });
}
