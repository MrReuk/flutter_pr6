import 'package:flutter/material.dart';

import '../models/genre.dart';
import '../models/simple_query.dart';
import '../widgets/entity_table.dart';
import 'simple_list_screen.dart';

class GenreListScreen extends StatelessWidget {
  const GenreListScreen({super.key, required this.query});

  final SimpleQuery query;

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Genre>(
      query: query,
      config: SimpleListConfig<Genre>(
        title: 'Жанры',
        path: '/genres',
        searchLabel: 'Поиск по названию или описанию',
        emptyMessage: 'Жанры не найдены. Измените поиск или фильтры.',
        addLabel: 'Добавить жанр',
        columns: (context) => [
          TableColumnSpec<Genre>(label: 'Название', sortField: 'name', build: (g) => Text(g.name)),
          TableColumnSpec<Genre>(
            label: 'Описание',
            build: (g) => CellText(g.description.isEmpty ? '—' : g.description, maxWidth: 480),
          ),
        ],
        idOf: (g) => g.id,
        isDeleted: (g) => g.isDeleted,
        nameOf: (g) => g.name,
        subtitleOf: (g) => g.description.isEmpty ? 'Без описания' : g.description,
      ),
    );
  }
}
