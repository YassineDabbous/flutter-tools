import 'package:skeleton/skeleton.dart';

/// A type-safe version of [BaseAction] that uses a dedicated payload model.
abstract class TypedAction<TPayload extends Jsonable> extends BaseAction {
  /// The typed payload for this action.
  final TPayload typedPayload;

  TypedAction({
    required super.controller,
    required super.route,
    required this.typedPayload,
    super.title,
    super.description,
    super.onHandled,
    super.formBuilder,
  });

  @override
  ActionRequest request() {
    final base = super.request();
    // Merge the typed payload into the request
    base.payload ??= {};
    base.payload!.addAll(typedPayload.toJson());
    return base;
  }
}
