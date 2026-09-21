import 'package:skeleton/skeleton.dart';

class BasicResponse<T> extends ApiResponse<T> {
  final int? code;
  final Map<String, dynamic>? validation;

  BasicResponse({
    this.code,
    super.message,
    super.error,
    this.validation,
    super.data,
  });

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

class FullListResponse<T> extends BasicResponse<List<T>> {
  FullListResponse({super.data, super.message, super.error, super.code});

  factory FullListResponse.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    final map = json as Map<String, dynamic>;
    return FullListResponse<T>(
      data: map['data'] != null
          ? (map['data'] as List).map(fromJsonT).toList()
          : null,
      message: map['message'] as String?,
      error: map['error'] as String?,
    );
  }
}

class PaginationResponse<T> extends BasicResponse<LaravelPaginator<T>> {
  PaginationResponse({super.data, super.message, super.error, super.code});

  factory PaginationResponse.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    final map = json as Map<String, dynamic>;
    final paginatorMap =
        (map.containsKey('code') && map['data'] is Map<String, dynamic>)
        ? map['data'] as Map<String, dynamic>
        : map;
    return PaginationResponse<T>(
      data: LaravelPaginator.fromJson(paginatorMap, fromJsonT),
      message: map['message'] as String?,
      error: map['error'] as String?,
    );
  }
}

class LaravelPaginator<T> extends PaginatedList<T> {
  final int hasMore;

  LaravelPaginator({
    required super.data,
    required super.total,
    required super.perPage,
    required super.currentPage,
    this.hasMore = 0,
  });

  bool get hasMoreBool => hasMore != 0;

  static int _hasMoreFromJson(dynamic value) {
    if (value == null) return 0;
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value != 0 ? 1 : 0;
    final s = value.toString().toLowerCase().trim();
    if (s == '1' || s == 'true') return 1;
    return 0;
  }

  static int _intFromJson(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  factory LaravelPaginator.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    final map = json as Map<String, dynamic>;
    // Laravel pagination can be at root or under 'data'
    final dataList = (map['data'] as List).map(fromJsonT).toList();

    // Meta/Links might be separate or merged
    final meta = map['meta'] as Map<String, dynamic>? ?? map;

    return LaravelPaginator<T>(
      data: dataList,
      total: meta['total'] != null ? _intFromJson(meta['total']) : 0,
      perPage: meta['per_page'] != null ? _intFromJson(meta['per_page']) : 15,
      currentPage: meta['current_page'] != null
          ? _intFromJson(meta['current_page'])
          : 1,
      hasMore: _hasMoreFromJson(meta['has_more']),
    );
  }

  @override
  int get lastPage => perPage > 0 ? (total / perPage).ceil() : 1;
}
