import 'package:flutter/widgets.dart';
import 'package:library_app/lazy_screens.dart';
import 'package:library_app/screens/author_form_screen.dart';
import 'package:library_app/screens/book_form_screen.dart';
import 'package:library_app/screens/desk_screen.dart';
import 'package:library_app/screens/genre_form_screen.dart';
import 'package:library_app/screens/loan_form_screen.dart';
import 'package:library_app/screens/my_loans_screen.dart';
import 'package:library_app/screens/publisher_form_screen.dart';
import 'package:library_app/screens/reader_form_screen.dart';
import 'package:library_app/screens/stats_screen.dart';
import 'package:library_app/screens/users_screen.dart';

/// Набор разделов для тестов: все экраны подключены обычными импортами.
class EagerScreens extends LazyScreens {
  const EagerScreens();

  @override
  Widget myLoansScreen() => const MyLoansScreen();

  @override
  Widget deskScreen() => const DeskScreen();

  @override
  Widget usersScreen() => const UsersScreen();

  @override
  Widget statsScreen() => const StatsScreen();

  @override
  Widget bookForm(int? id) => BookFormScreen(bookId: id);

  @override
  Widget authorForm(int? id) => AuthorFormScreen(authorId: id);

  @override
  Widget genreForm(int? id) => GenreFormScreen(genreId: id);

  @override
  Widget publisherForm(int? id) => PublisherFormScreen(publisherId: id);

  @override
  Widget readerForm(int? id) => ReaderFormScreen(readerId: id);

  @override
  Widget loanForm() => const LoanFormScreen();
}
