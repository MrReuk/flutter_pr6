import '../models/author.dart';
import '../models/author_query.dart';
import 'api_repository.dart';
import 'author_repository.dart';
import 'book_repository.dart';

class ApiAuthorRepository extends ApiRepository<Author, AuthorQuery> implements AuthorRepository {
  ApiAuthorRepository({required super.dio, required this.books})
    : super(resource: 'authors', cacheAll: true);

  final BookRepository books;

  @override
  Author fromJson(Map<String, dynamic> json) => Author.fromJson(json);

  @override
  Map<String, dynamic> toBody(Author item) => item.toJson();

  @override
  int idOf(Author item) => item.id;

  @override
  Map<String, dynamic> queryOf(AuthorQuery query) => pagingQuery(
    search: query.search,
    sortField: query.sortField,
    sortAscending: query.sortAscending,
    page: query.page,
    size: query.size,
    includeDeleted: query.includeDeleted,
  );

  @override
  Future<String?> deleteBlocker(int id, {required bool permanent}) async {
    if (!permanent) return null;
    final count = await books.countByAuthor(id, includeDeleted: true);
    if (count == 0) return null;
    final item = await findById(id);
    return 'Нельзя удалить навсегда автора «${item?.fullName ?? '№$id'}»: он указан в книгах ($count). Сначала уберите его из этих книг.';
  }
}
