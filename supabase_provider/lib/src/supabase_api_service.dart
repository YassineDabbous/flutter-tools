import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeleton/skeleton.dart';
import 'package:core/core.dart';

/// Base class for Supabase service implementations.
/// 
/// [ID] is typically [String] (UUID) for Supabase, but can be [int].
abstract class SupabaseApiService<Model, EditRequest, SearchRequest, ID> implements BaseApiService<Model, EditRequest, SearchRequest, ID> {
  final SupabaseClient client;
  final String table;

  SupabaseApiService(this.client, this.table);

  /// Helper to catch Supabase exceptions and map them to unified Failures.
  Future<T> handle<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      if (e is PostgrestException) {
        if (e.code == '42501') throw const PermissionFailure();
        if (e.code == '23505') throw ValidationFailure(errors: {'db': e.message});
        if (e.code == 'PGRST116') throw const NotFoundFailure();
        throw ServerFailure(e.message);
      }
      if (e is AuthException) throw const AuthFailure();
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ApiResponse<Model>> show({required ID id, SearchRequest? params}) async {
    return handle(() async {
      final response = await client.from(table).select().eq('id', id as Object).single();
      return ApiResponse(data: modelFromJson(response));
    });
  }

  @override
  Future<ApiResponse<ID>> create(EditRequest request) async {
    return handle(() async {
      final response = await client.from(table).insert(requestToJson(request)).select('id').single();
      return ApiResponse(data: response['id'] as ID);
    });
  }

  @override
  Future<ApiResponse<ID>> delete({required ID id, SearchRequest? params}) async {
    return handle(() async {
      await client.from(table).delete().eq('id', id as Object);
      return ApiResponse(data: id);
    });
  }

  @override
  Future<ApiResponse<ID>> update({required ID id, required EditRequest request}) async {
    return handle(() async {
      await client.from(table).update(requestToJson(request)).eq('id', id as Object);
      return ApiResponse(data: id);
    });
  }

  /// Convert JSON to Model - must be implemented by concrete service
  Model modelFromJson(Map<String, dynamic> json);

  /// Convert Request to JSON - must be implemented by concrete service
  Map<String, dynamic> requestToJson(EditRequest request);

  @override
  Future<ApiResponse<PaginatedResponse<Model>>> paging({required int page, required SearchRequest request}) async {
    // Basic implementation for Supabase pagination can be added here
    throw UnimplementedError('Supabase paging implementation needed based on project needs');
  }

  @override
  Future<ApiResponse<PaginatedResponse<Model>>> pagingCustomPath({
    required String path,
    required int page,
    required SearchRequest request,
  }) async {
    throw UnimplementedError('Supabase custom path paging not supported yet');
  }

  @override
  Future<ApiResponse> manageRelations({required ID id, required dynamic request}) async {
    throw UnimplementedError('Relationship management not implemented for Supabase yet');
  }
}
