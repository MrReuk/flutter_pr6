import 'package:flutter/widgets.dart';

import 'screens/author_form_screen.dart' deferred as author_form;
import 'screens/book_form_screen.dart' deferred as book_form;
import 'screens/desk_screen.dart' deferred as desk;
import 'screens/genre_form_screen.dart' deferred as genre_form;
import 'screens/loan_form_screen.dart' deferred as loan_form;
import 'screens/my_loans_screen.dart' deferred as my_loans;
import 'screens/publisher_form_screen.dart' deferred as publisher_form;
import 'screens/reader_form_screen.dart' deferred as reader_form;
import 'screens/stats_screen.dart' deferred as stats;
import 'screens/users_screen.dart' deferred as users;
import 'widgets/deferred_screen.dart';

/// Разделы, которые подгружаются отдельным файлом при первом открытии.
///
/// Здесь собраны все `deferred`-импорты приложения. Маршрутизатор получает
/// экраны через этот интерфейс и не знает, загружены они сразу или по требованию.
abstract class LazyScreens {
  const LazyScreens();

  Widget myLoansScreen();
  Widget deskScreen();
  Widget usersScreen();
  Widget statsScreen();
  Widget bookForm(int? id);
  Widget authorForm(int? id);
  Widget genreForm(int? id);
  Widget publisherForm(int? id);
  Widget readerForm(int? id);
  Widget loanForm();
}

/// Рабочий набор: каждый раздел скачивается при первом открытии. Пока файл
/// грузится, показывается индикатор; при сбое сети есть кнопка «Повторить».
class DeferredScreens extends LazyScreens {
  const DeferredScreens();

  @override
  Widget myLoansScreen() => DeferredScreen(
    title: 'Мои выдачи',
    load: my_loans.loadLibrary,
    builder: (context) => my_loans.MyLoansScreen(),
  );

  @override
  Widget deskScreen() => DeferredScreen(
    title: 'Рабочее место библиотекаря',
    load: desk.loadLibrary,
    builder: (context) => desk.DeskScreen(),
  );

  @override
  Widget usersScreen() => DeferredScreen(
    title: 'Пользователи и роли',
    load: users.loadLibrary,
    builder: (context) => users.UsersScreen(),
  );

  @override
  Widget statsScreen() => DeferredScreen(
    title: 'Статистика',
    load: stats.loadLibrary,
    builder: (context) => stats.StatsScreen(),
  );

  @override
  Widget bookForm(int? id) => DeferredScreen(
    title: 'Книга',
    load: book_form.loadLibrary,
    builder: (context) => book_form.BookFormScreen(bookId: id),
  );

  @override
  Widget authorForm(int? id) => DeferredScreen(
    title: 'Автор',
    load: author_form.loadLibrary,
    builder: (context) => author_form.AuthorFormScreen(authorId: id),
  );

  @override
  Widget genreForm(int? id) => DeferredScreen(
    title: 'Жанр',
    load: genre_form.loadLibrary,
    builder: (context) => genre_form.GenreFormScreen(genreId: id),
  );

  @override
  Widget publisherForm(int? id) => DeferredScreen(
    title: 'Издательство',
    load: publisher_form.loadLibrary,
    builder: (context) => publisher_form.PublisherFormScreen(publisherId: id),
  );

  @override
  Widget readerForm(int? id) => DeferredScreen(
    title: 'Читатель',
    load: reader_form.loadLibrary,
    builder: (context) => reader_form.ReaderFormScreen(readerId: id),
  );

  @override
  Widget loanForm() => DeferredScreen(
    title: 'Новая выдача',
    load: loan_form.loadLibrary,
    builder: (context) => loan_form.LoanFormScreen(),
  );
}

/// Подмена набора разделов. Нужна только тестам: тестовая машина Dart умеет
/// загрузить лишь одну отложенную библиотеку за запуск, поэтому тесты
/// подставляют набор с обычными импортами (test/flutter_test_config.dart).
@visibleForTesting
LazyScreens? lazyScreensOverride;

/// Набор разделов, которым пользуется маршрутизатор.
LazyScreens get lazyScreens => lazyScreensOverride ?? const DeferredScreens();
