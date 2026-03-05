import 'package:dio/dio.dart';
import 'package:skeleton/skeleton.dart';
import 'advanced_requests.dart';
import 'laravel_response.dart';

/// Laravel-specific implementation of the action API service.
class LaravelActionApiService implements ActionApiService {
  final Dio _dio;
  String? baseUrl;

  LaravelActionApiService(this._dio, {this.baseUrl});

  @override
  Future<ApiResponse<dynamic>> handleAction(ActionRequest request) async {
    final result = await superRequestTransform(
      dio: _dio,
      path: '/_action_',
      fieldsAndFiles: request.toJson(),
      method: 'POST',
      baseUrl: baseUrl,
    );
    return BasicResponse<dynamic>.fromJson(
      result.data!,
      (json) => json as dynamic,
    );
  }

  @override
  Future<ApiResponse<dynamic>> create(dynamic request) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<dynamic>> delete({required dynamic id, dynamic params}) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<List<dynamic>>> all({required dynamic request}) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<PaginatedResponse<dynamic>>> paging({
    required int page,
    required dynamic request,
  }) => throw UnimplementedError();

  @override
  Future<ApiResponse<dynamic>> show({required dynamic id, dynamic params}) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<dynamic>> showForEdit({
    required dynamic id,
    dynamic params,
  }) => throw UnimplementedError();

  @override
  Future<ApiResponse<PaginatedResponse<dynamic>>> pagingCustomPath({
    required String path,
    required int page,
    required dynamic request,
  }) => throw UnimplementedError();

  @override
  Future<ApiResponse<dynamic>> manageRelations({
    required dynamic id,
    required dynamic request,
  }) => throw UnimplementedError();

  @override
  Future<ApiResponse<dynamic>> update({
    required dynamic id,
    required dynamic request,
  }) => throw UnimplementedError();
}
