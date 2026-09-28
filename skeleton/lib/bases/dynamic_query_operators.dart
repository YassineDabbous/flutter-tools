// dynamic_query_operators.dart
/// Operator, preset and builder constants matching
/// `yassinedabbous/laravel-dynamic-query`.
///
/// The backend runs with `strict_filtering: true` and silently drops unknown
/// operators — always use these instead of raw strings.
abstract final class DQ {
  // --- Standard operators ---
  static const eq = '=';
  static const notEq = '!=';
  static const notEqAlt = '<>';
  static const lt = '<';
  static const gt = '>';
  static const lte = '<=';
  static const gte = '>=';
  static const nullSafeEq = '<=>';
  static const is_ = 'is';
  static const isNot = 'is not';

  // --- Wildcard / LIKE operators ---
  static const like = 'like';
  static const startsWith = 'like%';
  static const endsWith = '%like';
  static const contains = '%like%';
  static const ilike = 'ilike';
  static const rlike = 'rlike';
  static const regexp = 'regexp';

  // --- Complex operators ---
  static const in_ = 'in';
  static const between = 'between';
  static const null_ = 'null';
  static const fullText = 'full_text';
  static const has = 'has';
  static const jsonContains = 'json_contains';
  static const jsonContainsKey = 'json_contains_key';
  static const jsonOverlaps = 'json_overlaps';
  static const jsonLength = 'json_length';

  // --- Clauses & logic ---
  static const where = 'where';
  static const having = 'having';
  static const and = 'and';
  static const or = 'or';

  // --- Stats transforms & comparison ---
  static const cumulative = 'cumulative';
  static const growth = 'growth';
  static const previousPeriod = 'previous_period';

  // --- Date presets (created_at and custom date columns) ---
  static const today = 'today';
  static const yesterday = 'yesterday';
  static const thisWeek = 'this_week';
  static const lastWeek = 'last_week';
  static const thisMonth = 'this_month';
  static const lastMonth = 'last_month';
  static const thisYear = 'this_year';
  static const lastYear = 'last_year';
  static const last7Days = 'last_7_days';
  static const last30Days = 'last_30_days';
  static const ytd = 'ytd';
  static const qtd = 'qtd';
  static const mtd = 'mtd';

  // --- Group date macros ---
  static const macroYear = 'year';
  static const macroMonth = 'month';
  static const macroDay = 'day';
  static const macroHour = 'hour';

  // --- Sort ---
  /// `-price` (descending). Ascending is the bare column name.
  static String desc(String field) => '-$field';

  // --- Field selection ---
  /// Deep relation fields: `category:id|name`.
  static String deep(String relation, List<String> subFields) =>
      '$relation:${subFields.join('|')}';

  // --- Filtering ---
  /// `!status` — negates the filter (WHERE … != …).
  static String notKey(String field) =>
      field.startsWith('!') ? field : '!$field';

  /// `!json_contains` — negates the operator.
  static String notOp(String operator) =>
      operator.startsWith('!') ? operator : '!$operator';

  /// `user.email` — filters/sorts/groups on a related column (auto-join).
  static String rel(String relation, String column) => '$relation.$column';

  // --- Grouping ---
  static String groupDate(String column, String macro) => '$column:$macro';
  static String month(String column) => groupDate(column, macroMonth);
  static String year(String column) => groupDate(column, macroYear);
  static String day(String column) => groupDate(column, macroDay);
  static String hour(String column) => groupDate(column, macroHour);

  // --- Metrics ---
  static const count = 'count';
  static String sum(String column) => 'sum:$column';
  static String avg(String column) => 'avg:$column';
  static String min(String column) => 'min:$column';
  static String max(String column) => 'max:$column';
}
