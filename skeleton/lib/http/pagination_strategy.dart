import 'package:skeleton/skeleton.dart';

/// Strategy for different pagination types (Offset vs Cursor).
abstract class PaginationStrategy<Model, Filter> {
  Future<PaginationResponse<Model>> getPage({
    required BaseApiService<Model, dynamic, Filter> api,
    required int page,
    required Filter filter,
  });
}

class OffsetPaginationStrategy<Model, Filter> implements PaginationStrategy<Model, Filter> {
  @override
  Future<PaginationResponse<Model>> getPage({
    required BaseApiService<Model, dynamic, Filter> api,
    required int page,
    required Filter filter,
  }) async {
    return (await Core.get<ExceptionHandler>().handle(api.paging(page: page, request: filter)))!;
  }
}

class CursorPaginationStrategy<Model, Filter> implements PaginationStrategy<Model, Filter> {
  final String cursorField;
  
  CursorPaginationStrategy({this.cursorField = 'cursor'});

  @override
  Future<PaginationResponse<Model>> getPage({
    required BaseApiService<Model, dynamic, Filter> api,
    required int page,
    required Filter filter,
  }) async {
    // Logic to extract cursor from filter and call a custom paging method if needed,
    // or use standard paging if the backend handles cursor via the filter object.
    return (await Core.get<ExceptionHandler>().handle(api.paging(page: page, request: filter)))!;
  }
}
