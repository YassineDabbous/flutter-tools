/// Abstract class for actions that can be undone.
abstract class UndoableAction {
  /// Executes the action.
  Future<void> execute();

  /// Reverts the action.
  Future<void> undo();

  /// A human-readable label for the action (e.g., 'Delete Post').
  String get label;
}

/// A manager for handling undo/redo operations.
class UndoManager {
  final List<UndoableAction> _history = [];

  void execute(UndoableAction action) async {
    await action.execute();
    _history.add(action);
  }

  void undoLast() async {
    if (_history.isNotEmpty) {
      final last = _history.removeLast();
      await last.undo();
    }
  }

  bool get canUndo => _history.isNotEmpty;
}
