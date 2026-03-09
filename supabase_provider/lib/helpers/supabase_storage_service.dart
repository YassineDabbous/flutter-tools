import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:core/core.dart';

/// Implementation of [StorageService] for Supabase Storage.
class SupabaseStorageService implements StorageService {
  final sb.SupabaseClient client;
  SupabaseStorageService(this.client);

  @override
  Future<String> upload(String bucket, File file, {String? path}) async {
    final fileName =
        path ??
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    await client.storage.from(bucket).upload(fileName, file);
    return fileName; // Return the path/key instead of the full URL
  }

  @override
  Future<void> delete(String bucket, String path) async {
    await client.storage.from(bucket).remove([path]);
  }

  @override
  Future<String> getUrl(
    String bucket,
    String path, {
    StorageOptions? options,
  }) async {
    final isPublic = options?.isPublic ?? true;
    if (isPublic) {
      return client.storage.from(bucket).getPublicUrl(path);
    } else {
      return await client.storage
          .from(bucket)
          .createSignedUrl(path, options?.expires?.inSeconds ?? 3600);
    }
  }

  @override
  Future<List<String>> list(String bucket, {String? path}) async {
    final List<sb.FileObject> objects = await client.storage
        .from(bucket)
        .list(path: path);
    return objects.map((e) => e.name).toList();
  }
}
