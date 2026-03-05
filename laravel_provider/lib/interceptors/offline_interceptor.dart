import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:core/core.dart';

class OfflineQueuedException implements Exception {
  final int queueSize;
  OfflineQueuedException({required this.queueSize});
  @override
  String toString() => 'Request queued (Queue size: $queueSize)';
}

class OfflineQueueInterceptor extends Interceptor {
  final ListQueue<RequestOptions> _pendingRequests = ListQueue();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final hasConnection = await Core.get<NetworkInfo>().isConnected;

    if (hasConnection) {
      handler.next(options);
    } else if (_isMutating(options.method)) {
      _pendingRequests.add(options);
      handler.reject(DioException(
        requestOptions: options,
        error: OfflineQueuedException(queueSize: _pendingRequests.length),
      ));
    } else {
      handler.next(options);
    }
  }

  bool _isMutating(String method) {
    return {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(method.toUpperCase());
  }

  Future<void> flush(Dio dio) async {
    if (_pendingRequests.isEmpty) return;
    
    while (_pendingRequests.isNotEmpty) {
      final req = _pendingRequests.removeFirst();
      try {
        await dio.fetch(req);
      } catch (e) {
        _pendingRequests.addFirst(req);
        break;
      }
    }
  }
}
