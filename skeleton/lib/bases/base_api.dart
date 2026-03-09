import 'package:skeleton/skeleton.dart';

/// Defines a standard interface for all API service classes, enforcing common CRUD operations.
/// This is a pure interface, backend-agnostic.
///
/// Type Parameters:
/// - [Model]: The data model representing the resource.
/// - [EditRequest]: The model used for Create/Update requests.
/// - [SearchRequest]: The model used for query and filtering parameters.
/// - [ID]: The type of the resource identifier (typically `int` or `String`).
abstract class BaseApiService<Model, EditRequest, SearchRequest, ID> {
  /// Retrieves a single resource by its ID.
  Future<ApiResponse<Model>> show({required ID id, SearchRequest? params});

  /// Retrieves a single resource for editing.
  Future<ApiResponse<Model>> showForEdit({
    required ID id,
    SearchRequest? params,
  });

  /// Gets all resources at once.
  Future<ApiResponse<List<Model>>> all({required SearchRequest request});

  /// Retrieves resources using pagination.
  Future<ApiResponse<PaginatedResponse<Model>>> paging({
    required int page,
    required SearchRequest request,
  });

  /// Deletes a resource by its ID.
  Future<ApiResponse<ID>> delete({required ID id, SearchRequest? params});

  /// Creates a new resource.
  Future<ApiResponse<ID>> create(EditRequest request);

  /// Updates an existing resource.
  Future<ApiResponse<ID>> update({
    required ID id,
    required EditRequest request,
  });

  /// Custom path paging (for admin or specialized endpoints).
  Future<ApiResponse<PaginatedResponse<Model>>> pagingCustomPath({
    required String path,
    required int page,
    required SearchRequest request,
  });

  /// Manage resource relationships.
  Future<ApiResponse> manageRelations({
    required ID id,
    required dynamic request,
  });

  /// Returns a live stream of data matching the search request.
  Stream<List<Model>> stream({required SearchRequest request});

  /// Executes a remote function/RPC call.
  Future<ApiResponse<T>> callFunction<T>(
    String name, {
    Map<String, dynamic>? params,
  });
}
