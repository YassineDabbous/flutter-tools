# Developer Experience Improvements

Improvements to testing, tooling, documentation, and the overall developer workflow.

---

## 1. Zero Unit Tests

**Problem:** None of the 7 packages have any unit tests. The `pubspec.yaml` files include `flutter_test` in `dev_dependencies` but there are no `test/` directories with actual test files.

**Suggestion:** Add tests in priority order:

| Priority | What to Test | Why |
|----------|-------------|-----|
| 🔴 P0 | `LaravelErrorMapper` | Mapping logic is easy to get wrong; one wrong status code check = silent auth failures |
| 🔴 P0 | `AuthLocalManager` | Local persistence of tokens; bugs here = users randomly logged out |
| 🔴 P0 | `ActionRequest.toJson()` | Has mutation bug (see code_quality.md #4), test would catch it |
| 🟡 P1 | `RetryInterceptor` | Exponential backoff edge cases, max retries |
| 🟡 P1 | `TokenRefreshInterceptor` | Race conditions, concurrent refresh prevention |
| 🟡 P1 | `PaginationBloc` | Page tracking, max reached detection, offline paging |
| 🟢 P2 | `BaseMaker` / `BaseController` | Merge logic, filter persistence |
| 🟢 P2 | `Result` | Pattern matching, edge cases |

**Example test structure:**

```
core/test/
├── auth/
│   └── auth_local_manager_test.dart
├── di/
│   └── injector_test.dart
└── logic/
    └── failures_test.dart

skeleton/test/
├── bases/
│   ├── jsonable_test.dart
│   └── base_controller_test.dart
└── bloc/
    └── pagination_bloc_test.dart

laravel_provider/test/
├── mappers/
│   └── error_mapper_test.dart
└── interceptors/
    ├── retry_interceptor_test.dart
    └── auth_interceptor_test.dart
```

---

## 2. No Example App

**Problem:** There are demo apps in `.trash/` but no maintained example app in the main package tree. New developers have no reference for how to wire everything together.

**Suggestion:** Create a `example/` directory with a minimal working app:

```
example/
├── lib/
│   ├── main.dart
│   ├── config.dart          (extends Config)
│   ├── registrar.dart       (extends Registrar)
│   └── features/
│       └── products/
│           ├── models/
│           ├── api/
│           ├── blocs/
│           └── ui/
├── pubspec.yaml
└── README.md
```

This serves as both documentation and integration test.

---

## 3. Add a Code Generation CLI

**Problem:** Creating a new feature requires creating 6+ files manually (Model, Request, Filter, ApiService, Cubit, Controller, Maker). This is tedious and error-prone.

**Suggestion:** Create a `mason` brick or a simple CLI:

```bash
# Generate a full feature scaffold:
dart run sdk_gen feature product --id-type int --provider laravel

# Generates:
#   models/product.dart
#   models/product_request.dart
#   models/product_filter.dart
#   api/product_api_service.dart
#   blocs/product_cubit.dart
#   blocs/product_list_cubit.dart
#   controllers/product_controller.dart
#   controllers/product_maker.dart
```

This could use the `template_pack` impl package as a foundation.

---

## 4. Missing Dart Doc Comments on Public APIs

**Problem:** Many public classes and methods lack doc comments:

| File | Missing Docs |
|------|-------------|
| `component_handler.dart` | Class-level doc |
| `filter_handler.dart` | Most methods |
| `form_handler.dart` | `fillForm()`, `fillMaker()` |
| `concrete/ui/*` | Most widget classes |
| `skeleton/bases/bloc/bloc.dart` | Barrel file, no overview |

**Suggestion:** At minimum, every public class and every abstract method should have a `///` doc comment explaining its purpose and when to use it. Consider running `dart doc` and checking coverage.

---

## 5. No Linting Rules Defined

**Problem:** The packages use `flutter_lints` which is the basic rule set. There are no custom analysis options for:
- Enforcing documentation
- Preventing `dynamic` usage where possible
- Enforcing immutability patterns

**Suggestion:** Create a shared `analysis_options.yaml` at the packages root:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Documentation
    public_member_api_docs: true

    # Type safety
    avoid_dynamic_calls: true
    strict_raw_type: true
    
    # Immutability
    prefer_final_locals: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    
    # Clean code
    avoid_print: true
    prefer_single_quotes: true
    sort_constructors_first: true
    unawaited_futures: true
    
analyzer:
  errors:
    public_member_api_docs: warning
```

---

## 6. No CHANGELOG or Versioning Strategy

**Problem:** All packages are at `version: 0.0.1` with no `CHANGELOG.md`. When bugs are fixed or features added, there's no way to track what changed between versions.

**Suggestion:** 
- Add a `CHANGELOG.md` to each package
- Use semantic versioning
- Consider using `melos` for managing the monorepo

```bash
# Install melos
dart pub global activate melos

# melos.yaml at the root
name: caky_sdk
packages:
  - packages/*
  - packages/impl/*
```

Melos provides:
- Automated versioning across packages
- Coordinated publishing
- Running commands across all packages (`melos run test`)
- Dependency graph visualization

---

## 7. Dead/Commented Code Cleanup

Significant amount of commented-out code across the codebase:

| File | Lines | What |
|------|-------|------|
| `base_cubit_sealed.dart` | 78-91 | Entire `FullCubit` / `FullState` classes |
| `dynamic_query_request.dart` | 5, 7, 125-129 | `@JsonSerializable` and factory methods |
| `base_pagination_cubit.dart` | 112-115 | Old list clearing logic |
| `action_handler.dart` | 21-23, 52-56, 100-107 | Old action logic |
| `base_action.dart` | 42-44 | Old validate/fill/run callbacks |

This code creates noise and confuses developers who may not know if it's "work in progress" or "deprecated". Consider either completing it or removing it with a `// TODO:` comment explaining the intent.

---

## 8. Consistent Barrel File Pattern

**Problem:** Barrel file patterns are inconsistent across packages:

| Package | Style |
|---------|-------|
| `core` | `core.dart` exports everything |
| `skeleton` | `skeleton.dart` exports handlers + bases + http |
| `concrete` | `concrete.dart` re-exports `core` (problematic) |
| `action` | `action.dart` exports logic + ui |
| `laravel_provider` | `laravel_provider.dart` exports everything |
| `supabase_provider` | `supabase_provider.dart` exports everything |

**Suggestion:** Standardize on one of these patterns:

```dart
// Option A: Single barrel (current approach, but consistent)
export 'src/...';

// Option B: Layered barrels (better for large packages)
// consumer imports specific layer:
import 'package:skeleton/bases.dart';
import 'package:skeleton/http.dart';
import 'package:skeleton/handlers.dart';
```
