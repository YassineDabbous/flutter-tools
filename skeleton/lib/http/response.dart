/// Generic response wrapper for API results.
class ApiResponse<T> {
  final T? data;
  final String? message;
  final dynamic error;

  ApiResponse({this.data, this.message, this.error});
}

/// Generic paginated response wrapper.
class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int perPage;
  final int currentPage;

  PaginatedResponse({
    required this.data,
    required this.total,
    required this.perPage,
    this.currentPage = 1,
  });

  int get lastPage => (total / perPage).ceil();
}
