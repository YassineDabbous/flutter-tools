import 'package:dio/dio.dart';
import 'package:skeleton/skeleton.dart';
import 'package:laravel_provider/laravel_provider.dart';
import 'package:core/core.dart';

import 'advanced_requests.dart';

/// Base class for Laravel service implementations.
/// Provides a standard way to handle async requests and map errors.
///
/// URL model:
/// - [resource] is the bare noun used as default CRUD prefix (e.g. 'addresses').
/// - [pathSegments] are prepended before [resource] (e.g. ['customer']).
/// - [suffixPath] in any method is appended after [resource] (or replaces it
///   when it starts with '/' for absolute paths, or starts with '../' for
///   cross-prefix jumps).
/// - [persona] is an optional convenience that defaults [pathSegments] to
///   `[persona!]`.
///
/// ID type defaults to [int] for Laravel.
abstract class LaravelApiService<Model, ID>
    implements BaseApiService<Model, Map<String, dynamic>, Map<String, dynamic>, ID> {
  final Dio dio;
  final String? baseUrl;
  final String? persona;

  LaravelApiService(this.dio, {this.baseUrl, this.persona});

  /// Bare resource noun used as default URL prefix for CRUD verbs.
  /// e.g. 'addresses', 'finance', 'subscriptions'.
  String get resource;

  /// Segments prepended before [resource] / [suffixPath]. e.g. ['customer'].
  /// Defaults to `[persona!]` when [persona] is provided.
  List<String> get pathSegments =>
      persona != null ? [persona!] : const [];

  /// Resource noun used by [callFunction] for the `type` field of ActionRequest.
  /// Defaults to [resource].
  String get resourceType => resource;

  /// Helper to catch exceptions and map them to Failures.
  Future<T> handle<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw LaravelErrorMapper.map(e);
    }
  }

  /// Convert JSON to Model - must be implemented by concrete service
  Model modelFromJson(Map<String, dynamic> json);

  BasicResponse<Model> basicFromJson(Map<String, dynamic> json) =>
      BasicResponse<Model>.fromJson(
        json,
        (p0) => modelFromJson(p0 as Map<String, dynamic>),
      );

  FullListResponse<Model> listFromJson(Map<String, dynamic> json) =>
      FullListResponse<Model>.fromJson(
        json,
        (p0) => modelFromJson(p0 as Map<String, dynamic>),
      );

  PaginationResponse<Model> pageFromJson(Map<String, dynamic> json) =>
      PaginationResponse<Model>.fromJson(
        json,
        (p0) => modelFromJson(p0 as Map<String, dynamic>),
      );

  /// Convert Request to JSON - must be implemented by concrete service.
  /// Concrete services typically return the map as-is since the default
  /// [EditRequest] type is [Map].
  Map<String, dynamic> requestToJson(Map<String, dynamic> request);

  /// Compose the request URL from [pathSegments] + [resource] (+ [suffixPath]).
  ///
  /// Three modes:
  /// - [suffixPath] starting with '/' → absolute, [pathSegments] skipped.
  /// - [suffixPath] starting with '../' → cross-prefix, pops one segment then
  ///   appends the remainder.
  /// - Otherwise → normal: [pathSegments] + [resource] (+ [suffixPath]).
  String _buildPath({String? suffixPath, String? resourceOverride}) {
    if (suffixPath != null && suffixPath.startsWith('/')) {
      return suffixPath;
    }

    if (suffixPath != null && suffixPath.startsWith('../')) {
      if (pathSegments.isEmpty) {
        throw ArgumentError(
          '"../" requires at least one pathSegment '
          '(got pathSegments=$pathSegments, suffixPath=$suffixPath)',
        );
      }
      final popped = [...pathSegments]..removeLast();
      return '/${[...popped, ...suffixPath.substring(3).split('/')].join('/')}';
    }

    final segs = <String>[
      ...pathSegments,
      if (resourceOverride != null) resourceOverride else resource,
      if (suffixPath != null) ...suffixPath.split('/'),
    ];
    return '/${segs.where((s) => s.isNotEmpty).join('/')}';
  }

  /// Generic request and response transformer.
  ///
  /// [suffixPath] modes: see [_buildPath].
  Future<X> request<X>({
    String method = 'GET',
    String? suffixPath,
    Map<String, dynamic>? body,
    Map<String, dynamic>? params,
    required X Function(Map<String, dynamic>) fromJsonT,
  }) async {
    return handle(() async {
      final result = await superRequestTransform(
        dio: dio,
        path: _buildPath(suffixPath: suffixPath),
        method: method,
        baseUrl: baseUrl,
        fieldsAndFiles: body,
        queryParameters: params,
      );
      _throwOnErrorEnvelope(result.data, result.statusCode);
      return fromJsonT(result.data!);
    });
  }

  /// Some Laravel APIs return an error envelope (`{"error": "..."}`) even
  /// with a 2xx status. Treat it as a failure instead of parsing it as
  /// success (which would silently produce empty/null payloads).
  void _throwOnErrorEnvelope(Map<String, dynamic>? data, int? statusCode) {
    final error = data?['error'];
    if (error is String && error.trim().isNotEmpty) {
      throw statusCode == 404 ? NotFoundFailure(error) : ServerFailure(error);
    }
  }

  @override
  Future<ApiResponse<Model>> show({
    required ID id,
    Map<String, dynamic>? params,
    String? suffixPath,
  }) async {
    return request<ApiResponse<Model>>(
      suffixPath: suffixPath != null ? '/$id/$suffixPath' : '/$id',
      params: params,
      fromJsonT: basicFromJson,
    );
  }

  @override
  Future<ApiResponse<List<Model>>> all({
    Map<String, dynamic>? params,
    String? suffixPath,
  }) async {
    return request<ApiResponse<List<Model>>>(
      suffixPath: suffixPath,
      params: params,
      fromJsonT: listFromJson,
    );
  }

  @override
  Future<PaginationResponse<Model>> paging({
    required int page,
    Map<String, dynamic>? params,
    String? suffixPath,
  }) async {
    final query = params ?? <String, dynamic>{};
    query['page'] = page;
    return request<PaginationResponse<Model>>(
      suffixPath: suffixPath,
      params: query,
      fromJsonT: pageFromJson,
    );
  }

  @override
  Future<ApiResponse<ID>> create({
    required Map<String, dynamic> body,
    String? suffixPath,
  }) {
    return request<ApiResponse<ID>>(
      method: 'POST',
      suffixPath: suffixPath,
      body: requestToJson(body),
      fromJsonT: (p0) {
        final data = p0['data'];
        final id = (data is Map ? data['id'] : data) as ID;
        return ApiResponse(data: id);
      },
    );
  }

  @override
  Future<ApiResponse<ID>> update({
    required ID id,
    required Map<String, dynamic> body,
    String? suffixPath,
  }) async {
    return request<ApiResponse<ID>>(
      method: 'PUT',
      suffixPath: suffixPath != null ? '/$id/$suffixPath' : '/$id',
      body: requestToJson(body),
      fromJsonT: (p0) => ApiResponse(data: id),
    );
  }

  @override
  Future<ApiResponse<ID>> delete({
    required ID id,
    Map<String, dynamic>? params,
    String? suffixPath,
  }) async {
    return request<ApiResponse<ID>>(
      method: 'DELETE',
      suffixPath: suffixPath != null ? '/$id/$suffixPath' : '/$id',
      params: params,
      fromJsonT: (p0) => ApiResponse(data: id),
    );
  }

  @override
  Future<ApiResponse> manageRelations({
    required ID id,
    required dynamic data,
  }) async {
    return request<ApiResponse>(
      method: 'POST',
      suffixPath: '/$id/relations',
      body: data is Jsonable ? data.toJson() : data as Map<String, dynamic>,
      fromJsonT: (p0) => ApiResponse(data: p0),
    );
  }

  @override
  Stream<List<Model>> stream({required Map<String, dynamic> data}) {
    throw UnimplementedError('Streaming not supported for Laravel yet');
  }

  @override
  Future<ApiResponse<T>> callFunction<T>(
    String name, {
    Map<String, dynamic>? params,
  }) async {
    return handle(() async {
      final body = ActionRequest(
        action: name,
        type: resourceType,
        payload: params,
      );

      final result = await superRequestTransform(
        dio: dio,
        path: _buildPath(suffixPath: '/_action_'),
        fieldsAndFiles: body.toJson(),
        method: 'POST',
        baseUrl: baseUrl,
      );

      _throwOnErrorEnvelope(result.data, result.statusCode);
      return BasicResponse<T>.fromJson(result.data!, (json) => json as T);
    });
  }

  // Common implementation patterns for Laravel can be added here
}
