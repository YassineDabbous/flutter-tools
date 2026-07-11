// import 'package:intl/intl.dart';

// // final _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
// final _dateFormatter = DateFormat('yyyy-MM-ddTHH:mm:ss'); // 2022-11-19T14:08:30.000000Z
// DateTime? dateFromJson(String? date) => date != null ? _dateFormatter.parse(date) : null;
// String? dateToJson(DateTime? date) => date != null ? _dateFormatter.format(date) : null;

class Coordinates {
  int? srid;
  num? latitude;
  num? longitude;
  bool get isEmpty => latitude == 0 && longitude == 0;

  Coordinates({required this.latitude, required this.longitude, this.srid});

  Coordinates.fromJson(Map<String, dynamic> json) {
    srid = json['srid'];
    latitude = json['latitude'];
    longitude = json['longitude'];
  }
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}
