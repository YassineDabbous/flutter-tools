// Shared in-shell back-stack (generic): every shell that owns poppable
// surfaces (the planner shell, the composer shell) coordinates them
// newest-first — a LIFO registry drained by the shell's `PopScope`.

import 'package:flutter/widgets.dart';

/// One back-button consumer inside a shell.
class PopSession {
  /// Canonical id (per owning surface) — duplicate pushes replace the
  /// older entry.
  const PopSession(this.id, this.onPop, {this.obscuresFrame = false});

  /// Canonical id — duplicate pushes replace the older entry.
  final String id;

  /// A session WITH the coordinator means the surface is open and claims
  /// back presses — firing [onPop] closes/removes it as a side effect.
  final VoidCallback onPop;

  /// Full-height overlay sessions (pin mode, fullscreen editors) hide the
  /// frame lane (bar + rails) while open — the overlay paints the whole
  /// screen. Sheet-drag sessions never obscure. Default false.
  final bool obscuresFrame;
}

/// Ordered back-stack for in-shell surfaces. Shells push on surface-open,
/// drop/dropAll on close; the shell wraps its body in a `PopScope` that
/// drains newest-first ([handleBack]), then falls through to the shell's
/// own route pop. Shrunk by [dropAll] on dispose.
class PopCoordinator {
  final List<PopSession> _stack = [];

  /// Every mutation bumps this revision — the frame lane listens to it for
  /// both its hide-over-obscuring-overlay check and the back button's
  /// visibility, so neither depends on an incidental rebuild.
  final ValueNotifier<int> revision = ValueNotifier(0);

  int get length => _stack.length;

  /// How many OPEN sessions hide the frame lane (full-height overlays).
  int get obscuringCount => _stack.where((s) => s.obscuresFrame).length;

  String? get topId => _stack.isEmpty ? null : _stack.last.id;

  bool contains(String id) => _stack.any((s) => s.id == id);

  void _bump() {
    revision.value++;
  }

  void push(PopSession session) {
    _stack
      ..removeWhere((s) => s.id == session.id)
      ..add(session);
    _bump();
  }

  /// Removes WITHOUT firing — for close paths that own their dismissal
  /// (surface closed itself by an in-surface gesture, not a back press).
  void drop(String id) {
    _stack.removeWhere((s) => s.id == id);
    _bump();
  }

  /// Switch discipline: drop EVERYTHING before an owner swap — a stale
  /// session popping after the new owner mounted would hit dead widgets.
  void dropAll() {
    _stack.clear();
    _bump();
  }

  /// Newest-first drain. TRUE when a session existed (it was fired — the
  /// caller must not route-pop); FALSE = empty stack, fall through to the
  /// shell's own back profile.
  bool handleBack() {
    if (_stack.isEmpty) return false;
    _stack.removeLast().onPop();
    _bump();
    return true;
  }

  void dispose() {
    revision.dispose();
  }
}
