# Action Package — Improvements

---

## 🟡 1. Undo/Redo for Destructive Actions

### Problem
Bulk delete and other destructive actions are irreversible once confirmed. If the user makes a mistake, there's no way to undo.

### Solution
Implement a soft-delete + undo pattern:

```dart
class UndoableAction {
  final ActionRequest request;
  final Duration undoWindow;
  Timer? _commitTimer;
  final VoidCallback onCommit;
  final VoidCallback onUndo;

  UndoableAction({
    required this.request,
    this.undoWindow = const Duration(seconds: 8),
    required this.onCommit,
    required this.onUndo,
  });

  void start() {
    _commitTimer = Timer(undoWindow, () {
      onCommit();
    });
  }

  void undo() {
    _commitTimer?.cancel();
    onUndo();
  }
}

// In the action handler
void listener(BuildContext context, ActionState state) {
  if (state is ActionHandledState) {
    final undoable = UndoableAction(
      request: widget.action.request(),
      onCommit: () => store.runAction(widget.action.request()..set('_confirm', true)),
      onUndo: () {
        store.runAction(ActionRequest(
          action: 'undo_${widget.action.route}',
          type: widget.action.controller.type,
          keys: widget.action.controller.selectedIds,
        ));
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${widget.action.controller.selectedIds.length} items affected'),
      action: SnackBarAction(label: 'UNDO', onPressed: undoable.undo),
      duration: undoable.undoWindow,
    ));

    undoable.start();
  }
}
```

**Backend support required:** The API should support a two-phase delete:
1. Phase 1: `POST /_action_` with `soft=true` → marks resources as "pending deletion"
2. Phase 2 (after undo window): `POST /_action_` with `_confirm=true` → hard delete
3. Undo: `POST /_action_` with `action=undo_delete` → restore soft-deleted items

---

## 🟡 2. Batch Progress Tracking

### Problem
When performing bulk actions on 100+ items, the UI shows a generic spinner. No indication of progress.

### Solution
Support streaming progress from the server:

```dart
class ActionProgressState extends ActionState {
  final int total;
  final int processed;
  final int failed;
  double get progress => total > 0 ? processed / total : 0;
  ActionProgressState({required this.total, required this.processed, this.failed = 0});
}

// In ActionCubit
void runActionWithProgress(ActionRequest request) async {
  try {
    emit(ActionHandlingState());

    // Use SSE or chunked response for progress
    final stream = http().handleActionStreamed(request);
    await for (final update in stream) {
      emit(ActionProgressState(
        total: update['total'],
        processed: update['processed'],
        failed: update['failed'] ?? 0,
      ));
    }

    emit(ActionHandledState(BasicResponse(
      code: 200,
      message: 'Completed',
    )));
  } catch (e) {
    emit(mapErrorToState(e));
  }
}
```

**UI enhancement:**
```dart
if (state is ActionProgressState)
  Positioned.fill(
    child: Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LinearProgressIndicator(value: state.progress),
          const SizedBox(height: Sz.md),
          Text('${state.processed} / ${state.total}'),
          if (state.failed > 0)
            Text('${state.failed} failed', style: TextStyle(color: Colors.red)),
        ],
      ),
    ),
  ),
```

---

## 🟡 3. Offline Queued Actions

### Problem
If the user is offline, bulk actions fail. On mobile, connectivity is unreliable.

### Solution
Queue actions locally and execute when back online:

```dart
class OfflineActionQueue {
  static const _key = 'offline_action_queue';
  final SharedPrefHelper _prefs;

  OfflineActionQueue(this._prefs);

  Future<void> enqueue(ActionRequest request) async {
    final queue = _getQueue();
    queue.add({
      'request': request.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
      'id': const Uuid().v4(),
    });
    await _prefs.set<List>(key, queue);
  }

  List<Map<String, dynamic>> get pending => _getQueue();

  Future<void> flush(ActionCubit cubit) async {
    final queue = _getQueue();
    final remaining = <Map<String, dynamic>>[];

    for (final item in queue) {
      try {
        final request = ActionRequest.fromJson(item['request']);
        await cubit.runActionAsync(request);
      } catch (e) {
        remaining.add(item); // Keep failed items
      }
    }

    await _prefs.set<List>(_key, remaining);
  }
}
```

**Auto-flush on connectivity restore:**
```dart
// In your Initializer.activate()
ConnectivityService.onRestore.listen((_) {
  Core.get<OfflineActionQueue>().flush(Core.get<ActionCubit>());
});
```

---

## 🟢 4. Action Audit Trail

### Problem
No client-side record of which actions were performed, when, and on which resources.

### Solution
```dart
class ActionAuditLog {
  static const _key = 'action_audit_log';

  static Future<void> log(ActionRequest request, BasicResponse response) async {
    final prefs = Core.get<SharedPrefHelper>();
    final logs = prefs.get<List>(_key) ?? [];
    logs.insert(0, {
      'action': request.action,
      'type': request.type,
      'keys': request.keys,
      'result': response.code,
      'message': response.message,
      'timestamp': DateTime.now().toIso8601String(),
      'user': auth().currentUser?.user.name,
    });
    // Keep last 100 entries
    if (logs.length > 100) logs.removeLast();
    await prefs.set<List>(_key, logs);
  }
}

// In ActionCubit.runAction() — after success:
ActionAuditLog.log(request, data);
```

**UI:** Add an "Action History" screen to review past operations.

---

## 🟢 5. Action Templates / Presets

### Problem
Common action combinations (e.g., "Approve + Assign + Notify") must be configured each time.

### Solution
Allow saving action presets:

```dart
class ActionPreset {
  final String name;
  final List<ActionStep> steps;
  final Map<String, dynamic> defaultPayload;

  ActionPreset({required this.name, required this.steps, this.defaultPayload = const {}});
}

class ActionStep {
  final String action;
  final Map<String, dynamic>? payload;
  ActionStep({required this.action, this.payload});
}

// Usage: "Quick Approve" preset
final quickApprove = ActionPreset(
  name: 'Quick Approve',
  steps: [
    ActionStep(action: 'change_status', payload: {'status': 'approved'}),
    ActionStep(action: 'notify', payload: {'template': 'approval_email'}),
  ],
);
```

Users could create and save their own presets for frequently-used workflows.
