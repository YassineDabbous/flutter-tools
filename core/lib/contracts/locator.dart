import 'package:flutter/widgets.dart';

class Position {
  const Position({required this.longitude, required this.latitude});
  final double latitude;
  final double longitude;
}

abstract class Locator {
  Future<Position> getCurrentPosition();
  Future<Position> pickFromMap(BuildContext context, Position position);
  Future<Position> viewInMap(BuildContext context, Position position);
  Future openAppSettings();
}
