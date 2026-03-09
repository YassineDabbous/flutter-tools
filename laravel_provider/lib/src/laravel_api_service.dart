import 'package:dio/dio.dart';
import 'package:skeleton/skeleton.dart';
import 'package:laravel_provider/laravel_provider.dart';
import 'package:laravel_provider/src/advanced_requests.dart';
import 'laravel_response.dart';

/// Base class for Laravel service implementations.
/// Provides a standard way to handle async requests and map errors.
///
/// ID type defaults to [int] for Laravel.
abstract class LaravelApiService<Model, EditRequest, SearchRequest, ID>
    implements BaseApiService<Model, EditRequest, SearchRequest, ID> {
  final Dio dio;
  final String? baseUrl;

  LaravelApiService(this.dio, {this.baseUrl});

  /// The Laravel resource type (e.g., 'user', 'shipment').
  /// Used for constructed ActionRequests.
  String get resourceType; // => 'general';

  String get endpoint;

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

  /// Convert Request to JSON - must be implemented by concrete service
  Map<String, dynamic> requestToJson(EditRequest request);

  @override
  Future<ApiResponse<Model>> show({
    required ID id,
    SearchRequest? params,
    String? suffixPath,
  }) async {
    return handle(() async {
      final path = suffixPath != null
          ? '/$endpoint/$id/$suffixPath'
          : '/$endpoint/$id';
      final result = await superRequestTransform(
        dio: dio,
        path: path,
        method: 'GET',
        baseUrl: baseUrl,
        fieldsAndFiles: {},
        queryParameters: params is Jsonable ? params.toJson() : null,
      );
      return BasicResponse<Model>.fromJson(
        result.data!,
        (json) => modelFromJson(json as Map<String, dynamic>),
      );
    });
  }

  @override
  Future<ApiResponse<List<Model>>> all({
    required SearchRequest request,
    String? suffixPath,
  }) async {
    return handle(() async {
      final path = suffixPath != null ? '/$endpoint/$suffixPath' : '/$endpoint';
      final result = await superRequestTransform(
        dio: dio,
        path: path,
        method: 'GET',
        baseUrl: baseUrl,
        fieldsAndFiles: {},
        queryParameters: request is Jsonable ? request.toJson() : null,
      );
      return ListResponse<Model>.fromJson(
        result.data!,
        (json) => modelFromJson(json as Map<String, dynamic>),
      );
    });
  }

  @override
  Future<ApiResponse<PaginatedResponse<Model>>> paging({
    required int page,
    required SearchRequest request,
    String? suffixPath,
  }) async {
    return handle(() async {
      final path = suffixPath != null ? '/$endpoint/$suffixPath' : '/$endpoint';
      final query = request is Jsonable
          ? request.toJson()
          : <String, dynamic>{};
      query['page'] = page;

      final result = await superRequestTransform(
        dio: dio,
        path: path,
        method: 'GET',
        baseUrl: baseUrl,
        fieldsAndFiles: {},
        queryParameters: query,
      );

      // We wrap the pagination response in a BasicResponse to satisfy the ApiResponse requirement
      return BasicResponse<PaginatedResponse<Model>>(
        data: LaravelPaginationResponse<Model>.fromJson(
          result.data!,
          (json) => modelFromJson(json as Map<String, dynamic>),
        ),
      );
    });
  }

  @override
  Future<ApiResponse<ID>> create({
    required EditRequest request,
    String? suffixPath,
  }) async {
    return handle(() async {
      final path = suffixPath != null ? '/$endpoint/$suffixPath' : '/$endpoint';
      final result = await superRequestTransform(
        dio: dio,
        path: path,
        method: 'POST',
        baseUrl: baseUrl,
        fieldsAndFiles: requestToJson(request),
      );
      // Laravel often returns the ID or the whole model
      final data = result.data!['data'];
      final id = (data is Map ? data['id'] : data) as ID;
      return ApiResponse(data: id);
    });
  }

  @override
  Future<ApiResponse<ID>> update({
    required ID id,
    required EditRequest request,
    String? suffixPath,
  }) async {
    return handle(() async {
      final path = suffixPath != null
          ? '/$endpoint/$id/$suffixPath'
          : '/$endpoint/$id';
      await superRequestTransform(
        dio: dio,
        path: path,
        method: 'PUT',
        baseUrl: baseUrl,
        fieldsAndFiles: requestToJson(request),
      );
      return ApiResponse(data: id);
    });
  }

  @override
  Future<ApiResponse<ID>> delete({
    required ID id,
    SearchRequest? params,
    String? suffixPath,
  }) async {
    return handle(() async {
      final path = suffixPath != null
          ? '/$endpoint/$id/$suffixPath'
          : '/$endpoint/$id';
      await superRequestTransform(
        dio: dio,
        path: path,
        method: 'DELETE',
        baseUrl: baseUrl,
        fieldsAndFiles: {},
      );
      return ApiResponse(data: id);
    });
  }

  @override
  Future<ApiResponse> manageRelations({
    required ID id,
    required dynamic request,
  }) async {
    return handle(() async {
      final result = await superRequestTransform(
        dio: dio,
        path: '/$endpoint/$id/relations',
        method: 'POST',
        baseUrl: baseUrl,
        fieldsAndFiles: request is Jsonable
            ? request.toJson()
            : request as Map<String, dynamic>,
      );
      return ApiResponse(data: result.data);
    });
  }

  @override
  Stream<List<Model>> stream({required SearchRequest request}) {
    throw UnimplementedError('Streaming not supported for Laravel yet');
  }

  @override
  Future<ApiResponse<T>> callFunction<T>(
    String name, {
    Map<String, dynamic>? params,
  }) async {
    return handle(() async {
      final request = ActionRequest(
        action: name,
        type: resourceType,
        payload: params,
      );

      final result = await superRequestTransform(
        dio: dio,
        path: '/_action_',
        fieldsAndFiles: request.toJson(),
        method: 'POST',
        baseUrl: baseUrl,
      );

      return BasicResponse<T>.fromJson(result.data!, (json) => json as T);
    });
  }

  // Common implementation patterns for Laravel can be added here
}
