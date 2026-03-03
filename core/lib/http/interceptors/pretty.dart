import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class PrettyLogInterceptor extends PrettyDioLogger {
  PrettyLogInterceptor({
    super.requestHeader = true,
    super.requestBody = true,
    super.responseBody = true,
    super.responseHeader = true,
    super.error = true,
    super.compact = true,
    super.maxWidth = 160,
    super.logPrint,
  });

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) { 
    if(response.realUri.path.contains('home') || response.realUri.path.contains('customization')) {
      // Skip logging for 'home' and 'customization' endpoint responses
      handler.next(response);
      return;
    }
    super.onResponse(response, handler);
  }

 
}
