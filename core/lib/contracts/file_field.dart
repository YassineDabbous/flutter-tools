import 'dart:typed_data';
import '../constants/media_type.dart';

/// Generic representation of a file for upload across different providers.
///
/// Enhanced with UI properties to maintain compatibility with existing widgets.
class FileField {
  final String key;
  final String? path;
  final Uint8List? data;
  final String? fileName;
  final String? contentType;

  // UI & State properties
  final String? fullUrl;
  final FileType type;
  final bool shouldBeRemoved;

  FileField({
    required this.key,
    this.path,
    this.data,
    this.fileName,
    this.contentType,
    this.fullUrl,
    this.type = FileType.UNKNOWN,
    this.shouldBeRemoved = false,
  });

  bool get isPath => path != null;
  bool get isBytes => data != null;
  bool get isOnline => fullUrl != null;

  /// Helper to create a copy with changed values.
  FileField copyWith({
    String? key,
    String? path,
    Uint8List? data,
    String? fileName,
    String? contentType,
    String? fullUrl,
    FileType? type,
    bool? shouldBeRemoved,
  }) {
    return FileField(
      key: key ?? this.key,
      path: path ?? this.path,
      data: data ?? this.data,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      fullUrl: fullUrl ?? this.fullUrl,
      type: type ?? this.type,
      shouldBeRemoved: shouldBeRemoved ?? this.shouldBeRemoved,
    );
  }
}
