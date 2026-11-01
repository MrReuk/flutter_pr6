import '../models/genre.dart';
import '../models/simple_query.dart';
import 'api_repository.dart';
import 'book_repository.dart';
import 'entity_repository.dart';

class ApiGenreRepository extends ApiRepository<Genre, SimpleQuery> implements GenreRepository {
  ApiGenreRepository({required super.dio, required this.books})
    : super(resource: 'genres', cacheAll: true);

  final BookRepository books;

  @override
  Genre fromJson(Map<String, dynamic> json) => Genre.fromJson(json);

  @override
  Map<String, dynamic> toBody(Genre item) => item.toJson();

  @override
  int idOf(Genre item) => item.id;

  @override
  Map<String, dynamic> queryOf(SimpleQuery query) => pagingQuery(
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
    final count = await books.countByGenre(id, includeDeleted: true);
    if (count == 0) return null;
    final item = await findById(id);
    return 'Нельзя удалить навсегда жанр «${item?.name ?? '№$id'}»: он указан в книгах ($count). Сначала уберите его из этих книг.';
  }
}
