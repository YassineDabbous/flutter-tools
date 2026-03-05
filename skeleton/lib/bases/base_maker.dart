import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

/// Maker classes (like `UserMaker`, `PostMaker`) are used as helpers for Create/Edit screens and EditForm.
abstract class BaseMaker<
  TModel extends Jsonable,
  TRequest extends Jsonable,
  ID
> {
  ID? id; // nullable ID for creation forms
  late TRequest form; // resource fields that will be modified and submitted
  late TRequest fixed; // unmodifiable resource fields

  final Map<String, dynamic> _attachments = {};

  /// Retrieves the current map of attachments.
  Map<String, dynamic> get attachments => _attachments;

  /// True if there are any attachments queued for upload.
  bool get hasAttachments => _attachments.isNotEmpty;

  /// Sets an attachment for a specific key (e.g., 'image', 'document').
  void setAttachment(String key, dynamic value) {
    if (value == null) {
      _attachments.remove(key);
    } else {
      _attachments[key] = value;
    }
  }

  /// Clears all attachments.
  void clearAttachments() => _attachments.clear();

  /// true if form valid, used usually as a proxy to FormState.validate()
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
  BaseMaker({TRequest? request, TRequest? fixed, TModel? model})
    : assert(model == null || request == null) {
    this.fixed = fixed ?? newInstance;
    form = (request ?? newInstance);
    if (model != null) {
      fillFromModel(model);
      try {
        if (model is Identifiable<ID>) {
          id = (model as Identifiable<ID>).id;
        } else {
          id = (model as dynamic).id;
        }
      } catch (e) {
        logCtrl.warning('no id in this model class');
      }
    }
  }

  /// fill `TRequest form` using query parameters
  void fillFromQuery(Map<String, String> params) {
    form = jsonToRequest(params.toDynamic);
  }

  /// fill `TRequest form` using `TModel` instance
  void fillFromModel(TModel model) {
    try {
      if (model is Identifiable<ID>) {
        id = (model as Identifiable<ID>).id;
      } else {
        id = (model as dynamic).id;
      }
    } catch (e) {
      logCtrl.warning('no id in this model class');
    }
    form = modelToRequest(model);
  }

  /// Getter will be used as the final merged request (modified data + fixed data) that will be submitted to the backend
  TRequest get request {
    if (form is JsonableFromTo && fixed is JsonableFromTo) {
      return (form as dynamic).merge(fixed);
    }
    return form;
  }

  /// Transform a data model to request instance
  TRequest modelToRequest(TModel model) => jsonToRequest(model.toJson());

  /// Transform a data map to request instance
  TRequest jsonToRequest(Map<String, dynamic> json);

  /// Helper to create new request class instance
  TRequest get newInstance;
}
