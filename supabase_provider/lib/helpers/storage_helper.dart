import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper for Supabase Storage operations.
class SupabaseStorageHelper {
  final SupabaseClient client;
  SupabaseStorageHelper(this.client);

  /// Uploads a file to a specific bucket and returns the public URL.
  Future<String> upload(String bucket, File file, {String? path}) async {
    final fileName = path ?? '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    await client.storage.from(bucket).upload(fileName, file);
    return client.storage.from(bucket).getPublicUrl(fileName);
  }

  /// Deletes a file from a bucket.
  Future<void> delete(String bucket, String path) async {
    await client.storage.from(bucket).remove([path]);
  }
}
