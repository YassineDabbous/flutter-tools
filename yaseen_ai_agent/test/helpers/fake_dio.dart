// Fakes for provider tests. No network is ever touched.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:yaseen_ai_agent/src/tools/param_spec.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';
import 'package:yaseen_ai_agent/src/tools/tool_response.dart';

/// Dio that answers every request from [responder].
Dio fakeDio(FutureOr<Response<dynamic>> Function(RequestOptions) responder) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          handler.resolve(await responder(options));
        } catch (e) {
          handler.reject(DioException(requestOptions: options, error: e));
        }
      },
    ),
  );
  return dio;
}

/// Dio that fails every request with [error].
Dio failingDio(DioException Function(RequestOptions) error) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(error(options)),
    ),
  );
  return dio;
}

/// Minimal JSON-text tool used by agent hybrid tests.
class SpyTool extends Tool {
  Map<String, dynamic>? seenParams;
  Object? seenMeta;

  SpyTool()
    : super(
        name: 'spy_tool',
        description: 'Records its invocation for assertions.',
        parameters: [
          ParameterSpecification(
            name: 'query',
            type: 'string',
            description: 'The query.',
            required: true,
          ),
        ],
      );

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    seenParams = params;
    return ToolResponse(
      toolName: name,
      isRequestSuccessful: true,
      message: 'spy saw ${params['query']}',
    );
  }
}
