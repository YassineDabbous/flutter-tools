// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatisticsResponse _$StatisticsResponseFromJson(Map<String, dynamic> json) =>
    StatisticsResponse(
      meta: StatMeta.fromJson(json['meta'] as Map<String, dynamic>),
      summary: json['summary'] == null
          ? null
          : StatsSummary.fromJson(json['summary'] as Map<String, dynamic>),
      dataset: (json['dataset'] as List<dynamic>)
          .map((e) => StatPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StatisticsResponseToJson(StatisticsResponse instance) =>
    <String, dynamic>{
      'meta': instance.meta.toJson(),
      'summary': instance.summary?.toJson(),
      'dataset': instance.dataset.map((e) => e.toJson()).toList(),
    };

StatMeta _$StatMetaFromJson(Map<String, dynamic> json) => StatMeta(
  metric: json['metric'] as String,
  currency: json['currency'] as String?,
  timezone: json['timezone'] as String?,
  granularity: json['granularity'],
);

Map<String, dynamic> _$StatMetaToJson(StatMeta instance) => <String, dynamic>{
  'metric': instance.metric,
  'currency': instance.currency,
  'timezone': instance.timezone,
  'granularity': instance.granularity,
};

StatsSummary _$StatsSummaryFromJson(Map<String, dynamic> json) => StatsSummary(
  value: (json['value'] as num).toDouble(),
  formatted: json['formatted'] as String,
  trend: json['trend'] == null
      ? null
      : StatTrend.fromJson(json['trend'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StatsSummaryToJson(StatsSummary instance) =>
    <String, dynamic>{
      'value': instance.value,
      'formatted': instance.formatted,
      'trend': instance.trend?.toJson(),
    };

StatTrend _$StatTrendFromJson(Map<String, dynamic> json) => StatTrend(
  direction: json['direction'] as String,
  percent: (json['percent'] as num).toDouble(),
  absolute: (json['absolute'] as num).toDouble(),
);

Map<String, dynamic> _$StatTrendToJson(StatTrend instance) => <String, dynamic>{
  'direction': instance.direction,
  'percent': instance.percent,
  'absolute': instance.absolute,
};

StatPoint _$StatPointFromJson(Map<String, dynamic> json) => StatPoint(
  label: json['label'] as String,
  group: json['group'] as Map<String, dynamic>,
  value: (json['value'] as num).toDouble(),
  previousValue: (json['previous_value'] as num?)?.toDouble(),
  transforms: json['transforms'] == null
      ? null
      : StatTransforms.fromJson(json['transforms'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StatPointToJson(StatPoint instance) => <String, dynamic>{
  'label': instance.label,
  'group': instance.group,
  'value': instance.value,
  'previous_value': instance.previousValue,
  'transforms': instance.transforms?.toJson(),
};

StatTransforms _$StatTransformsFromJson(Map<String, dynamic> json) =>
    StatTransforms(
      cumulative: (json['cumulative'] as num?)?.toDouble(),
      growth: (json['growth'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$StatTransformsToJson(StatTransforms instance) =>
    <String, dynamic>{
      'cumulative': instance.cumulative,
      'growth': instance.growth,
    };
