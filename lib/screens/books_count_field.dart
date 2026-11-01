import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/book_repository.dart';
import '../widgets/detail_layout.dart';

class BooksCountField extends StatelessWidget {
  const BooksCountField({super.key, required this.count, required this.booksLocation});

  final Future<int> Function(BookRepository books) count;
  final String booksLocation;

  @override
  Widget build(BuildContext context) {
    final books = context.read<BookRepository>();
    return DetailField(
      label: 'Книги',
      child: FutureBuilder<int>(
        future: count(books),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('…');
          final value = snapshot.data!;
          return Row(
            children: [
              Text(value == 0 ? 'Нет книг' : 'Книг: $value'),
              if (value > 0) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => context.go(booksLocation),
                  child: const Text('Показать в списке'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
