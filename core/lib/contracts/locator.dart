import 'dart:async';

import 'package:flutter/widgets.dart';

class Position {
  const Position({required this.longitude, required this.latitude});
  final double latitude;
  final double longitude;
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
