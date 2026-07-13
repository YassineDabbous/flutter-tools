import 'package:dio/dio.dart';
import 'package:skeleton/skeleton.dart';
import 'package:laravel_provider/laravel_provider.dart';

/// Base class for Laravel service implementations.
/// Provides a standard way to handle async requests and map errors.
///
/// ID type defaults to [int] for Laravel.
abstract class LaravelApiService<Model, EditRequest, SearchRequest, ID> implements BaseApiService<Model, EditRequest, SearchRequest, ID> {
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

  BasicResponse<Model> basicFromJson(Map<String, dynamic> json) => BasicResponse<Model>.fromJson(json, (p0) => modelFromJson(p0 as Map<String, dynamic>));
  
  ListResponse<Model> listFromJson(Map<String, dynamic> json) => ListResponse<Model>.fromJson(json, (p0) => modelFromJson(p0 as Map<String, dynamic>));
  
  PaginationResponse<Model> pageFromJson(Map<String, dynamic> json) => PaginationResponse<Model>.fromJson(json, (p0) => modelFromJson(p0 as Map<String, dynamic>));

  /// Convert Request to JSON - must be implemented by concrete service
  Map<String, dynamic> requestToJson(EditRequest request);


  /// Generic request and response transformer
  Future<X> request<X>({String method = 'GET', String? suffixPath, Map<String, dynamic>? body, Map<String, dynamic>? params, required X Function(Map<String, dynamic>) fromJsonT}) async {
    return handle(() async {
      final path = suffixPath != null ? '/$endpoint/$suffixPath' : '/$endpoint';
      final result = await superRequestTransform(dio: dio, path: path, method: method, baseUrl: baseUrl, fieldsAndFiles: body, queryParameters: params);
      return fromJsonT(result.data!);
    });
  }

  @override
  Future<ApiResponse<Model>> show({required ID id, SearchRequest? params, String? suffixPath}) async {
    return request<ApiResponse<Model>>(
      suffixPath: suffixPath != null ? '/$id/$suffixPath' : '/$id',
      params: params is Jsonable ? params.toJson() : null,
      fromJsonT: basicFromJson,
    );
  }

  @override
  Future<ApiResponse<List<Model>>> all({SearchRequest? params, String? suffixPath}) async {
    return request<ApiResponse<List<Model>>>(
      suffixPath: suffixPath,
      params: params is Jsonable ? params.toJson() : null,
      fromJsonT: listFromJson,
    );
  }

  @override
  Future<PaginationResponse<Model>> paging({required int page, SearchRequest? params, String? suffixPath}) async {
    final query = params is Jsonable ? params.toJson() : <String, dynamic>{};
    query['page'] = page;
    return request<PaginationResponse<Model>>(
      suffixPath: suffixPath,
      params: query,
      // We wrap the pagination response in a BasicResponse to satisfy the ApiResponse requirement
      fromJsonT: pageFromJson,
    );
  }

  @override
  Future<ApiResponse<ID>> create({required EditRequest body, String? suffixPath}) async {
    return handle(() async {
      final path = suffixPath != null ? '/$endpoint/$suffixPath' : '/$endpoint';
      final result = await superRequestTransform(dio: dio, path: path, method: 'POST', baseUrl: baseUrl, fieldsAndFiles: requestToJson(body));
      // Laravel often returns the ID or the whole model
      final data = result.data!['data'];
      final id = (data is Map ? data['id'] : data) as ID;
      return ApiResponse(data: id);
    });
  }

  @override
  Future<ApiResponse<ID>> update({required ID id, required EditRequest body, String? suffixPath}) async {
    return request<ApiResponse<ID>>(
      method: 'PUT',
      suffixPath: suffixPath != null ? '/$id/$suffixPath' : '/$id',
      body: requestToJson(body),
      fromJsonT: (p0) => ApiResponse(data: id),
    );
  }

  @override
  Future<ApiResponse<ID>> delete({required ID id, SearchRequest? params, String? suffixPath}) async {
    return request<ApiResponse<ID>>(
      method: 'DELETE',
      suffixPath: suffixPath != null ? '/$id/$suffixPath' : '/$id',
      params: params is Jsonable ? params.toJson() : null,
      fromJsonT: (p0) => ApiResponse(data: id),
    );
  }

  @override
  Future<ApiResponse> manageRelations({required ID id, required dynamic data}) async {
    return request<ApiResponse>(
      method: 'POST',
      suffixPath: '/$id/relations',
      body: data is Jsonable ? data.toJson() : data as Map<String, dynamic>,
      fromJsonT: (p0) => ApiResponse(data: p0),
    );
  }

  @override
  Stream<List<Model>> stream({required SearchRequest data}) {
    throw UnimplementedError('Streaming not supported for Laravel yet');
  }

  @override
  Future<ApiResponse<T>> callFunction<T>(String name, {Map<String, dynamic>? params}) async {
    return handle(() async {
      final body = ActionRequest(action: name, type: resourceType, payload: params);

      final result = await superRequestTransform(dio: dio, path: '/_action_', fieldsAndFiles: body.toJson(), method: 'POST', baseUrl: baseUrl);

      return BasicResponse<T>.fromJson(result.data!, (json) => json as T);
    });
  }

  // Common implementation patterns for Laravel can be added here
}
