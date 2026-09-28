// dynamic_query_request.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:skeleton/skeleton.dart';

/// Query builder compatible with `yassinedabbous/laravel-dynamic-query`.
///
/// Param registry is the backend `config.php` (`params` map). URL keys are used
/// WITHOUT `[]` — Dio encodes `List` values as `key[]=…` automatically, which
/// Laravel parses back into arrays (the backend also accepts CSV strings).
///
/// Two usage paths:
/// 1. Typed filter per endpoint (recommended): extend this class, declare ONLY
///    backend-whitelisted filter values (mirrors `dynamicFilters()` + the
///    `*IndexRequest` rules — `strict_filtering` silently ignores the rest),
///    and implement `fromJson`/`toJson` via `json_serializable`.
/// 2. Ad-hoc: use [DynamicQuery] with `extras` (no codegen).
///
/// All params default to `null` — nothing is sent unless explicitly set, so the
/// backend applies its own defaults (e.g. `per_page=15`).
// don't use @JsonSerializable on abstract class.
abstract class DynamicQueryRequest<T> extends SuperModel<T> {
  // --- Pagination (`page`: Laravel paginator; rest: package config) ---
  @JsonKey(name: 'page')
  int? page;

  @JsonKey(name: 'per_page')
  int? perPage;

  @JsonKey(name: '_simple')
  bool? simple;

  @JsonKey(name: '_get_all')
  bool? getAll;

  @JsonKey(name: '_limit')
  int? limit;

  // --- Selection ---
  @JsonKey(name: '_fields')
  List<String>? fields;

  @JsonKey(name: '_model')
  String? modelAlias;

  // --- Sorting (`-field` = DESC) ---
  @JsonKey(name: '_sort')
  List<String>? sort;

  // --- Logic (and/or across filters) ---
  @JsonKey(name: '_logic')
  String? logic;

  // --- Global clause (where/having for all filters) ---
  @JsonKey(name: '_clause')
  String? clause;

  // --- Dynamic Operators & Clauses ---
  // Maps column names to operators (e.g. {'price': '>=', 'name': '%like%'})
  @JsonKey(name: '_operators')
  Map<String, String>? operators;

  // Maps column names to clauses (e.g. {'total': 'having'})
  @JsonKey(name: '_clauses')
  Map<String, String>? clauses;

  // --- Statistics (BI Engine) ---
  @JsonKey(name: '_metric')
  String? metric;

  // Reserved: registered in backend config, unused by current package scopes.
  @JsonKey(name: '_col')
  String? col;

  // Reserved: registered in backend config, unused by current package scopes.
  @JsonKey(name: '_period')
  String? period;

  // Reserved: registered in backend config, unused by current package scopes.
  @JsonKey(name: '_alias')
  String? alias;

  // Group columns, with optional date macros (e.g. 'created_at:month').
  @JsonKey(name: '_group')
  List<String>? group;

  @JsonKey(name: '_transform')
  String? transform;

  @JsonKey(name: '_compare')
  String? compare;

  @JsonKey(name: '_compare_on')
  String? compareOn;

  @JsonKey(name: '_timezone')
  String? timezone;

  @JsonKey(name: '_cache')
  bool? cache;

  // --- Supabase/Dart-only (no Laravel params; stripped by toQueryParameters) ---
  @JsonKey(name: '_includes[]')
  List<String>? includes;

  @JsonKey(name: '_cursor')
  dynamic cursor;

  DynamicQueryRequest({
    this.modelAlias,
    this.page,
    this.perPage,
    this.simple,
    this.getAll,
    this.limit,
    this.fields,
    this.sort,
    this.logic,
    this.clause,
    this.operators,
    this.clauses,
    this.metric,
    this.col,
    this.period,
    this.alias,
    this.group,
    this.transform,
    this.compare,
    this.compareOn,
    this.timezone,
    this.cache,
    this.includes,
    this.cursor,
  });

