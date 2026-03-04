# RPC (Database Functions) & Edge Functions

Sometimes standard CRUD isn't enough. Supabase allows running logic on the server via RPC (Postgres functions) or Edge Functions (TypeScript/Deno).

## 1. RPC inside BaseApiService

Caky's `BaseApiService` can include methods that call RPCs. This keeps the Cubit logic clean.

### Implementation Pattern

```dart
class SupabaseProductService extends BaseApiService<Product, ...> {
  // ... standard CRUD ...

  /// Call a custom PG function to calculate total inventory value
  Future<BasicResponse<double>> getTotalValue() async {
    final response = await client.rpc('calculate_inventory_value');
    return BasicResponse(data: response as double);
  }
}
```

## 2. Edge Functions for Complex Logic

Edge Functions are perfect for integrations (Stripe, SendGrid) or heavy processing. They behave like standard REST endpoints but are called via the Supabase SDK.

### Pattern: Custom Endpoint Integration

```dart
class StripeService {
  final SupabaseClient client;
  StripeService(this.client);

  Future<BasicResponse<String>> createCheckoutSession(User user) async {
    final response = await client.functions.invoke(
      'create-stripe-session',
      body: {'userId': user.id},
    );
    
    if (response.status != 200) throw ServerException(message: 'Edge Function Failed');
    return BasicResponse(data: response.data['url']);
  }
}
```

## 3. Why these don't break Caky?

1.  **Uniform States**: Whether the data comes from a table or an Edge function, it's mapped to a `BasicResponse` and handled by the same `LoadingState`/`LoadedState` pattern in the UI.
2.  **Decoupling**: The UI never knows if it's talking to a database table or a TypeScript function in the cloud. It only sees the `BaseApiService` contract.
3.  **Authentication**: Both RPC and Edge Functions automatically receive the user's JWT from the Supabase SDK, so Caky's `AuthLocalManager` remains the source of truth for the "Logged In" status.
