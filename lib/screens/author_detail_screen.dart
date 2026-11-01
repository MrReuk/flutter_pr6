import 'package:flutter/material.dart';

import '../models/author.dart';
import '../widgets/detail_layout.dart';
import 'entity_detail_screen.dart';

class AuthorDetailScreen extends StatelessWidget {
  const AuthorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntityDetailScreen<Author>(
      title: 'Карточка автора',
      listPath: '/authors',
      listLabel: 'К списку авторов',
      notFoundMessage: 'Автор не найден',
      editLocation: (author) => '/authors/${author.id}/edit',
      nameOf: (author) => author.fullName,
      isDeleted: (author) => author.isDeleted,
      fields: (context, author) => [
        DetailField(label: 'Страна', child: Text(author.country.isEmpty ? '—' : author.country)),
        DetailField(
          label: 'Год рождения',
          child: Text(author.birthYear == null ? '—' : '${author.birthYear}'),
        ),
      ],
    );
  }
}
