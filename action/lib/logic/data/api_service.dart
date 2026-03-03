import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

class ActionApiService extends BaseApiService {
  final Dio _dio;
  String? baseUrl;
  ActionApiService(this._dio, {this.baseUrl}) : super(_dio, baseUrl: baseUrl);
  factory ActionApiService.instance() => ActionApiService(Core.get<BaseDio>().dio, baseUrl: Core.get<Config>().baseUrl);

  Future<BasicResponse<dynamic>> handleAction(ActionRequest request) async {
    final result = await superRequestTransform(dio: _dio, path: '/_action_', fieldsAndFiles: request.toJson(), method: 'POST', baseUrl: baseUrl);
    return BasicResponse<dynamic>.fromJson(result.data!, (json) => json as dynamic);
  }
}
