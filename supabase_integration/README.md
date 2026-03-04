# Supabase Integration Roadmap

This guide explains how to adapt the Caky SDK for Supabase.

## Documentation Index

| File | Topic |
| :--- | :--- |
| [01 Overview](./01_overview.md) | Backend-agnostic strategy and what's reusable. |
| [02 API Service](./02_api_service.md) | Implementing `BaseApiService` using `SupabaseClient`. |
| [03 Auth & Errors](./03_auth_and_errors.md) | Supabase Auth listeners and Error mapping. |

## Implementation Checklist

1.  **Dependency Injection**: Initialize `Supabase` in `main.dart` and register the `SupabaseClient` in the `Core` DI container.
2.  **Auth Management**: Create a `SupabaseAuthManager` class (see `03_auth_and_errors.md`) and register it as the provider for `AuthLocalManager`.
3.  **API Layer**:
    - Avoid using `retrofit`.
    - Create a custom Library/Package for Supabase services.
    - Implement `BaseApiService` for your models (see `02_api_service.md`).
4.  **Error Handling**: Create a `SupabaseExceptionHandler` mixin and add it to your services.
5.  **UI Verification**: Ensure all `EmptyState` and `ErrorState` widgets in the `concrete` package continue to render as expected.

## Summary

The Caky SDK's clean separation of concerns makes Supabase integration straightforward. By focusing on **Interfaces** rather than implementations, you can use the same Cubits, Blocs, and UI widgets for any Supabase project.
