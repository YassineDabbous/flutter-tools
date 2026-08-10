import 'package:dio/dio.dart';
import 'package:core/core.dart';

extension FileFieldDioX on FileField {
  MultipartFile? toMultipart() {
    if (data != null) {
      return MultipartFile.fromBytes(
        data!,
        filename: fileName ?? 'file',
        contentType: contentType != null
            ? DioMediaType.parse(contentType!)
            : null,
      );
    }
    if (path != null) {
      return MultipartFile.fromFileSync(
        path!,
        filename: fileName,
        contentType: contentType != null
            ? DioMediaType.parse(contentType!)
            : null,
      );
    }
    return null;
  }
}

Future<Response<Map<String, dynamic>>> superRequestTransform({
  required Dio dio,
  required String path,
  String method = 'POST',
  String? baseUrl,
  Map<String, dynamic>? fieldsAndFiles,
  Map<String, dynamic>? queryParameters,
}) async {
  final Map<String, dynamic> fields = {};
  final List<FileField> files = [];

  fieldsAndFiles?.forEach((key, value) {
    if (value is FileField) {
      files.add(value);
    } else {
      fields[key] = value;
    }
  });

  final attachmentsMap = Map<String, MultipartFile>.fromEntries(
    files
        .where((fileField) => fileField.data != null || fileField.path != null)
        .map((fileField) => MapEntry(fileField.key, fileField.toMultipart()!)),
  );

  return await superRequest(
    dio: dio,
    path: path,
    fields: fields,
    files: attachmentsMap,
    baseUrl: baseUrl,
    method: method,
    queryParameters: queryParameters,
  );
}

Future<Response<Map<String, dynamic>>> superRequest({
  required Dio dio,
  required String path,
  String method = 'POST',
  required String? baseUrl,
  Map<String, dynamic>? fields,
  Map<String, MultipartFile>? files,
  Map<String, dynamic>? queryParameters,
}) async {
  dynamic data;
  final isMultipart = (files != null && files.isNotEmpty);

  if (isMultipart) {
    final formData = FormData.fromMap(fields ?? {}, ListFormat.multiCompatible);

    formData.files.addAll(files.entries);

    // Laravel method spoofing
    if (method == 'PUT' || method == 'PATCH') {
      formData.fields.add(MapEntry("_method", method.toUpperCase()));
    }
    data = formData;
  } else if (method == 'GET') {
    data = null;
  } else if (method == 'DELETE') {
    // Allow a JSON body for DELETE (e.g. current_password confirmation).
    data = (fields != null && fields.isNotEmpty) ? fields : null;
  } else {
    data = fields;
    // For simple POST/PUT/PATCH without files, we can use JSON
  }

  final options = Options(
    method: (isMultipart && (method == 'PUT' || method == 'PATCH'))
        ? 'POST'
        : method,
    contentType: isMultipart ? 'multipart/form-data' : 'application/json',
    responseType: ResponseType.json,
  );

  return await dio.fetch<Map<String, dynamic>>(
    options
        .compose(
          dio.options,
          path,
          data: data,
          queryParameters: queryParameters,
        )
        .copyWith(baseUrl: baseUrl ?? dio.options.baseUrl),
  );
}
