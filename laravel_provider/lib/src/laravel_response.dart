import 'package:json_annotation/json_annotation.dart';
import 'package:skeleton/skeleton.dart';
part 'laravel_response.g.dart';

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class BasicResponse<T> implements ApiResponse<T> {
  final int? code;
  @override
  final String? message;
  @override
  final String? error;
  final Map<String, dynamic>? validation;
  @override
  final T? data;

  BasicResponse({
    this.code,
    this.message,
    this.error,
    this.validation,
    this.data,
  });

  factory BasicResponse.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    return _$BasicResponseFromJson(json!, fromJsonT);
  }
}

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class LaravelPaginationResponse<T> implements PaginatedResponse<T> {
  @override
  final List<T> data;
  @override
  final int total;
  @override
  final int perPage;
  @override
  final int currentPage;

  LaravelPaginationResponse({
    required this.data,
    required this.total,
    required this.perPage,
    required this.currentPage,
  });

  factory LaravelPaginationResponse.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    return _$LaravelPaginationResponseFromJson<T>(json, fromJsonT);
  }

  @override
  int get lastPage => (total / perPage).ceil();
}
