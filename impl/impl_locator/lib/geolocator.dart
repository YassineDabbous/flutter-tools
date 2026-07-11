import 'package:core/core.dart';
import 'package:geolocator/geolocator.dart' as Geo;

class LocatorImpl implements Locator {
  @override
  Future openAppSettings() async {
    await Geo.Geolocator.openAppSettings();
  }

  @override
  Future<Position> pickFromMap(context, Position position) {
    throw UnimplementedError();
  }

  @override
  Future<Position> viewInMap(context, Position position) {
    throw UnimplementedError();
  }

  @override
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    Geo.LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geo.Geolocator.checkPermission();
    if (permission == Geo.LocationPermission.denied) {
      permission = await Geo.Geolocator.requestPermission();
      if (permission == Geo.LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == Geo.LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.

      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    final p = await Geo.Geolocator.getCurrentPosition();
    print(p.toString());
    return Position(latitude: p.latitude, longitude: p.longitude);
  }
}
