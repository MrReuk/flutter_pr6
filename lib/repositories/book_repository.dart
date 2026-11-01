import '../models/book.dart';
import '../models/book_query.dart';
import 'entity_repository.dart';

abstract interface class BookRepository implements EntityRepository<Book, BookQuery> {
  Future<int> countByPublisher(int publisherId, {bool includeDeleted = false});
  Future<int> countByGenre(int genreId, {bool includeDeleted = false});
  Future<int> countByAuthor(int authorId, {bool includeDeleted = false});
}
