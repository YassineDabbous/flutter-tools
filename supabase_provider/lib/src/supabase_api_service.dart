import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:skeleton/skeleton.dart';
import 'package:core/core.dart';

/// Base class for Supabase service implementations.
///
/// [ID] is typically [String] (UUID) for Supabase, but can be [int].
abstract class SupabaseApiService<Model, EditRequest, SearchRequest, ID>
    implements BaseApiService<Model, EditRequest, SearchRequest, ID> {
  final sb.SupabaseClient client;
  final String table;

  SupabaseApiService(this.client, this.table);

  /// Helper to catch Supabase exceptions and map them to unified Failures.
  Future<T> handle<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      if (e is sb.PostgrestException) {
        if (e.code == '42501') throw const PermissionFailure();
        if (e.code == '23505') {
          throw ValidationFailure(errors: {'db': e.message});
        }
        if (e.code == 'PGRST116') throw const NotFoundFailure();
        throw ServerFailure(e.message);
      }
      if (e is sb.AuthException) throw const AuthFailure();
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ApiResponse<Model>> show({
    required ID id,
    SearchRequest? params,
    String? suffixPath,
  }) async {
    return handle(() async {
      final response = await client
          .from(table)
          .select()
          .eq('id', id as Object)
          .single();
      return ApiResponse(data: modelFromJson(response));
    });
  }

  @override
  Future<ApiResponse<ID>> create({
    required EditRequest body,
    String? suffixPath,
  }) async {
    return handle(() async {
      final response = await client
          .from(table)
          .insert(requestToJson(body))
          .select('id')
          .single();
      return ApiResponse(data: response['id'] as ID);
    });
  }

  @override
  Future<ApiResponse<ID>> delete({
    required ID id,
    SearchRequest? params,
    String? suffixPath,
  }) async {
    return handle(() async {
      await client.from(table).delete().eq('id', id as Object);
      return ApiResponse(data: id);
    });
  }

  @override
  Future<ApiResponse<ID>> update({
    required ID id,
    required EditRequest body,
    String? suffixPath,
  }) async {
    return handle(() async {
      await client
          .from(table)
          .update(requestToJson(body))
          .eq('id', id as Object);
      return ApiResponse(data: id);
    });
  }

  /// Convert JSON to Model - must be implemented by concrete service
  Model modelFromJson(Map<String, dynamic> json);

  /// Convert Request to JSON - must be implemented by concrete service
  Map<String, dynamic> requestToJson(EditRequest request);

  /// Applies DynamicQueryRequest filters to a Postgrest query.
  dynamic _buildQuery(dynamic query, SearchRequest? params) {
    if (params == null || params is! DynamicQueryRequest) return query;
    final request = params as DynamicQueryRequest;

    var q = query;

    // Apply Filters
    if (request.operators != null) {
      request.operators!.forEach((field, operator) {
        final val = request.toJson()[field];
        // Skip if value is null
        if (val == null) return;

        switch (operator) {
          case 'eq':
          case '=':
            q = q.eq(field, val);
            break;
          case 'neq':
          case '!=':
            q = q.neq(field, val);
            break;
          case 'gt':
          case '>':
            q = q.gt(field, val);
            break;
          case 'lt':
          case '<':
            q = q.lt(field, val);
            break;
          case 'like':
            q = q.like(field, '%$val%');
            break;
          case 'ilike':
            q = q.ilike(field, '%$val%');
            break;
          default:
            q = q.eq(field, val);
        }
      });
    }

    // Apply Sorting
    if (request.sort != null) {
      for (final s in request.sort!) {
        final ascending = !s.startsWith('-');
        final column = ascending ? s : s.substring(1);
        q = q.order(column, ascending: ascending);
      }
    }

    // Apply Limit
    if (request.limit != null) {
      q = q.limit(request.limit!);
    }

    return q;
  }

  String _buildSelect(SearchRequest? params) {
    if (params == null || params is! DynamicQueryRequest) return '*';
    final request = params as DynamicQueryRequest;

    String selectStr = request.fields?.join(',') ?? '*';
    if (request.includes != null && request.includes!.isNotEmpty) {
      for (final inc in request.includes!) {
        selectStr += ',$inc(*)';
      }
    }
    return selectStr;
  }

  @override
  Future<ApiResponse<List<Model>>> all({
    SearchRequest? params,
    String? suffixPath,
  }) async {
    return handle(() async {
      final selectStr = _buildSelect(params);
      var query = client.from(table).select(selectStr);
      query = _buildQuery(query, params);
      final response = await query;
      final List<Model> data = (response as List)
          .map((json) => modelFromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse(data: data);
    });
  }

  @override
  Future<ApiResponse<PaginatedList<Model>>> paging({
    required int page,
    SearchRequest? params,
    String? suffixPath,
  }) async {
    return handle(() async {
      final selectStr = _buildSelect(params);
      final perPage = (params is DynamicQueryRequest)
          ? (params as DynamicQueryRequest).perPage ?? 15
          : 15;

      final from = (page - 1) * perPage;
      final to = from + perPage - 1;

      // Use .count() method instead of select parameter for wider version compatibility
      final dynamic baseQuery = client.from(table).select(selectStr);
      final dynamic query = _buildQuery(
        baseQuery.count(sb.CountOption.exact),
        params,
      );

      final dynamic response = await query.range(from, to);

      // In newer Supabase versions, response might be the data list or a PostgrestResponse
      final List<dynamic> listData = response is List
          ? response
          : (response as dynamic).data;
      final int count = response is List
          ? listData.length
          : (response as dynamic).count ?? listData.length;

      final List<Model> data = listData
          .map((json) => modelFromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        data: PaginatedList(
          data: data,
          total: count,
          perPage: perPage,
          currentPage: page,
        ),
      );
    });
  }

  @override
  Future<ApiResponse> manageRelations({
    required ID id,
    required dynamic data,
  }) async {
    throw UnimplementedError(
      'Relationship management not implemented for Supabase yet',
    );
  }

  @override
  Stream<List<Model>> stream({required SearchRequest data}) {
    // Basic implementation for Supabase streaming
    // Note: Supabase streaming doesn't support complex filters directly yet in the same way as queries
    return client
        .from(table)
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => modelFromJson(json)).toList());
  }

  @override
  Future<ApiResponse<T>> callFunction<T>(
    String name, {
    Map<String, dynamic>? params,
  }) async {
    return handle(() async {
      final response = await client.rpc(name, params: params);
      return ApiResponse(data: response as T);
    });
  }
}
