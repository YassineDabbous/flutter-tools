import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

/// Extension to add persistence and URL sharing capabilities to BaseController filters.
extension FilterPersistenceX<
  TFilterRequest extends SuperModel<TFilterRequest>,
  TModel,
  ID
>
    on BaseController<TFilterRequest, TModel, ID> {
  /// Serialize current filter to a URL-friendly query string.
  String toQueryString() {
    final json = request.toJson();
    final List<String> parts = [];

    json.forEach((key, value) {
      if (value == null) return;

      if (value is Iterable) {
        for (final item in value) {
          parts.add(
            '${Uri.encodeComponent('$key[]')}=${Uri.encodeComponent(item.toString())}',
          );
        }
      } else if (value.toString().isNotEmpty) {
        parts.add(
          '${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}',
        );
      }
    });

    return parts.join('&');
  }

  /// Restore filter from a URL query string.
  void fromQueryString(String query) {
    if (query.isEmpty) return;
    final params = Uri.splitQueryString(query);
    fillFromQuery(params);
  }

  /// Persist current filter to local storage.
  Future<void> saveFilter(String key) async {
    final storage = Core.get<SharedPrefHelper>();
    await storage.set<Map<String, dynamic>>('filter_$key', request.toJson());
  }

  /// Restore filter from local storage.
  Future<void> loadFilter(String key) async {
    final storage = Core.get<SharedPrefHelper>();
    final json = storage.get<Map<String, dynamic>>('filter_$key');
    if (json != null) {
      fillFromJson(json);
    }
  }

  /// Clear the persisted filter from local storage.
  Future<void> clearFilter(String key) async {
    final storage = Core.get<SharedPrefHelper>();
    await storage.remove('filter_$key');
  }
}
