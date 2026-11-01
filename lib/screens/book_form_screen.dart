import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../state/reference_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import 'entity_form_screen.dart';

class BookFormScreen extends StatelessWidget {
  const BookFormScreen({super.key, this.bookId});

  final int? bookId;

  @override
  Widget build(BuildContext context) {
    final books = context.read<BookRepository>();
    final refs = context.read<ReferenceNotifier>();
    final id = bookId;

    return EntityFormScreen<Book>(
      title: id == null ? 'Новая книга' : 'Редактирование книги',
      backPath: '/books',
      notFoundMessage: 'Книга не найдена',
      savedMessage: id == null ? 'Книга добавлена' : 'Изменения сохранены',
      needsRefs: true,
      needsLinks: true,
      loadItem: id == null ? null : () => books.findById(id),
      initialValues: (book) => {
        'title': book?.title ?? '',
        'isbn': book?.isbn ?? '',
        'year': book == null ? '' : '${book.year}',
        'pages': book == null ? '' : '${book.pages}',
        'publisherId': book?.publisherId,
        'authorIds': book?.authorIds ?? <int>[],
        'genreIds': book?.genreIds ?? <int>[],
        'copiesTotal': book == null ? '' : '${book.copiesTotal}',
      },
      fields: (book) => [
        FieldSpec.text(
          key: 'title',
          label: 'Название',
          required: true,
          maxLength: 150,
          validator: checks([notBlank(), minLength(2), maxLength(150)]),
        ),
        FieldSpec.text(
          key: 'isbn',
          label: 'ISBN',
          required: true,
          hint: '978-5-17-123456-0',
          validator: checks([notBlank(), isbnFormat()]),
        ),
        FieldSpec.text(
          key: 'year',
          label: 'Год издания',
          required: true,
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
          validator: checks([notBlank(), integerInRange(1450, DateTime.now().year)]),
        ),
        FieldSpec.text(
          key: 'pages',
          label: 'Количество страниц',
          required: true,
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
          validator: checks([notBlank(), positiveInteger(max: 10000)]),
        ),
        FieldSpec.dropdown(
          key: 'publisherId',
          label: 'Издательство',
          required: true,
          validator: mustChoose('Выберите издательство'),
          options: (values) => refs.publisherOptions(keep: [if (book != null) book.publisherId]),
        ),
        FieldSpec.multi(
          key: 'authorIds',
          label: 'Авторы',
          required: true,
          validator: mustChooseAtLeastOne('Выберите хотя бы одного автора'),
          options: (values) => refs.authorOptions(keep: book?.authorIds ?? const []),
          narrowed: (values) => refs.authorOptionsForPublisher(
            values['publisherId'] as int?,
            keep: book?.authorIds ?? const [],
          ),
          narrowedSwitchLabel: 'Показать всех авторов',
          narrowedHint: 'Показаны авторы, у которых уже есть книги этого издательства',
        ),
        FieldSpec.multi(
          key: 'genreIds',
          label: 'Жанры',
          required: true,
          validator: mustChooseAtLeastOne('Выберите хотя бы один жанр'),
          options: (values) => refs.genreOptions(keep: book?.genreIds ?? const []),
        ),
        FieldSpec.text(
          key: 'copiesTotal',
          label: 'Всего экземпляров',
          required: true,
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
          validator: checks([notBlank(), positiveInteger(max: 1000)]),
        ),
      ],
      save: (values, existing) async {
        final draft = Book(
          id: existing?.id ?? 0,
          title: (values['title'] as String).trim(),
          isbn: (values['isbn'] as String).trim(),
          year: int.parse((values['year'] as String).trim()),
          pages: int.parse((values['pages'] as String).trim()),
          publisherId: values['publisherId'] as int,
          authorIds: List<int>.of(values['authorIds'] as List<int>),
          genreIds: List<int>.of(values['genreIds'] as List<int>),
          copiesTotal: int.parse((values['copiesTotal'] as String).trim()),
          deletedAt: existing?.deletedAt,
        );
        if (existing == null) {
          await books.create(draft);
        } else {
          await books.update(draft);
        }
      },
    );
  }
}
