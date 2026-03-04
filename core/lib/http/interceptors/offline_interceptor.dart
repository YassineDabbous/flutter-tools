import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:core/core.dart';

/// Exception thrown when a request is queued for offline processing.
class OfflineQueuedException implements Exception {
  final int queueSize;
  OfflineQueuedException({required this.queueSize});
  @override
  String toString() => 'Request queued (Queue size: $queueSize)';
}

/// Interceptor that queues mutating requests when offline and flushes them when online.
class OfflineQueueInterceptor extends Interceptor {
  final ListQueue<RequestOptions> _pendingRequests = ListQueue();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final hasConnection = await Core.get<NetworkInfo>().isConnected;

    if (hasConnection) {
      handler.next(options);
    } else if (_isMutating(options.method)) {
      logNet.warning('Offline: Queuing ${options.method} request to ${options.path}');
      _pendingRequests.add(options);
      handler.reject(DioException(
        requestOptions: options,
        error: OfflineQueuedException(queueSize: _pendingRequests.length),
      ));
    } else {
      // GET requests just fail as normal (or might be served from cache by another interceptor)
      handler.next(options);
    }
  }

  bool _isMutating(String method) {
    return {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(method.toUpperCase());
  }

  /// Flushes all queued requests. Should be called when connectivity is restored.
  Future<void> flush(Dio dio) async {
    if (_pendingRequests.isEmpty) return;
    
    logNet.info('Online: Flushing ${_pendingRequests.length} queued requests...');
    
    while (_pendingRequests.isNotEmpty) {
      final req = _pendingRequests.removeFirst();
      try {
        await dio.fetch(req);
      } catch (e) {
        logNet.error('Failed to flush request: $e. Re-queuing.');
        _pendingRequests.addFirst(req); // Re-queue at the front
        break; // Stop flushing if one fails (assume connection might be unstable again)
      }
    }
  }
}
