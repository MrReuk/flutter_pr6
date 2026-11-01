import '../models/reader.dart';
import '../models/simple_query.dart';
import 'api_repository.dart';
import 'entity_repository.dart';

class ApiReaderRepository extends ApiRepository<Reader, SimpleQuery> implements ReaderRepository {
  ApiReaderRepository({required super.dio}) : super(resource: 'readers');

  @override
  Reader fromJson(Map<String, dynamic> json) => Reader.fromJson(json);

  @override
  Map<String, dynamic> toBody(Reader item) => item.toJson();

  @override
  int idOf(Reader item) => item.id;

  @override
  Map<String, dynamic> queryOf(SimpleQuery query) => pagingQuery(
    search: query.search,
    sortField: query.sortField,
    sortAscending: query.sortAscending,
    page: query.page,
    size: query.size,
    includeDeleted: query.includeDeleted,
  );
}
