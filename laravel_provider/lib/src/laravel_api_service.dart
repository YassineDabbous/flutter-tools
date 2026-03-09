import 'package:dio/dio.dart';
import 'package:skeleton/skeleton.dart';
import '../mappers/error_mapper.dart';
import 'advanced_requests.dart';
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

  /// Helper to catch exceptions and map them to Failures.
  Future<T> handle<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw LaravelErrorMapper.map(e);
    }
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
