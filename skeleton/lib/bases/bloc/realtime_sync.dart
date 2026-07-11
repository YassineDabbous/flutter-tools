import 'dart:async';
import 'package:skeleton/skeleton.dart';

/// Mixin for real-time synchronization of Cubit state.
mixin RealtimeSync<
  ApiType extends BaseApiService,
  BaseState extends MyBaseState
>
    on MyBaseBloc<ApiType, BaseState> {
  StreamSubscription? _syncSubscription;

  /// Starts listening to a stream of updates.
  void startSync<T>(Stream<T> stream, void Function(T event) onUpdate) {
    _syncSubscription?.cancel();
    _syncSubscription = stream.listen(onUpdate);
  }

  /// Stops listening to updates.
  void stopSync() {
    _syncSubscription?.cancel();
    _syncSubscription = null;
  }

  @override
  Future<void> close() {
    stopSync();
    return super.close();
  }
}
