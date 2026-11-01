import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/json_helpers.dart';
import 'api_repository.dart';
import 'book_repository.dart';

class ApiBookRepository extends ApiRepository<Book, BookQuery> implements BookRepository {
  ApiBookRepository({required super.dio}) : super(resource: 'books');

  @override
  Book fromJson(Map<String, dynamic> json) => Book.fromJson(json);

  @override
  Map<String, dynamic> toBody(Book item) => item.toJson();

  @override
  int idOf(Book item) => item.id;

  @override
  Map<String, dynamic> queryOf(BookQuery query) {
    return {
      ...pagingQuery(
        search: query.search,
        sortField: query.sortField,
        sortAscending: query.sortAscending,
        page: query.page,
        size: query.size,
        includeDeleted: query.includeDeleted,
      ),
      if (query.genreId != null) 'genreId': query.genreId,
      if (query.publisherId != null) 'publisherId': query.publisherId,
      if (query.yearFrom != null) 'yearFrom': query.yearFrom,
      if (query.yearTo != null) 'yearTo': query.yearTo,
      if (query.onlyAvailable) 'available': 'true',
    };
  }

  Future<int> _count(Map<String, dynamic> filter, bool includeDeleted) {
    return guard(() async {
      final response = await dio.get<dynamic>(
        '/$resource',
        queryParameters: {...filter, 'size': 1, if (includeDeleted) 'includeDeleted': 'true'},
      );
      return jsonInt(jsonMap(response.data)['total']);
    });
  }

  @override
  Future<int> countByPublisher(int publisherId, {bool includeDeleted = false}) =>
      _count({'publisherId': publisherId}, includeDeleted);

  @override
  Future<int> countByGenre(int genreId, {bool includeDeleted = false}) =>
      _count({'genreId': genreId}, includeDeleted);

  @override
  Future<int> countByAuthor(int authorId, {bool includeDeleted = false}) =>
      _count({'authorId': authorId}, includeDeleted);
}
