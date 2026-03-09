import 'package:skeleton/skeleton.dart';

/// A decorator that adds a local caching layer to any [BaseApiService].
class CachingApiService<M, E, S, ID> implements BaseApiService<M, E, S, ID> {
  final BaseApiService<M, E, S, ID> _remote;

  /// Simple in-memory cache.
  /// @TODO: Replace with a more robust implementation like Hive or custom storage if needed.
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _expiry = {};

  final Duration ttl;

  CachingApiService(this._remote, {this.ttl = const Duration(minutes: 5)});

  String _cacheKey(String method, dynamic id, S? params) {
    String paramStr = '';
    if (params is Jsonable) {
      final json = params.toJson();
      // Sort keys for stable toString
      final sortedKeys = json.keys.toList()..sort();
      paramStr = sortedKeys.map((k) => '$k:${json[k]}').join(',');
    } else {
      paramStr = params?.toString() ?? '';
    }
    return '${M.runtimeType}:$method:$id:$paramStr';
  }

  bool _isExpired(String key) {
    final exp = _expiry[key];
    if (exp == null) return true;
    return DateTime.now().isAfter(exp);
  }

  @override
  Future<ApiResponse<M>> show({required ID id, S? params}) async {
    final key = _cacheKey('show', id, params);
    if (_cache.containsKey(key) && !_isExpired(key)) {
      return ApiResponse(data: _cache[key] as M);
    }

    final result = await _remote.show(id: id, params: params);
    if (result.data != null) {
      _cache[key] = result.data;
      _expiry[key] = DateTime.now().add(ttl);
    }
    return result;
  }

  @override
  Future<ApiResponse<PaginatedResponse<M>>> paging({
    required int page,
    required S request,
  }) async {
    // Paging results are usually too dynamic to cache simply,
    // but could be cached if path/request are identical.
    return _remote.paging(page: page, request: request);
  }

  @override
  Future<ApiResponse<ID>> create(E request) => _remote.create(request);

  @override
  Future<ApiResponse<ID>> update({required ID id, required E request}) {
    // Clear cache for this ID on update
    _cache.removeWhere(
      (key, _) => key.startsWith('${M.runtimeType}:show:$id:'),
    );
    return _remote.update(id: id, request: request);
  }

  @override
  Future<ApiResponse<ID>> delete({required ID id, S? params}) {
    // Clear cache for this ID on delete
    _cache.removeWhere(
      (key, _) => key.startsWith('${M.runtimeType}:show:$id:'),
    );
    return _remote.delete(id: id, params: params);
  }

  @override
  Future<ApiResponse<M>> showForEdit({required ID id, S? params}) =>
      _remote.showForEdit(id: id, params: params);

  @override
  Future<ApiResponse<List<M>>> all({required S request}) =>
      _remote.all(request: request);

  @override
  Future<ApiResponse<PaginatedResponse<M>>> pagingCustomPath({
    required String path,
    required int page,
    required S request,
  }) => _remote.pagingCustomPath(path: path, page: page, request: request);

  @override
  Future<ApiResponse<dynamic>> manageRelations({
    required ID id,
    required dynamic request,
  }) => _remote.manageRelations(id: id, request: request);

  @override
  Stream<List<M>> stream({required S request}) =>
      _remote.stream(request: request);

  @override
  Future<ApiResponse<T>> callFunction<T>(
    String name, {
    Map<String, dynamic>? params,
  }) => _remote.callFunction(name, params: params);

  /// Clears the entire in-memory cache.
  static void clearCache() {
    _cache.clear();
    _expiry.clear();
  }
}
