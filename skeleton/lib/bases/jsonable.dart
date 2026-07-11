/// For serializable classes that contains `toJson` helper.
abstract class Jsonable {
  Map<String, dynamic> toJson();
}

/// Class contains a `fromJson`, `toJson` and `merge` helpers.
abstract class JsonableFromTo<T> extends Jsonable {
  T fromJson(Map<String, dynamic> json);

  T merge(JsonableFromTo fixed) => fromJson(
    toJson()
      ..addAll(fixed.toJson()..removeWhere((key, value) => value == null)),
  );
}

abstract class SuperModel<T> extends JsonableFromTo<T> {}

abstract class Identifiable<T> {
  T get id;
  T getId() => id;
}

abstract class Labelable {
  String get label;
}

abstract class BaseModel<T> extends Jsonable
    implements Identifiable<T>, Labelable {
  String getLabel() => label;
}
