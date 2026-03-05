import 'package:dio/dio.dart';
import 'package:core/core.dart';

extension FileFieldDioX on FileField {
  MultipartFile? toMultipart() {
    if (data != null) {
      return MultipartFile.fromBytes(data!, filename: fileName ?? 'file', contentType: contentType != null ? DioMediaType.parse(contentType!) : null);
    }
    if (path != null) {
      return MultipartFile.fromFileSync(path!, filename: fileName, contentType: contentType != null ? DioMediaType.parse(contentType!) : null);
    }
    return null;
  }
}

Future<Response<Map<String, dynamic>>> superRequestTransform({
  required Dio dio,
  required String path,
  String method = 'POST',
  required String? baseUrl,
  required Map<String, dynamic> fieldsAndFiles,
}) async {
  final Map<String, dynamic> fields = {};
  final List<FileField> files = [];

  fieldsAndFiles.forEach((key, value) {
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
    method: method
  );
}

Future<Response<Map<String, dynamic>>> superRequest({
  required Dio dio,
  required String path,
  String method = 'POST',
  required String? baseUrl,
  required Map<String, dynamic> fields,
  required Map<String, MultipartFile> files,
}) async {
  final data = FormData.fromMap(
    fields,
    ListFormat.multiCompatible,
  );

  data.files.addAll(files.entries);

  if (method == 'PUT' || method == 'PATCH') {
    data.fields.add(MapEntry("_method", method.toUpperCase()));
  }

  final options = Options(
    method: 'POST',
    contentType: 'multipart/form-data',
    responseType: ResponseType.json,
  );

  return await dio.fetch<Map<String, dynamic>>(
    options.compose(dio.options, path, data: data).copyWith(
      baseUrl: baseUrl ?? dio.options.baseUrl
    )
  );
}
