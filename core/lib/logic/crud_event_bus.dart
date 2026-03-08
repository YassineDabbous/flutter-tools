import 'dart:async';

/// Cross-cubit synchronization event.
class CrudEvent<T> {
  final CrudEventType type;
  final dynamic id;
  final T? data;
  CrudEvent({required this.type, this.id, this.data});
}

enum CrudEventType { created, updated, deleted }

/// A simple global event bus for CRUD operations.
class CrudEventBus {
  static final _controller = StreamController<CrudEvent>.broadcast();

  /// Stream of all CRUD events.
  static Stream<CrudEvent> get stream => _controller.stream;

  /// Fire a new CRUD event.
  static void fire(CrudEvent event) {
    _controller.add(event);
  }

  /// Listen for events of a specific model type.
  static Stream<CrudEvent<T>> on<T>() {
    return stream.where((event) => event is CrudEvent<T>).cast<CrudEvent<T>>();
  }
}
