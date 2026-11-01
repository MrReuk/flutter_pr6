import '../models/publisher.dart';
import '../models/simple_query.dart';
import 'api_repository.dart';
import 'book_repository.dart';
import 'entity_repository.dart';

class ApiPublisherRepository extends ApiRepository<Publisher, SimpleQuery>
    implements PublisherRepository {
  ApiPublisherRepository({required super.dio, required this.books})
    : super(resource: 'publishers', cacheAll: true);

  final BookRepository books;

  @override
  Publisher fromJson(Map<String, dynamic> json) => Publisher.fromJson(json);

  @override
  Map<String, dynamic> toBody(Publisher item) => item.toJson();

  @override
  int idOf(Publisher item) => item.id;

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
    final count = await books.countByPublisher(id, includeDeleted: permanent);
    if (count == 0) return null;
    final item = await findById(id);
    return 'Нельзя удалить издательство «${item?.name ?? '№$id'}»: у него есть книги ($count). Сначала измените издательство у этих книг или удалите их.';
  }
}
