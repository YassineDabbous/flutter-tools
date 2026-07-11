import 'package:json_annotation/json_annotation.dart';

part 'manage_relation_request.g.dart';

/// Represents the payload for the generic relationship management endpoint.
@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class ManageRelationRequest {
  /// The name of the relationship to manage (e.g., "roles").
  final String name;

  /// The action to perform: "link", "unlink", or null for sync/toggle.
  final String? action;

  /// The list of IDs to attach, detach, sync, or associate.
  final List<int> ids;

  /// Optional additional data for pivot tables.
  final Map<String, dynamic>? additional;

  ManageRelationRequest({
    required this.name,
    this.action,
    required this.ids,
    this.additional,
  });

  /// This class is only for sending data, so we only need toJson().
  Map<String, dynamic> toJson() => _$ManageRelationRequestToJson(this);
}
