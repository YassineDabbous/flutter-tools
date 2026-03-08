import 'package:flutter/material.dart';
import 'package:skeleton/skeleton.dart';

abstract class BaseAction {
  late ActionRequest _request;
  final Function(dynamic)? onHandled;
  final BaseController controller;
  final String? title;
  final String? description;
  final String route;
  bool requireConfirmation = true;
  final Widget Function(BaseAction)? formBuilder;

  BaseAction({
    required this.controller,
    required this.route,
    this.title,
    this.description,
    this.onHandled,
    this.formBuilder,
  }) {
    _request = ActionRequest(
      action: route,
      type: controller.type,
      keys: controller.initiallySelectedIds,
      filter: controller.request.toJson(),
    );
  }

  ActionRequest request() {
    _request.keys = controller.selectedIds;
    _request.filter = controller.request.toJson();
    return _request;
  }

  dynamic get(String key) => _request.payload?[key];
  void set(String key, dynamic value) {
    _request.payload ??= {};
    _request.payload?[key] = value;
  }
}

abstract class ActionApiService
    extends BaseApiService<dynamic, dynamic, dynamic, dynamic> {
  Future<ApiResponse<dynamic>> handleAction(ActionRequest request);
}

class GeneralAction extends BaseAction {
  GeneralAction({
    required super.controller,
    required super.route,
    super.title,
    super.description,
    super.onHandled,
    super.formBuilder,
  });
}

class ActionRequest extends SuperModel<ActionRequest> {
  String action;
  String type;
  List<dynamic>? keys;
  Map<String, dynamic>? filter;
  Map<String, dynamic>? payload;

  ActionRequest({
    required this.action,
    required this.type,
    this.keys,
    this.filter,
    this.payload,
  });
  // @override
  // Map<String, dynamic> toJson() => {'action': action, 'type': type, 'keys': keys, 'filter': filter, 'payload': payload};
  @override
  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    if (payload != null) {
      json.addAll(Map.of(payload!)..removeWhere((key, value) => value == null));
    }
    if (filter != null) {
      // print('filter ====>');
      // print(filter.toString());
      json.addAll(
        Map.of(filter!)
          ..removeWhere((key, value) => value == null)
          ..removeWhere((key, value) => value == ''),
      );
    }
    json.addAll({'_action_': action, '_type_': type, '_keys_': keys});

    //
    //
    // @TODO: ugle fix for ShipmentSearchRequest.statuses
    json = json.map((key, value) {
      if (key.endsWith('[]')) {
        key = key.substring(0, key.length - 2);
      }
      return MapEntry(key, value);
    });
    //
    return json;
  }

  @override
  ActionRequest fromJson(Map<String, dynamic> json) => ActionRequest(
    action: json['action'],
    type: json['type'],
    keys: json['keys'],
    filter: json['filter'],
    payload: json['payload'],
  );
  //
  // factory ActionRequest.newInstance() => ActionRequest();
  // factory ActionRequest.fromJson(Map<String, dynamic> json) => ActionRequest(id: json['id'], type: json['type']);
}
