import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/validation/validators.dart';
import 'package:library_app/widgets/entity_form.dart';

const _options = [(id: 1, name: 'Первый'), (id: 2, name: 'Второй'), (id: 3, name: 'Третий')];

List<FieldSpec> _fields() => [
  FieldSpec.text(
    key: 'name',
    label: 'Название',
    required: true,
    validator: checks([notBlank(), minLength(3)]),
  ),
  FieldSpec.text(
    key: 'year',
    label: 'Год',
    required: true,
    validator: checks([notBlank(), integerInRange(1900, 2026)]),
  ),
  FieldSpec.dropdown(
    key: 'choiceId',
    label: 'Выбор',
    required: true,
    validator: mustChoose('Выберите вариант'),
    options: (values) => _options,
  ),
  FieldSpec.multi(
    key: 'tagIds',
    label: 'Метки',
    required: true,
    validator: mustChooseAtLeastOne('Выберите хотя бы одну метку'),
    options: (values) => _options,
  ),
];

Future<void> _pumpForm(
  WidgetTester tester, {
  SubmitHandler? onSubmit,
  ValueChanged<bool>? onDirtyChanged,
  FormValues initialValues = const {},
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EntityForm(
          fields: _fields(),
          initialValues: initialValues,
          onSubmit: onSubmit ?? (values) async => const {},
          onDirtyChanged: onDirtyChanged ?? (_) {},
          onCancel: () {},
        ),
      ),
    ),
  );
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('Пустая отправка показывает ошибки сразу у нескольких полей', (tester) async {
    var submitted = false;
    await _pumpForm(
      tester,
      onSubmit: (values) async {
        submitted = true;
        return const {};
      },
    );

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Обязательное поле'), findsNWidgets(2));
    expect(find.text('Выберите вариант'), findsOneWidget);
    expect(find.text('Выберите хотя бы одну метку'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('Ошибки диапазона и длины показываются под полем', (tester) async {
    await _pumpForm(tester);

    await tester.enterText(_field('Название *'), 'ab');
    await tester.enterText(_field('Год *'), '1800');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Не короче 3 символов'), findsOneWidget);
    expect(find.text('Допустимо от 1900 до 2026'), findsOneWidget);
  });

  testWidgets('Корректная форма отправляется с введёнными значениями', (tester) async {
    FormValues? received;
    await _pumpForm(
      tester,
      onSubmit: (values) async {
        received = values;
        return const {};
      },
    );

    await tester.enterText(_field('Название *'), 'Тест');
    await tester.enterText(_field('Год *'), '2001');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Второй').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Первый'));
    await tester.tap(find.widgetWithText(FilterChip, 'Третий'));
    await tester.pump();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(received, isNotNull);
    expect(received!['name'], 'Тест');
    expect(received!['year'], '2001');
    expect(received!['choiceId'], 2);
    expect(received!['tagIds'], [1, 3]);
  });

  testWidgets('Ошибка сервера показывается под полем и пропадает при правке', (tester) async {
    await _pumpForm(
      tester,
      onSubmit: (values) async => {'name': 'Такое название уже есть'},
      initialValues: const {
        'name': 'Дубликат',
        'year': '2000',
        'choiceId': 1,
        'tagIds': [1],
      },
    );

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Такое название уже есть'), findsOneWidget);

    await tester.enterText(_field('Название *'), 'Другое название');
    await tester.pumpAndSettle();
    expect(find.text('Такое название уже есть'), findsNothing);
  });

  testWidgets('Форма сообщает, есть ли несохранённые изменения', (tester) async {
    final states = <bool>[];
    await _pumpForm(tester, onDirtyChanged: states.add, initialValues: const {'name': 'Исходное'});

    await tester.enterText(_field('Название *'), 'Исходное!');
    await tester.pump();
    expect(states, [true]);

    await tester.enterText(_field('Название *'), 'Исходное');
    await tester.pump();
    expect(states, [true, false]);

    await tester.tap(find.widgetWithText(FilterChip, 'Второй'));
    await tester.pump();
    expect(states, [true, false, true]);
  });
}