  /// Dio-ready query map: Lists stay Lists (Dio encodes `key[]=…`); bools
  /// become `1`/`0` (backend boolean validation rejects native `true`);
  /// nulls and empty String/List/Map are dropped (`0`/`false` filter values
  /// are kept); Supabase-only `includes`/`cursor` keys are stripped.
  /// Everything else (child filter values, `in`/`between` arrays,
  /// `!`-prefixed negated keys) passes through untouched.
  Map<String, dynamic> toQueryParameters() {
    final json = Map<String, dynamic>.from(toJson());
    final params = <String, dynamic>{};

    for (final key in ['_fields', '_sort', '_group']) {
      final v = json.remove(key);
      if (v is List && v.isNotEmpty) {
        params[key] = v;
      } else if (v is String && v.isNotEmpty) {
        params[key] = v;
      }
    }
    for (final key in ['_get_all', '_simple', '_cache']) {
      final v = json.remove(key);
      if (v == null) continue;
      params[key] = _boolToInt(v);
    }
    for (final key in ['page', 'per_page', '_limit']) {
      final v = json.remove(key);
      if (v == null) continue;
      params[key] = v;
    }
    for (final key in ['_operators', '_clauses']) {
      final v = json.remove(key);
      if (v is Map && v.isNotEmpty) params[key] = v;
    }
    for (final key in [
      '_logic',
      '_clause',
      '_metric',
      '_col',
      '_period',
      '_alias',
      '_transform',
      '_compare',
      '_compare_on',
      '_timezone',
      '_model',
    ]) {
      final v = json.remove(key);
      if (v == null) continue;
      if (v is String && v.isEmpty) continue;
      params[key] = v;
    }
    // Ignored for Laravel (Supabase/Dart-only).
    json.remove('_includes[]');
    json.remove('_includes');
    json.remove('_cursor');

    for (final entry in json.entries) {
      final v = entry.value;
      if (v == null) continue;
      if (v is String && v.isEmpty) continue;
      if (v is List && v.isEmpty) continue;
      if (v is Map && v.isEmpty) continue;
      params[entry.key] = v;
    }
    return params;
  }

  static int _boolToInt(dynamic v) {
    if (v is bool) return v ? 1 : 0;
    if (v is num) return v != 0 ? 1 : 0;
    final s = v.toString().toLowerCase().trim();
    return (s == '1' || s == 'true') ? 1 : 0;
  }

  /// Assigns all `_`-prefixed dynamic params from a JSON map. For subclass
  /// `fromJson` implementations (hand-written or generated) so `merge()`
  /// round-trips sorts/operators/stats instead of dropping them.
  void fillDynamicJson(Map<String, dynamic> json) {
    page = _asInt(json['page']);
    perPage = _asInt(json['per_page']);
    simple = _asBool(json['_simple']);
    getAll = _asBool(json['_get_all']);
    limit = _asInt(json['_limit']);
    fields = _asStringList(json['_fields']);
    modelAlias = json['_model'] as String?;
    sort = _asStringList(json['_sort']);
    logic = json['_logic'] as String?;
    clause = json['_clause'] as String?;
    final ops = json['_operators'];
    operators = ops is Map
        ? ops.map((k, v) => MapEntry(k.toString(), v.toString()))
        : null;
    final cls = json['_clauses'];
    clauses = cls is Map
        ? cls.map((k, v) => MapEntry(k.toString(), v.toString()))
        : null;
    metric = json['_metric'] as String?;
    col = json['_col'] as String?;
    period = json['_period'] as String?;
    alias = json['_alias'] as String?;
    group = _asStringList(json['_group']);
    transform = json['_transform'] as String?;
    compare = json['_compare'] as String?;
    compareOn = json['_compare_on'] as String?;
    timezone = json['_timezone'] as String?;
    cache = _asBool(json['_cache']);
  }

