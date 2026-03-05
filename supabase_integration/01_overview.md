# Supabase Integration Overview

The SDK is designed to be **Backend Agnostic**. Although the default implementation targets Laravel/REST APIs via Dio and Retrofit, the core architectural patterns (Cubits, Blocs, Makers, and Sealed States) are fully compatible with Supabase.

## What works currently without changes?

Most of the "logic" and "UI" layers in the SDK work perfectly with Supabase because they depend on **Interfaces**, not concrete implementations:

1.  **Cubits & Blocs**: `BaseCrudCubit`, `PaginationBloc`, and `AutoCrudBloc` (customized) rely on `BaseApiService`. As long as you provide a Supabase-backed implementation of this interface, the Blocs will work as-is.
2.  **State Management**: `AppState`, `LoadingState`, `ErrorState`, etc., are generic and don't care about the data source.
3.  **Makers**: `BaseMaker` and its attachment tracking work independently of the backend.
4.  **UI Components**: `ShimmerHelper`, `AppSnackbars`, and states in the `concrete` package are completely backend-independent.

## What needs to be added/modified?

To fully transition to Supabase, you only need to provide "Supabase Versions" of the following infrastructure components:

| Component | Current (Laravel) | Supabase Version |
| :--- | :--- | :--- |
| **Network Client** | `Dio` | `SupabaseClient` |
| **API Interface** | `Retrofit` (Generated) | Custom Implementation of `BaseApiService` |
| **Auth Manager** | `AuthLocalManager` | `SupabaseAuthBridge` |
| **Error Handling** | `LaravelErrorMapper` | `SupabaseApiService` internal mapper |

## The "Same Interface" Strategy

The power of the `skeleton` is that it defines a contract. By creating a library that implements the `BaseApiService` using `supabase-flutter`, you can swap the entire backend of an app by just changing the Dependency Injection (DI) registration.
