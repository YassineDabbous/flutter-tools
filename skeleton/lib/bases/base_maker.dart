import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

//
//
// Map<String, FileField> attachments = {};
// get attachmentsMap => (attachments..removeWhere((key, value) => value.data == null)).map((key, value) => MapEntry(key, value.formPart()!));
// Map<String, MultipartFile>
// FileField? attachmentsGet(String key) => attachments[key];
// FileField attachmentsSet(String key, dynamic value) {
//   if (attachments.containsKey(key) && attachments[key] != null) {
//     attachments[key]!.data = value;
//   } else {
//     attachments[key] = FileField(name: key, type: type)
//   }
//   return attachments[key]!;
// }

/// Maker classes (like `UserMaker`, `PostMaker`) are used as helpers for Create/Edit screens and EditForm.
abstract class BaseMaker<TModel extends Jsonable, TRequest extends SuperModel<TRequest>> {
  int id = 0; // default to 0 for creation forms
  late TRequest form; // resource fields that will be modified and submitteds
  late TRequest fixed; // unmodifiable resource fields

  /// true if form valide, used usualy as a proxy to FormState.validate()
  bool Function()? validate;

  /// the function that will be triggered to fill form inputs (textfields) using the `TRequest form`
  Function()? fill;

  /// Setter used as proxy to `fillFromModel`
  ///
  /// @param m The data model that will be used to fill the `TRequest form`
  set model(TModel data) {
    fillFromModel(data);
  }

  //
  BaseMaker({TRequest? request, TRequest? fixed, TModel? model}) : assert(model == null || request == null) {
    // form = model != null ? modelToRequest(model) : (request ?? newInstance);
    this.fixed = fixed ?? newInstance;
    form = (request ?? newInstance);
    if (model != null) {
      fillFromModel(model);
    }
    try {
      id = (model as dynamic).id ?? id;
    } catch (e) {
      logCtrl.warning('no id in this model class');
    }
  }

  /// fill `TRequest form` using query parameters
  void fillFromQuery(Map<String, String> params) {
    form = jsonToRequest(params.toDynamic);
  }

  /// fill `TRequest form` using `TModel` instance
  void fillFromModel(TModel model) {
    try {
      /// get the id from the data model
      id = (model as dynamic).id ?? id;
    } catch (e) {
      logCtrl.warning('no id in this model class');
    }
    form = modelToRequest(model);
  }

  /// Getter will be used as the final merged request (modified data + fixed data) that will be submitted to the backend
  TRequest get request => form.merge(fixed);

  /// Transform a data model to request instance
  TRequest modelToRequest(TModel model) => form.fromJson(model.toJson());

  /// Transform a data map to request instance
  TRequest jsonToRequest(Map<String, dynamic> json) => form.fromJson(json);

  /// Helper to create new request class instance
  TRequest get newInstance;
}
