/// Extensions for the generic [Map] class.
extension MapExtensions on Map {
  /// Converts all map values to their corresponding numeric type (int, double, num)
  /// if possible, otherwise keeps them as is.
  Map<String, dynamic> get toDynamic => map((key, value) => MapEntry(key, int.tryParse(value) ?? double.tryParse(value) ?? num.tryParse(value) ?? value));

  /// Converts the map into a URL query string (e.g., 'key1=value1&key2=value2').
  String get toQuery => map((key, value) => MapEntry(key, value == null ? value : '$key=$value')).values.where((element) => element != null).join('&');

  /// Converts the map into a URL query string prefixed with '?'.
  String get toQueryWithMark => '?$toQuery';

  /// Returns a new Map sorted alphabetically by its keys.
  Map get sorted => Map.fromEntries(entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)));

  /// Returns a new Map sorted alphabetically by its keys, ensuring keys are [String].
  Map<String, V> sort<String, V extends Object>() {
    final x = entries.map((e) => MapEntry(e.key.toString(), e.value as V)).toList();
    x.sort((e1, e2) => e1.key.compareTo(e2.key));
    return Map.fromEntries(Iterable.castFrom(x));
  }
}

  // '?attribuable_id=111&attribuable_type=222...'
  // String toUrlParameters() {
  //   var result = [];
  //   forEach((key, value) {
  //     if (value != null && (value is! String || value.trim().isNotEmpty)) {
  //       result.add('$key=$value');
  //     }
  //   });
  //   logNet.debug('?${result.join('&')}');
  //   return '?${result.join('&')}';
  // } 
