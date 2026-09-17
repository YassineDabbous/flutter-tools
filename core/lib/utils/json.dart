/// Tolerant JSON helpers shared by every Rebelo app/module parsing Laravel
/// responses.
///
/// # Laravel-tolerance contract
/// Laravel serializes numerics as **strings** (`decimal:` casts — e.g.
/// `"36.7992000"`) and empty maps as **arrays** (`json_decode('{}')` → `[]`).
/// Two real crash signatures this file prevents:
/// - `type 'String' is not a subtype of type 'num?'`
/// - `type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>?'`
///
/// Every `double`/`int`/`bool`/`Map` field parsed from a backend response must
/// go through these helpers — never raw `as` casts.
///
/// # Ownership rule
/// **Core is the only home.** If a module needs a new tolerant parser, add it
/// here (core is a dependency of every package) — never copy this file.
/// Evidence: `rg -l "doubleFromJson|mapFromJson"` must only match
/// `packages/core/lib/utils/json.dart` (and files that import it).
library;

import '../extensions/logger.dart';

/// Parses a numeric value tolerantly: `num` → [double], `String` → parse.
double? doubleFromJson(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// [doubleFromJson] with `0` fallback (required field).
double doubleFromJsonValue(dynamic value) => doubleFromJson(value) ?? 0;

/// Parses an integer tolerantly: `int` → itself, other `num` → truncated,
/// `String` → parse. Null/`"0.5"`-style values → `null`.
int? intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

/// [intFromJson] with `0` fallback (required field).
int intFromJsonValue(dynamic value) => intFromJson(value) ?? 0;

/// Parses a boolean tolerantly: `true`, `1`, `'1'`, `'true'`, `'TRUE'` → true.
bool boolFromJson(dynamic value) =>
    value == true ||
    value == 1 ||
    value == '1' ||
    value == 'true' ||
    value == 'TRUE';

/// [boolFromJson] (baase is always non-null: a missing flag means "off").
bool boolFromJsonValue(dynamic value) => boolFromJson(value);

/// Parses a `Map<String, dynamic>` tolerantly.
///
/// Returns `null` for a `List`/non-map input — PHP `json_decode('{}')`
/// becomes `[]`, so this traps the empty-map-as-array crash. Never use
/// `as Map<String, dynamic>?` on dynamic JSON.
Map<String, dynamic>? mapFromJson(dynamic value) {
  if (value == null) return null;
  if (value is List) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

/// Parses a list of maps, coercing each element to `Map<String, dynamic>`.
///
/// **WARNING**: a non-map element is silently coerced to `{}` rather than
/// dropped — this masks backend shape bugs (a JSON array of scalars would come
/// through as an equal-length list of empty maps). Mind callers that drain
/// `.isEmpty`/`.length` as if it were the real payload.
List<Map<String, dynamic>>? mapListFromJson(dynamic value) {
  if (value == null || value is! List) return null;
  return value.map((e) {
    if (e is Map<String, dynamic>) return e;
    if (e is Map) return e.cast<String, dynamic>();
    // Silently coercing hides array-of-scalars bugs — log so the shape drift
    // surfaces instead of draining as empty maps downstream.
    Object().logNet.warning('json_helpers.mapListFromJson: non-map element', e);
    return <String, dynamic>{};
  }).toList();
}

/// String lists (e.g. subscription tier `benefits` jsonb): keeps only the
/// string elements instead of crashing on unexpected shapes.
List<String>? stringListFromJson(dynamic value) {
  if (value == null || value is! List) return null;
  return value.whereType<String>().toList();
}