  /// Serializes all `_`-prefixed dynamic params. For subclass `toJson`
  /// implementations (spread after the subclass filter values).
  Map<String, dynamic> dynamicJson() => {
    'page': page,
    'per_page': perPage,
    '_simple': simple,
    '_get_all': getAll,
    '_limit': limit,
    '_fields': fields,
    '_model': modelAlias,
    '_sort': sort,
    '_logic': logic,
    '_clause': clause,
    '_operators': operators,
    '_clauses': clauses,
    '_metric': metric,
    '_col': col,
    '_period': period,
    '_alias': alias,
    '_group': group,
    '_transform': transform,
    '_compare': compare,
    '_compare_on': compareOn,
    '_timezone': timezone,
    '_cache': cache,
  };

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static bool? _asBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase().trim();
    if (s == '1' || s == 'true') return true;
    if (s == '0' || s == 'false') return false;
    return null;
  }

  static List<String>? _asStringList(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) return v.split(',');
    return null;
  }

  /// Merges `fixed` into this filter. Unlike the shallow base version,
  /// `_operators`/`_clauses` maps are unioned (fixed wins per-field).
  @override
  T merge(JsonableFromTo fixed) {
    final merged = super.merge(fixed);
    if (fixed is DynamicQueryRequest) {
      final m = merged as DynamicQueryRequest;
      final ops = {...?operators, ...?fixed.operators};
      m.operators = ops.isEmpty ? null : ops;
      final cls = {...?clauses, ...?fixed.clauses};
      m.clauses = cls.isEmpty ? null : cls;
    }
    return merged;
  }

  // --- Fluent Builders ---

  /// Replaces the field list. Relations use deep syntax: `category:id|name`
  /// (see [DQ.deep]).
  DynamicQueryRequest<T> select(List<String> fields) {
    this.fields = fields;
    return this;
  }

  /// Supabase-only. For Laravel, request relations via [select] deep syntax.
  DynamicQueryRequest<T> include(List<String> relationships) {
    includes = relationships;
    return this;
  }

  /// Appends a sort entry (`-field` when [descending]).
  DynamicQueryRequest<T> orderBy(String field, {bool descending = false}) {
    sort ??= [];
    sort!.add(descending ? '-$field' : field);
    return this;
  }

  DynamicQueryRequest<T> orderByDesc(String field) =>
      orderBy(field, descending: true);

  /// Sets the operator (and optional clause) for [field]. The filter VALUE
  /// itself lives on the child class — this only touches the operator side.
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

  /// Operator shortcuts (values stay on the child class).
  DynamicQueryRequest<T> useIn(String field) => where(field, DQ.in_);
  DynamicQueryRequest<T> useBetween(String field) => where(field, DQ.between);
  DynamicQueryRequest<T> useContains(String field) => where(field, DQ.contains);
  DynamicQueryRequest<T> useStartsWith(String field) =>
      where(field, DQ.startsWith);
  DynamicQueryRequest<T> useEndsWith(String field) => where(field, DQ.endsWith);
  DynamicQueryRequest<T> useNull(String field) => where(field, DQ.null_);

  /// Filters [field] via HAVING instead of WHERE (aggregated values).
  DynamicQueryRequest<T> having(String field) =>
      where(field, operators?[field] ?? DQ.eq, DQ.having);

  /// Applies HAVING to all filters.
  DynamicQueryRequest<T> globalHaving() {
    clause = DQ.having;
    return this;
  }

  /// Combines multiple filters with OR instead of AND.
  DynamicQueryRequest<T> or() {
    logic = DQ.or;
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

  DynamicQueryRequest<T> perPageTo(int perPage) {
    this.perPage = perPage;
    return this;
  }

  /// Uses `simplePaginate` (faster, no `total` — admin lists MUST set this).
  DynamicQueryRequest<T> simplePaginate([bool value = true]) {
    simple = value;
    return this;
  }

  /// Skips pagination entirely (requires backend `allow_get_all`).
  DynamicQueryRequest<T> fetchAll([bool value = true]) {
    getAll = value;
    return this;
  }

  /// Appends grouping columns (date macros via [DQ.month] etc.).
  DynamicQueryRequest<T> groupBy(List<String> groups) {
    group ??= [];
    group!.addAll(groups);
    return this;
  }

  DynamicQueryRequest<T> addGroup(String group) => groupBy([group]);

  /// Stats metric, e.g. `DQ.sum('total')`.
  DynamicQueryRequest<T> withMetric(String metric) {
    this.metric = metric;
    return this;
  }

  DynamicQueryRequest<T> withTransform(String transform) {
    this.transform = transform;
    return this;
  }

  DynamicQueryRequest<T> comparePreviousPeriod({String? on}) {
    compare = DQ.previousPeriod;
    if (on != null) compareOn = on;
    return this;
  }

  DynamicQueryRequest<T> withTimezone(String timezone) {
    this.timezone = timezone;
    return this;
  }

  DynamicQueryRequest<T> useCache([bool value = true]) {
    cache = value;
    return this;
  }

  DynamicQueryRequest<T> cursorAt(dynamic cursor) {
    this.cursor = cursor;
    return this;
  }
}

/// Ad-hoc dynamic query (no codegen): filter values go into [extras] and are
/// merged top-level by [toJson]/[toQueryParameters]. Prefer a typed
/// [DynamicQueryRequest] subclass per endpoint when the filter set is stable.
class DynamicQuery extends DynamicQueryRequest<DynamicQuery> {
  /// Ad-hoc filter values. Keys must not collide with `_`-prefixed params.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic> extras = {};

  DynamicQuery({
    Map<String, dynamic>? extras,
    super.page,
    super.perPage,
    super.simple,
    super.getAll,
    super.limit,
  }) {
    if (extras != null) this.extras = Map<String, dynamic>.from(extras);
  }

  static const _knownKeys = {
    'page',
    'per_page',
    '_simple',
    '_get_all',
    '_limit',
    '_fields',
    '_model',
    '_sort',
    '_logic',
    '_clause',
    '_operators',
    '_clauses',
    '_metric',
    '_col',
    '_period',
    '_alias',
    '_group',
    '_transform',
    '_compare',
    '_compare_on',
    '_timezone',
    '_cache',
  };

  @override
  DynamicQuery fromJson(Map<String, dynamic> json) {
    final q = DynamicQuery()..fillDynamicJson(json);
    for (final entry in json.entries) {
      if (!_knownKeys.contains(entry.key)) q.extras[entry.key] = entry.value;
    }
    return q;
  }

  @override
  Map<String, dynamic> toJson() => {...extras, ...dynamicJson()};
}
