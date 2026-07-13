import 'package:skeleton/skeleton.dart';

/// Strategy for different pagination types (Offset vs Cursor).
abstract class PaginationStrategy<Model, Filter> {
  Future<PaginatedResponse<Model>> getPage({
    required BaseApiService<Model, dynamic, Filter, dynamic> api,
    required int page,
    required Filter filter,
  });
}

class OffsetPaginationStrategy<Model, Filter>
    implements PaginationStrategy<Model, Filter> {
  @override
  Future<PaginatedResponse<Model>> getPage({
    required BaseApiService<Model, dynamic, Filter, dynamic> api,
    required int page,
    required Filter filter,
  }) async {
    return (await api.paging(page: page, params: filter)).data!;
  }
}

class CursorPaginationStrategy<Model, Filter>
    implements PaginationStrategy<Model, Filter> {
  final String cursorField;

  CursorPaginationStrategy({this.cursorField = 'cursor'});

  @override
  Future<PaginatedResponse<Model>> getPage({
    required BaseApiService<Model, dynamic, Filter, dynamic> api,
    required int page,
    required Filter filter,
  }) async {
    return (await api.paging(page: page, params: filter)).data!;
  }
}
