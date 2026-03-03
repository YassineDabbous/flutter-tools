import 'dart:typed_data';

import 'package:core/constants/constants.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:json_annotation/json_annotation.dart';

class FileField {
  @override
  String toString() => fullUrl ?? super.toString();

  FileType type;
  final String name;
  final String? fullUrl;
  Uint8List? data;

  /// Returns true if the file is an existing file, represented by a URL.
  bool get isOnline => fullUrl != null;

  /// Flag to indicate if the online file should be deleted on update.
  bool shouldBeRemoved = false;

  FileField({required this.name, required this.type, this.fullUrl, this.data});

  /// Creates a copy of this FileField, optionally replacing its properties.
  FileField copyWith({String? name, FileType? type, String? fullUrl, Uint8List? data}) =>
      FileField(name: name ?? this.name, type: type ?? this.type, data: data ?? this.data, fullUrl: fullUrl ?? this.fullUrl);

  /// Converts the file data into a Dio [MapEntry] for multipart upload.
  /// Returns null if [data] is null (no file to upload).
  MapEntry<String, MultipartFile>? formPart() {
    if (data == null) return null;
    return MapEntry(
      name,
      MultipartFile.fromBytes(
        data!,
        filename: '$name.${type.extension()}', // Use type extension for filename
        contentType: MediaType.parse(type.mediaType()), // Use type media type for MIME type
      ),
    );
  }
}

class FileFieldConverter implements JsonConverter<FileField, String?> {
  final String name;
  final FileType type;
  final String? defaultUrl;

  /// Converter for fields where the JSON value is the file's URL string.
  const FileFieldConverter({required this.name, required this.type, this.defaultUrl});

  /// Utility converter for cases where only a URL is needed (e.g., in lists).
  const FileFieldConverter.justForUrl() : name = 'should-not-be-used', type = FileType.UNKNOWN, defaultUrl = null;

  @override
  FileField fromJson(String? url) => FileField(fullUrl: url ?? defaultUrl, name: name, type: type);

  @override
  // WARNING: This forces a crash if fullUrl is null. Consider: object.fullUrl ?? ''
  String toJson(FileField object) => object.fullUrl!;
}
