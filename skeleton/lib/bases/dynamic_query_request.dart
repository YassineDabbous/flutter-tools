// dynamic_query_request.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:skeleton/skeleton.dart';

// don't use @JsonSerializable on abstract class.
abstract class DynamicQueryRequest<T> extends SuperModel<T> {
  // @JsonKey(name: 'category.name')
  // final String? categoryName;

  // --- Pagination ---
  @JsonKey(name: 'page')
  int? page;

  @JsonKey(name: 'limit')
  int? limit;

  @JsonKey(name: 'per_page')
  int? perPage;

  @JsonKey(name: '_get_all')
  bool? getAll;

  // --- Selection ---
  @JsonKey(name: '_fields[]')
  List<String>? fields;

  @JsonKey(name: '_model')
  String? modelAlias;

  // --- Sorting ---
  @JsonKey(name: '_sort[]')
  List<String>? sort;

  // --- Logic (AND/OR) ---
  @JsonKey(name: '_logic')
  String? logic;

  // --- Dynamic Operators & Clauses ---
  // Maps column names to operators (e.g., {'price': '>', 'name': 'like%'})
  @JsonKey(name: '_operators')
  Map<String, String>? operators;

  // Maps column names to clauses (e.g., {'count': 'having'})
  @JsonKey(name: '_clauses')
  Map<String, String>? clauses;

  // --- Statistics (BI Engine) ---
  @JsonKey(name: '_metric')
  String? metric;

  @JsonKey(name: '_group[]')
  List<String>? group;

  @JsonKey(name: '_transform')
  String? transform;

  @JsonKey(name: '_compare')
  String? compare;

  @JsonKey(name: '_compare_on')
  String? compareOn;

  @JsonKey(name: '_timezone')
  String? timezone;

  DynamicQueryRequest({
    this.modelAlias,
    this.page,
    this.perPage,
    this.getAll,
    this.limit,
    this.fields,
    this.sort,
    this.logic,
    this.operators,
    this.clauses,
    this.metric,
    this.group,
    this.transform,
    this.compare,
    this.compareOn,
    this.timezone,
  });

  // --- Fluent Builders ---

  DynamicQueryRequest<T> select(List<String> fields) {
    this.fields = fields;
    return this;
  }

  DynamicQueryRequest<T> orderBy(String field, {bool descending = false}) {
    sort ??= [];
    sort!.add(descending ? '-$field' : field);
    return this;
  }

  DynamicQueryRequest<T> where(
    String field,
    String operator, [
    String? clause,
  ]) {
    operators ??= {};
    operators![field] = operator;
    if (clause != null) {
      clauses ??= {};
      clauses![field] = clause;
    }
    return this;
  }

  DynamicQueryRequest<T> limitTo(int limit) {
    this.limit = limit;
    return this;
  }

  DynamicQueryRequest<T> pageTo(int page, {int? perPage}) {
    this.page = page;
    if (perPage != null) this.perPage = perPage;
    return this;
  }
}
