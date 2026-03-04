# Caky Multi-Provider Architecture Proposal

Currently, the `core` and `skeleton` packages are tightly coupled with **Dio** and **Retrofit**. This ensures a solid experience for Laravel developers but makes it difficult to use other backends like **Supabase** without pulling in unnecessary dependencies.

## 1. The Separation Strategy

I propose splitting the SDK into **Core Modules** and **Provider Modules**.

### A. Core Modules (Backend Agnostic)

1.  **`caky_core`**: Contains the pure foundation.
    - Result types, Base Models (`Identifiable`).
    - Standard Dependency Injection patterns.
    - Abstract Storage interfaces.
    - **No Dependencies**: No Dio, No Supabase, No Retrofit.

2.  **`caky_skeleton`**: Contains the logic and state patterns.
    - Interfaces: `BaseApiService`, `AuthLocalManager`.
    - Logic: `PaginationBloc`, `BaseCrudCubit`, `UndoManager`.
    - UI Support: `CakyState` (Sealed states for Loading/Error).
    - **No Dependencies**: Only depends on `caky_core`.

### B. Provider Modules (Specific Integrations)

3.  **`caky_laravel`**: 
    - Implementation of `BaseApiService` using **Retrofit**.
    - Robust interceptors (Retry, Offline Queue, Token Refresh).
    - Laravel-specific JSON parsing (`BasicResponse`, `PaginationResponse`).

4.  **`caky_supabase`**:
    - Implementation of `BaseApiService` using **SupabaseClient**.
    - Real-time stream integration for BLoCs.
    - Supabase Auth sync and Storage helpers.

## 2. Advantages of this Approach

| Benefit | Description |
| :--- | :--- |
| **Slim Payload** | Supabase apps don't include Dio; Laravel apps don't include Supabase SDK. |
| **Pure Interfaces** | Forces the SDK to have high-quality, generic interfaces. |
| **Future Proof** | Adding a new provider (GraphQL, Firebase, AppWrite) is just a new package away. |
| **Easier Maintenance** | A breaking change in a backend SDK only affects one provider package. |

## 3. Potential Challenges

- **Breaking Assumption**: Currently, `ExceptionHandler` assumes `DioException`. We would need to define caky-specific `NetworkException` types that providers map to.
- **Project Structure**: Developers now handle 3 paths in `pubspec.yaml` instead of 2.
- **Model Compatibility**: Ensured by the `Jsonable` and `Identifiable` interfaces in `core`.

## 4. Final Recommendation

**YES**, separating them is the superior architectural choice. It evolves Caky from a "Laravel Toolset" into a professional "Universal Flutter SDK Framework".
