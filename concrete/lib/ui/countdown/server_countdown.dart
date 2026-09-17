import 'dart:async';

import 'package:flutter/material.dart';

import 'package:core/core.dart';

/// Server-clock countdown shared by every Rebelo surface.
///
/// Seeds from a backend `*_expires_at` + `server_now` pair (same server clock,
/// so device-clock drift of ±minutes is irrelevant) and advances only by
/// elapsed wall time, ticking once per second. A missing/unparsable deadline
/// pair renders [SizedBox.shrink] (hide the chip); [onExpired] fires exactly
/// once when the deadline is reached (or was already past at seed time).
///
/// [onExpired] is local plumbing only — callers decide whether reaching zero
/// should refetch; the widget never invents a client-side duration.
class ServerCountdown extends StatefulWidget {
  /// Backend deadline (ISO-8601, server clock). `null` hides the countdown.
  final String? expiresAt;

  /// Backend "now" paired with [expiresAt] (ISO-8601, server clock).
  final String? serverNow;

  /// Builds the visible countdown from the current remaining seconds.
  final Widget Function(BuildContext context, int remainingSeconds) builder;

  /// Fired once when the countdown reaches zero.
  final VoidCallback? onExpired;

  const ServerCountdown({
    super.key,
    required this.expiresAt,
    required this.serverNow,
    required this.builder,
    this.onExpired,
  });

  @override
  State<ServerCountdown> createState() => _ServerCountdownState();
}

class _ServerCountdownState extends State<ServerCountdown> {
  Timer? _timer;
  late DateTime _seededAt;
  int? _baseMs;
  int _seconds = 0;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(covariant ServerCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt ||
        oldWidget.serverNow != widget.serverNow) {
      _seed();
    }
  }

  void _seed() {
    _timer?.cancel();
    _timer = null;
    _fired = false;
    _seededAt = DateTime.now();
    _baseMs = TrackingTimers.remainingMs(widget.expiresAt, widget.serverNow);
    _seconds = _remainingSeconds;
    if (_baseMs == null) return;
    if (_seconds <= 0) {
      _fired = true;
      widget.onExpired?.call();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds = _remainingSeconds);
      if (_seconds <= 0) {
        _timer?.cancel();
        _timer = null;
        if (!_fired) {
          _fired = true;
          widget.onExpired?.call();
        }
      }
    });
  }

  int get _remainingSeconds {
    final base = _baseMs;
    if (base == null) return 0;
    final ms = base - DateTime.now().difference(_seededAt).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_baseMs == null) return const SizedBox.shrink();
    return widget.builder(context, _seconds);
  }
}
