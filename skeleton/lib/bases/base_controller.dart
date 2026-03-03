import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

abstract class BaseController<TFilterRequest extends SuperModel, TModel> {
  /// whether dealing with Admin API
  bool forAdmin;

  /// Model type ("user" for "User")
  String type;

  /// List of model fiels, used with HTTP requests to get only needed model fields.
  List<String> fields; //  = const ['id', 'name', 'employees_count', 'employees_sum_salary'];

  /// Search filter
  late TFilterRequest filter;

  /// Fixed Filter fields
  late TFilterRequest fixed; // for fixed params in filter, used to prevent user from clearing the whole filter.

  /// Make a fresh filter request
  Function()? refresh;

  // Function(Model item, UserAction action, int index)? action;

  // Run a user action on list of items
  Function(List<TModel> items, UserAction action)? bulkAction; // , bool forceAll= false

  /// Validates filter form
  bool Function()? validateFilter;

  Function()? fillFilter;

  Function()? clearForm;

  /// Constructor
  BaseController({
    required this.type,
    TFilterRequest? filter,
    TFilterRequest? fixed,
    this.onIdsSelection,
    this.initialySelectedIds,
    this.forAdmin = false,
    this.enableSelection = true,
    this.fields = const [],
  }) {
    this.filter = filter ?? newInstance;
    this.fixed = fixed ?? newInstance;
  }

  /// Clears filter form
  void clear() {
    if (fixed.toJson().isNotEmpty) {
      fillFromJson(fixed.toJson());
    } else {
      filter = newInstance;
    }
    clearForm?.call();
  }

  /// Creates filter instance
  TFilterRequest get newInstance;

  /// Merges new filters with fixed one.
  TFilterRequest get request => filter.merge(fixed);

  /// Fill filter from query parameters
  void fillFromQuery(Map<String, String> params) {
    // fillFromJson(params.toDynamic); <-  if params=={} this will cause creating new empty filter.

    // merging params with current filter
    filter = filter.merge(newInstance.fromJson(params));
  }

  /// Fill filter from json map
  void fillFromJson(Map<String, dynamic> json) {
    filter = newInstance.fromJson(json);
  }

  //
  // Selection helpers
  //

  bool enableSelection;
  final Function(List<int> ids)? onIdsSelection;
  bool get isSelectionEnabled => enableSelection || onIdsSelection != null;

  /// Selected indexes in a table/grid
  List<int> selectedIndexes = [];

  /// Initialy selected IDs
  List<int>? initialySelectedIds;

  /// IDs of selected items
  List<int> selectedIds = [];

  /// Selection Listener
  void onSelection(List<int> indexes, List<int> ids) {
    logUI.debug('selected ids are $ids');
    selectedIndexes = indexes;
    selectedIds = ids;
  }
}

// abstract class BaseControllerx<TFilterRequest extends SuperModel<TFilterRequest>, TModel extends Jsonable> {
//   late TFilterRequest filter;
//   TFilterRequest? fixed; // for fixed params in filter,  ex: fix "account type === business" in Pages Screen
//   // Function(Model item, UserAction action, int index)? action;
//   Function()? refresh;
//   //
//   final Function(List<int> ids)? onSelection;
//   List<int>? initialSelectedIds;
//   //
//   bool Function()? validateFilter;
//   Function()? fillFilter;
//   //
//   BaseControllerx({
//     TFilterRequest? filter,
//     this.onSelection,
//     this.initialSelectedIds,
//   }) {
//     this.filter = filter ?? newInstance;
//   }

//   void clear() {
//     filter = fixed ?? newInstance;
//   }

//   TFilterRequest get newInstance;

//   TFilterRequest get request => fixed == null ? filter : filter.merge(fixed!);

//   fillFromQuery(Map<String, String> params) {
//     fillFromJson(params.toDynamic);
//   }

//   fillFromJson(Map<String, dynamic> json) => newInstance.fromJson(json);
// }
