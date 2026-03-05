// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laravel_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BasicResponse<T> _$BasicResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => BasicResponse<T>(
  code: (json['code'] as num?)?.toInt(),
  message: json['message'] as String?,
  error: json['error'] as String?,
  validation: json['validation'] as Map<String, dynamic>?,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
);

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

LaravelPaginationResponse<T> _$LaravelPaginationResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => LaravelPaginationResponse<T>(
  data: (json['data'] as List<dynamic>).map(fromJsonT).toList(),
  total: (json['total'] as num).toInt(),
  perPage: (json['perPage'] as num).toInt(),
  currentPage: (json['currentPage'] as num).toInt(),
);
