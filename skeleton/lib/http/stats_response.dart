import 'package:json_annotation/json_annotation.dart';

part 'stats_response.g.dart';

/// Standard interface for statistics data across any provider.
@JsonSerializable(explicitToJson: true)
class StatisticsResponse {
  final StatMeta meta;
  final StatsSummary? summary;
  final List<StatPoint> dataset;

  StatisticsResponse({required this.meta, this.summary, required this.dataset});

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) =>
      _$StatisticsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StatisticsResponseToJson(this);
}

@JsonSerializable()
class StatMeta {
  final StatMetric metric;
  final String? currency;
  final String? timezone;
  final dynamic granularity;

  StatMeta({
    required this.metric,
    this.currency,
    this.timezone,
    this.granularity,
  });

  factory StatMeta.fromJson(Map<String, dynamic> json) =>
      _$StatMetaFromJson(json);
  Map<String, dynamic> toJson() => _$StatMetaToJson(this);
}

/// Parsed `_metric` descriptor (`laravel-dynamic-query` `dynamicStatsAPI`).
///
/// The backend sends an object (`{raw, type, field}`), never the raw query
/// string — typed here after the `String` version threw
/// `type '_Map<String, dynamic>' is not a subtype of type 'String'` on the
/// first real stats payload.
@JsonSerializable()
class StatMetric {
  /// The metric as requested (`sum:grand_total`, `count`).
  final String raw;

  /// Aggregate type (`count`, `sum`, `avg`, `min`, `max`, or a custom name
  /// from the model's `dynamicMetrics()`).
  final String type;

  /// Aggregated column, if any (`sum:grand_total` → `grand_total`).
  final String? field;

  StatMetric({required this.raw, required this.type, this.field});

  factory StatMetric.fromJson(Map<String, dynamic> json) =>
      _$StatMetricFromJson(json);
  Map<String, dynamic> toJson() => _$StatMetricToJson(this);
}

@JsonSerializable(explicitToJson: true)
class StatsSummary {
  final double value;
  final String formatted;
  final StatTrend? trend;

  StatsSummary({required this.value, required this.formatted, this.trend});

  factory StatsSummary.fromJson(Map<String, dynamic> json) =>
      _$StatsSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$StatsSummaryToJson(this);
}

@JsonSerializable()
class StatTrend {
  final String direction; // 'up', 'down', 'flat'
  final double percent;
  final double absolute;

  StatTrend({
    required this.direction,
    required this.percent,
    required this.absolute,
  });

  factory StatTrend.fromJson(Map<String, dynamic> json) =>
      _$StatTrendFromJson(json);
  Map<String, dynamic> toJson() => _$StatTrendToJson(this);

  bool get isPositive => direction == 'up';
  bool get isNegative => direction == 'down';
}

@JsonSerializable(explicitToJson: true)
class StatPoint {
  final String label;
  final Map<String, dynamic> group;
  final double value;

  @JsonKey(name: 'previous_value')
  final double? previousValue;
  final StatTransforms? transforms;

  StatPoint({
    required this.label,
    required this.group,
    required this.value,
    this.previousValue,
    this.transforms,
  });

  factory StatPoint.fromJson(Map<String, dynamic> json) =>
      _$StatPointFromJson(json);
  Map<String, dynamic> toJson() => _$StatPointToJson(this);
}

@JsonSerializable()
class StatTransforms {
  @JsonKey(name: 'cumulative')
  final double? cumulative;

  @JsonKey(name: 'growth')
  final double? growth;

  StatTransforms({this.cumulative, this.growth});

  factory StatTransforms.fromJson(Map<String, dynamic> json) =>
      _$StatTransformsFromJson(json);
  Map<String, dynamic> toJson() => _$StatTransformsToJson(this);
}
