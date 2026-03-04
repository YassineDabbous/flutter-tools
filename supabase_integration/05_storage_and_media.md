# Supabase Storage & Media Helpers

Supabase Storage integrates perfectly with Caky's `BaseMaker` attachment system. Instead of multi-part form data (typical for Laravel), we use direct bucket uploads.

## 1. SupabaseStorageHelper

Instead of building this logic into every Maker, we create a centralized helper.

```dart
class SupabaseStorageHelper {
  final SupabaseClient client;
  SupabaseStorageHelper(this.client);

  Future<String> upload(String bucket, File file, {String? path}) async {
    final fileName = path ?? '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    await client.storage.from(bucket).upload(fileName, file);
    return client.storage.from(bucket).getPublicUrl(fileName);
  }
}
```

## 2. Integrating with BaseMaker

When using `BaseMaker` with Supabase, the "Request" model typically expects a URL string for the image/file field.

### Implementation Pattern

```dart
class ProductMaker extends BaseMaker<Product, ProductRequest> {
  // ...
  
  Future<void> saveWithUpload(SupabaseStorageHelper storage) async {
    if (hasAttachments) {
      for (var entry in attachments.entries) {
        if (entry.value is File) {
          final url = await storage.upload('products', entry.value);
          // Update the request object with the new URL
          (form as dynamic).itemImage = url; 
        }
      }
    }
  }
}
```

## 3. Image Optimization on the Fly

Supabase supports dynamic image resizing via URL parameters. We can add an extension to facilitate this in Caky's UI.

```dart
extension SupabaseImageTransform on String {
  String thumbnail({int width = 200, int height = 200}) {
    return '$this?width=$width&height=$height&resize=contain';
  }
}
```

## 4. Handling Private Buckets

If a bucket is private, you need a signed URL. Caky's `ShimmerHelper` or a custom `SupabaseImage` widget can handle the async loading of a signed URL before displaying the image.
