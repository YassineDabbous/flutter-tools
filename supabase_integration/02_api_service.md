# Implementing BaseApiService with Supabase

In the Caky SDK, `BaseApiService` is the contract for all data operations. To use Supabase, you create a concrete class that uses `SupabaseClient` to fulfill this contract.

## Example: SupabaseProductService

Instead of using Retrofit annotations, you manually implement the methods:

```dart
class SupabaseProductService implements BaseApiService<Product, ProductRequest, ProductQuery> {
  final SupabaseClient client;
  SupabaseProductService(this.client);

  @override
  Future<BasicResponse<PaginationResponse<Product>>> paging({
    required int page,
    required ProductQuery request,
  }) async {
    final from = (page - 1) * request.perPage;
    final to = from + request.perPage - 1;

    final response = await client
        .from('products')
        .select('*', const FetchOptions(count: CountOption.exact))
        .range(from, to)
        .order(request.orderBy ?? 'created_at');

    final data = (response as List).map((e) => Product.fromJson(e)).toList();
    final count = response.count ?? 0;

    return BasicResponse(
      data: PaginationResponse(
        data: data,
        total: count,
        perPage: request.perPage,
        currentPage: page,
        lastPage: (count / request.perPage).ceil(),
      ),
    );
  }

  @override
  Future<BasicResponse<int>> create(ProductRequest request) async {
    final response = await client
        .from('products')
        .insert(request.toJson())
        .select('id')
        .single();
    
    return BasicResponse(data: response['id']);
  }

  // Implementation for update, delete, show...
}
```

## Why this approach?

1.  **Zero Change to Blocs**: Your `ProductCubit` remains exactly the same. It still calls `service.paging()`.
2.  **Type Safety**: You maintain the `Product` model and `ProductRequest` models.
3.  **Flexibility**: You can use Supabase's `.rpc()` for complex operations while still returning a standard `BasicResponse`.

## Mapping SearchRequest

Since `SearchRequest` (e.g., `DynamicQueryRequest`) is a plain Dart object, you can create a helper to apply its filters to a Supabase query:

```dart
extension SupabaseFilter on PostgrestFilterBuilder {
  PostgrestFilterBuilder applyCakyQuery(DynamicQueryRequest? request) {
    if (request == null) return this;
    var query = this;
    // Map request.where to Supabase .eq(), .ilike(), etc.
    return query;
  }
}
```
