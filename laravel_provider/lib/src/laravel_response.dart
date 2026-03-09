import 'package:skeleton/skeleton.dart';

class BasicResponse<T> extends ApiResponse<T> {
  final int? code;
  final Map<String, dynamic>? validation;

  BasicResponse({
    this.code,
    String? message,
    String? error,
    this.validation,
    T? data,
  }) : super(data: data, message: message, error: error);

  factory BasicResponse.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    final map = json as Map<String, dynamic>;
    return BasicResponse<T>(
      code: map['code'] as int?,
      message: map['message'] as String?,
      error: map['error'] as String?,
      validation: map['validation'] as Map<String, dynamic>?,
      data: map['data'] != null ? fromJsonT(map['data']) : null,
    );
  }
}

class LaravelPaginationResponse<T> extends PaginatedResponse<T> {
  LaravelPaginationResponse({
    required List<T> data,
    required int total,
    required int perPage,
    required int currentPage,
  }) : super(
         data: data,
         total: total,
         perPage: perPage,
         currentPage: currentPage,
       );

  factory LaravelPaginationResponse.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    final map = json as Map<String, dynamic>;
    // Laravel pagination can be at root or under 'data'
    final dataList = (map['data'] as List).map(fromJsonT).toList();

    // Meta/Links might be separate or merged
    final meta = map['meta'] as Map<String, dynamic>? ?? map;

    return LaravelPaginationResponse<T>(
      data: dataList,
      total: meta['total'] as int? ?? 0,
      perPage: meta['per_page'] as int? ?? 15,
      currentPage: meta['current_page'] as int? ?? 1,
    );
  }

  @override
  int get lastPage => perPage > 0 ? (total / perPage).ceil() : 1;
}

class ListResponse<T> extends ApiResponse<List<T>> {
  ListResponse({List<T>? data, String? message, String? error})
    : super(data: data, message: message, error: error);

  factory ListResponse.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    final map = json as Map<String, dynamic>;
    return ListResponse<T>(
      data: map['data'] != null
          ? (map['data'] as List).map(fromJsonT).toList()
          : null,
      message: map['message'] as String?,
      error: map['error'] as String?,
    );
  }
}
