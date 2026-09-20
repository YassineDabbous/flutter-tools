import 'laravel_api_service.dart';

/// Base class for persona-prefixed Laravel services (`customer`, `courier`,
/// `partner` — one instance per persona, lowercase prefix).
///
/// Backend prefixes are lowercase (`customer|courier|partner`) while call
/// sites pass `Customer|Courier|Partner` — normalized here, once, so concrete
/// services never repeat the `pathSegments` override.
///
/// With the inherited `resource == ''` convention (used by all persona
/// services), a method's `suffixPath` carries the full sub-path, e.g.
/// `suffixPath: 'finance/debt/settle'` resolves to
/// `/customer/finance/debt/settle`.
///
/// Do NOT use this when the backend mounts the resource bare (no persona) —
/// extend [LaravelApiService] directly with fixed `pathSegments` instead
/// (see `ReceiptVerifyApi`: `const ['customer']`).
abstract class PersonaApiService<Model, ID>
    extends LaravelApiService<Model, ID> {
  PersonaApiService(super.dio, {super.baseUrl, required super.persona});

  @override
  List<String> get pathSegments => [persona!.toLowerCase()];
}
