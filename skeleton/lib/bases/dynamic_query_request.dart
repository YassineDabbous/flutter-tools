// dynamic_query_request.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:skeleton/skeleton.dart';

// part 'dynamic_query_request.g.dart';

// @JsonSerializable(genericArgumentFactories: true, includeIfNull: false)
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

  // factory DynamicQueryRequest.fromJson(Map<String, dynamic> json) =>
  //     _$DynamicQueryRequestFromJson(json);

  // Map<String, dynamic> toJson() => _$DynamicQueryRequestToJson(this);
}