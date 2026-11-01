import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../widgets/detail_layout.dart';
import 'books_count_field.dart';
import 'entity_detail_screen.dart';

class PublisherDetailScreen extends StatelessWidget {
  const PublisherDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntityDetailScreen<Publisher>(
      title: 'Карточка издательства',
      listPath: '/publishers',
      listLabel: 'К списку издательств',
      notFoundMessage: 'Издательство не найдено',
      editLocation: (publisher) => '/publishers/${publisher.id}/edit',
      nameOf: (publisher) => publisher.name,
      isDeleted: (publisher) => publisher.isDeleted,
      fields: (context, publisher) => [
        DetailField(label: 'Город', child: Text(publisher.city.isEmpty ? '—' : publisher.city)),
        DetailField(
          label: 'Год основания',
          child: Text(publisher.foundedYear == null ? '—' : '${publisher.foundedYear}'),
        ),
        BooksCountField(
          count: (books) => books.countByPublisher(publisher.id),
          booksLocation: '/books?publisherId=${publisher.id}',
        ),
      ],
    );
  }
}
