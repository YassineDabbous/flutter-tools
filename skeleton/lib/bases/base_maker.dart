import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

/// Maker classes (like `UserMaker`, `PostMaker`) are used as helpers for Create/Edit screens and EditForm.
abstract class BaseMaker<TModel extends Jsonable, TRequest extends SuperModel<TRequest>> {
  int id = 0; // default to 0 for creation forms
  late TRequest form; // resource fields that will be modified and submitteds
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
