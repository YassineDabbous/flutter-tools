import 'dart:async';

import 'package:flutter/widgets.dart';

class Position {
  const Position({
    required this.longitude,
    required this.latitude,
    this.heading,
    this.speed,
    this.accuracy,
  });
  final double latitude;
  final double longitude;

  /// Course over ground in degrees (0-359.999) — meaningful only while
  /// moving (`speed > ~1 m/s`); null/stale when stationary.
  final double? heading;

  /// Speed over ground in m/s.
  final double? speed;

  /// Position accuracy radius in meters.
  final double? accuracy;
}

abstract class Locator {
  Future<Position> getCurrentPosition();

  /// Continuous position updates for streaming surfaces (courier GPS
  /// publisher). Implementations should apply a distance filter (~10 m) —
  /// cadence/rate shaping belongs to the caller.
  Stream<Position> positionStream();

  Future<Position> pickFromMap(BuildContext context, Position position);
  Future<Position> viewInMap(BuildContext context, Position position);
  Future openAppSettings();
}
