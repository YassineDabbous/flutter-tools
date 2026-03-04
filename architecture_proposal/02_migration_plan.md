# Migration Plan: Decoupling the SDK

If we decide to proceed with the separation, here is the technical roadmap to ensure a smooth transition.

## Phase 1: Pure Core Extraction
- Move all Dio, Retrofit, and HTTP-related code from `packages/core` to a new `packages/caky_laravel`.
- Clean up `core/pubspec.yaml` to remove nearly all dependencies except `injector`, `flutter_bloc`, and `equatable`.

## Phase 2: Interface Generalization in Skeleton
- Remove Retrofit annotations (`@GET`, `@POST`) from `BaseApiService`. This becomes a pure abstract class.
- Abstract the `ExceptionHandler`. Instead of a mixin checking for `DioException`, providers will implement a `parseError(dynamic error)` method.
- Update `BasicResponse` to be less opinionated about the Laravel-specific `code/message/error` keys, or move them to the provider.

## Phase 3: Creating the Laravel Provider
- `caky_laravel` will host the Retrofit implementation.
- It will export the interceptors we built (Retry, Offline, Refresh).
- It will provide the `Dio` configuration that gets injected into the `BaseApiService`.

## Phase 4: Creating the Supabase Provider
- `caky_supabase` will be initialized with the documentation from the `supabase_integration` research.
- It will implement the pure `BaseApiService` using the Supabase SDK.
- It will provide specialized helpers for Real-time and Storage.

## Phase 5: Developer Experience
- Update the documentation to show how to Choose a Provider:
  - **Laravel**: Add `caky_core`, `caky_skeleton`, `caky_laravel`.
  - **Supabase**: Add `caky_core`, `caky_skeleton`, `caky_supabase`.

## Summary
The goal is that **neither Core nor Skeleton should know about the internet**. They only know about **Data Contracts**.
