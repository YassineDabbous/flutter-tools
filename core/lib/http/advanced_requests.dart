import 'package:dio/dio.dart';
import 'package:core/core.dart';

/// Transforms a mixed map of standard fields and FileField objects into a
/// `multipart/form-data` request handled by `superRequest`.
///
/// This function separates standard fields from file objects, prepares the files
/// as `MultipartFile`, and calls the core request function.
///
/// **Usage:** Allows the caller to treat file and data inputs uniformly.
///
/// @param dio The Dio client instance to use for the request.
/// @param path The API endpoint path (e.g., 'users/1/update').
/// @param method The HTTP method (e.g., 'POST', 'PUT', 'PATCH'). This method is
///   spoofed in the underlying request for backend compatibility (e.g., Laravel).
/// @param baseUrl Optional base URL override.
/// @param fieldsAndFiles A map containing both standard String/int/list fields
///   and custom [FileField] objects for uploads.
/// @returns A [Response] object from Dio, containing the API response data.
Future<Response<Map<String, dynamic>>> superRequestTransform({
  required Dio dio,
  required String path,
  String method = 'POST',
  required String? baseUrl,
  required Map<String, dynamic> fieldsAndFiles,
}) async {
  // 1. Separate fields from files
  final Map<String, dynamic> fields = {};
  final List<FileField> files = [];

  fieldsAndFiles.forEach((key, value) {
    if (value is FileField) {
      files.add(value);
    } else {
      fields[key] = value;
    }
  });

  // 2. Prepare files for Dio (filter out null data and convert to MultipartFile)
  // Ensure 'formPart()' returns a valid MapEntry<String, MultipartFile>
  final attachmentsMap = Map<String, MultipartFile>.fromEntries(
    files
        .where((fileField) => fileField.data != null) // Only valid file data
        .map((fileField) => fileField.formPart()!), // Convert to Dio MultipartFile
  );

  print('-------------------- SuperRequest --------------------');
  print('files count: ${attachmentsMap.length}');
  print('fields count: ${fields.length}');

  return await superRequest(dio: dio, path: path, fields: fields, files: attachmentsMap, baseUrl: baseUrl, method: method);
}

/// Executes a Dio request specifically configured to handle `multipart/form-data`.
///
/// This function constructs the [FormData] object, merges fields and files,
/// and ensures that 'PUT' or 'PATCH' methods are correctly spoofed for backends
/// that require it (like Laravel).
///
/// **Note:** All file upload requests are sent as HTTP 'POST' requests
/// containing the 'multipart/form-data' payload.
///
/// @param dio The Dio client instance.
/// @param path The API endpoint path.
/// @param method The intended HTTP method ('POST', 'PUT', 'PATCH'). Determines
///   if the `_method` field is added to the form data.
/// @param baseUrl Optional base URL override.
/// @param fields The map of standard form fields (String, int, List, etc.).
/// @param files The map of file parts, where the key is the form field name
///   and the value is Dio's [MultipartFile].
/// @returns A [Response] object from Dio.
Future<Response<Map<String, dynamic>>> superRequest({
  required Dio dio,
  required String path,
  String method = 'POST',
  required String? baseUrl,
  required Map<String, dynamic> fields,
  required Map<String, MultipartFile> files,
}) async {
  // 1. Create FormData from regular fields
  final data = FormData.fromMap(
    fields,
    // Crucial for handling list values correctly (e.g., key[]=1, key[]=2)
    ListFormat.multiCompatible,
  );

  data.fields.forEach((element) => print("${element.key}: ${element.value}: ${element.value.runtimeType}"));

  // 2. Add files
  data.files.addAll(files.entries);

  // 3. Spoof PUT/PATCH requests for API compatibility (e.g., Laravel)
  // The actual HTTP request remains POST for multipart/form-data
  if (method == 'PUT' || method == 'PATCH') {
    // Add _method field to trick the backend into recognizing it as PUT/PATCH
    data.fields.add(MapEntry("_method", method.toUpperCase()));
  }

  // 4. Configure and execute the request
  final options = Options(
    // Always use POST when sending FormData
    method: 'POST',
    contentType: 'multipart/form-data',
    responseType: ResponseType.json,
  );

  return await dio.fetch<Map<String, dynamic>>(options.compose(dio.options, path, data: data).copyWith(baseUrl: baseUrl ?? dio.options.baseUrl));
}
