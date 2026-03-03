import 'package:core/http/app_path_provider.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';

/// Static class for configuring and managing HTTP caching.
abstract class Cache {
  /// The Hive store implementation for persistence.
  static final HiveCacheStore _store = HiveCacheStore(AppPathProvider.path);

  /// Global cache options applied to the Dio interceptor.
  static CacheOptions get cacheOptions => CacheOptions(
    store: _store,
    hitCacheOnErrorCodes: [401, 403], // Use cache if server returns auth error
    policy: CachePolicy.request,
    maxStale: const Duration(days: 1),
    priority: CachePriority.high,
    keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    allowPostMethod: false,
  );

  /// Clears the entire cache store.
  static Future<void> clear() => _store.clean();

  /// Clears cache entries with low priority or below.
  static Future<void> clearLowRequests() => _store.clean(priorityOrBelow: CachePriority.low);

  /// Options for requesting data with a 1-day stale maximum.
  static Options get daily => Cache.cacheOptions.copyWith(maxStale: const Duration(days: 1), priority: CachePriority.normal).toOptions();
}
