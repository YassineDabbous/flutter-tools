import 'dart:io';

/// Options for storage operations like resizing or quality adjustment.
class StorageOptions {
  final bool isPublic;
  final Duration? expires;
  final Map<String, dynamic>? transform;

  const StorageOptions({this.isPublic = true, this.expires, this.transform});
}

/// A standard interface for file storage operations.
abstract class StorageService {
  /// Uploads a file to a specific bucket and returns the file path/key.
  Future<String> upload(String bucket, File file, {String? path});

  /// Deletes a file from a bucket by its path.
  Future<void> delete(String bucket, String path);

  /// Resolves a file path into a usable URL (public or signed).
  Future<String> getUrl(String bucket, String path, {StorageOptions? options});

  /// List all files in a specific directory/bucket.
  Future<List<String>> list(String bucket, {String? path});
}
