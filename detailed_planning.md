# Detailed Migration & Architecture Plan: Multi-Provider SDK

This document outlines the radical refactoring of the current SDK into a professional, backend-agnostic framework. The goal is to separate pure business logic and UI patterns from specific data providers (Laravel/Supabase).

---

## 1. New Package Hierarchy

We will maintain four primary packages. All "caky" prefixes are removed to ensure a general-purpose professional feel.

### 📦 `core`
**Responsibility**: The absolute truth and foundation. 
- **Dependencies**: `equatable`, `logger`, `injector`.
- **Key Modules**:
  - `Result<S, E>`: The universal success/failure union type.
  - `Identifiable<ID>` & `Labelable`: Atomic interfaces for generic IDs.
  - `BaseModel<ID>`: Base class for all data objects.
  - `AppFailure`: Unified domain failure hierarchy (Auth, Network, Validation).
  - `EnvConfig` & `ModuleConfig`: Basic DI and environment definitions.
  - `Logger`: Minimal logging abstraction.

### 📦 `skeleton`
**Responsibility**: Application logic, state management, and interface contracts.
- **Dependencies**: `core`, `flutter_bloc`, `rxdart`.
- **Key Modules**:
  - `BaseApiService<M, E, S, ID>`: **Pure Interface**. Generic over Model, Requests, and ID.
  - `AppState`: Standard sealed states (Loading, Success, Error).
  - `PaginationBloc` & `BaseCrudCubit`: Pure logic using generic base APIs.
  - `BaseMaker<M, R, ID>`: Form and attachment management logic.
  - `OptimisticCrud` & `RealtimeSync`: Logic mixins.
  - `DynamicQueryRequest`: Abstracted query builder logic.

### 📦 `laravel_provider`
**Responsibility**: Implementation of `skeleton` interfaces using REST/Dio/Retrofit.
- **Dependencies**: `skeleton`, `dio`, `retrofit`, `json_annotation`.
- **Key Modules**:
  - `LaravelApiService`: Implementation of `BaseApiService` with Retrofit annotations.
  - `DioClientFactory`: Centralized configuration of Dio.
  - `Interceptors`: Retry with backoff, Offline Queue, Token Refresh.
  - `LaravelErrorMapper`: Mapping Dio errors to `AppFailure` types.

### 📦 `supabase_provider`
**Responsibility**: Implementation of `skeleton` interfaces using the Supabase SDK.
- **Dependencies**: `skeleton`, `supabase_flutter`.
- **Key Modules**:
  - `SupabaseApiService`: Implementation Using `SupabaseClient` with internal error mapping.
  - `RealtimeObserver`: Linking Supabase streams to `PaginationBloc`.
  - `SupabaseStorageHelper`: Direct bucket uploads for `BaseMaker` attachments.
  - `SupabaseAuthBridge`: Syncing Supabase Session with `AuthLocalManager`.

---

## 2. Radical Improvements (Nitty-Gritty)

### 2.1 Standardized Error Handling
Each provider must map its backend-specific errors (DioException, PostgrestException) to a set of **Unified Failures** (AppFailure) defined in `core`:
- `NetworkFailure`
- `AuthFailure`
- `ValidationFailure` (with a unified ErrorBag)
- `ServerFailure`

### 2.2 API Service "Generic Purity"
The `BaseApiService` methods use generic `ID` types to support both Laravel (int) and Supabase (UUID).

### 2.3 Maker 2.0 (Attachment Streams)
Move to an observable attachment system where the UI can listen to individual file upload progress.

### 2.4 The "Provider Registry"
Register backend-specific implementations during app initialization.
```dart
// main.dart
Initializer.run([
  core_module(),
  skeleton_module(),
  supabase_provider_module(url: '...', key: '...'), // Hydrates interfaces
]);
```

---

## 3. Class Migration Map

| Class | Original Home | New Home | Change Description |
| :--- | :--- | :--- | :--- |
| `Result` | `core/utils` | `core/utils` | No change. |
| `BaseModel` | `core/models` | `skeleton/bases` | Generic ID support. |
| `BaseApiService` | `skeleton/bases` | `skeleton/bases` | **Crucial**: Generic ID type added. |
| `AppFailure` | N/A | `core/logic` | New naming to avoid collisions. |
| `PaginationBloc` | `skeleton/bases/bloc` | `skeleton/bases/bloc` | Generic ID support added. |

---

## 4. Migration Execution Steps

### Phase 1: The Core Purge
1. Create new `laravel_provider` package.
2. Move `dio`, `retrofit`, and `json_serializable` to `laravel_provider`.
3. Extract `Http/Interceptors` and Laravel-specific `BaseResponse` logic.

### Phase 2: Skeleton Abstraction
1. Convert `BaseApiService` into a "Naked" abstract class with generic ID.
2. Refactor `PaginationBloc` to handle generic `PaginatedResponse` objects.
3. Decouple `BaseMaker` from any multi-part assumptions and genericize ID.

### Phase 3: Supabase Implementation
1. Implement `SupabaseApiService` with generic ID.
2. Implement `SupabaseAuthBridge`.

### Phase 4: UI Unification (Concrete Package)
1. Ensure the `concrete` package (UI) ONLY imports `skeleton` and `core`.

---

**Conclusion**: This plan transforms the SDK into a powerful, multi-provider engine that can be extended infinitely without polluting core logic.
