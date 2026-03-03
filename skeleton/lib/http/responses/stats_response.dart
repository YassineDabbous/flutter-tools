import 'package:json_annotation/json_annotation.dart';

part 'stats_response.g.dart';

@JsonSerializable(explicitToJson: true)
class StatisticsResponse {
  final StatMeta meta;
  
  // Summary might be null if specific comparison logic fails or isn't requested, 
  // though your backend defaults it usually.
  final StatsSummary? summary;
  
  final List<StatPoint> dataset;

  StatisticsResponse({
    required this.meta,
    this.summary,
    required this.dataset,
  });

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) => _$StatisticsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StatisticsResponseToJson(this);
}

// ==========================================
// METADATA
// ==========================================

@JsonSerializable()
class StatMeta {
  final String metric;
  final String currency;
  final String timezone;
  
  // Granularity might be a string (e.g. "created_at:month") or list of strings
  // dynamic is safest here, or use String? if backend joins them.
  final dynamic granularity; 

  StatMeta({
    required this.metric,
    required this.currency,
    required this.timezone,
    this.granularity,
  });

  factory StatMeta.fromJson(Map<String, dynamic> json) => _$StatMetaFromJson(json);
  Map<String, dynamic> toJson() => _$StatMetaToJson(this);
}

// ==========================================
// SUMMARY (The Big Number)
// ==========================================

@JsonSerializable(explicitToJson: true)
class StatsSummary {
  final double value;
  final String formatted;
  
  // Trend is optional (only exists if _compare is used or specific backend logic)
  final StatTrend? trend;

  StatsSummary({
    required this.value,
    required this.formatted,
    this.trend,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) => _$StatsSummaryFromJson(json);
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

  factory StatTrend.fromJson(Map<String, dynamic> json) => _$StatTrendFromJson(json);
  Map<String, dynamic> toJson() => _$StatTrendToJson(this);
  
  // UI Helpers
  bool get isPositive => direction == 'up';
  bool get isNegative => direction == 'down';
}

// ==========================================
// DATASET (The Chart Data)
// ==========================================

@JsonSerializable(explicitToJson: true)
class StatPoint {
  final String label;
  
  // The raw grouping keys (e.g. {'status': 'paid', 'country': 'US'})
  final Map<String, String?> group;
  
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

  factory StatPoint.fromJson(Map<String, dynamic> json) => _$StatPointFromJson(json);
  Map<String, dynamic> toJson() => _$StatPointToJson(this);
}

@JsonSerializable()
class StatTransforms {
  @JsonKey(name: 'cumulative')
  final double? cumulative;

  @JsonKey(name: 'growth')
  final double? growth; // Percentage

  StatTransforms({this.cumulative, this.growth});

  factory StatTransforms.fromJson(Map<String, dynamic> json) => _$StatTransformsFromJson(json);
  Map<String, dynamic> toJson() => _$StatTransformsToJson(this);
}