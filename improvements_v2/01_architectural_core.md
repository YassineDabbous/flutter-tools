# Architectural Core Improvements (V2)

Following the initial set of improvements, the Caky SDK "Core" can be further evolved to support high-performance, enterprise-grade applications.

## 1. Advanced Persistence Layer (Isar)
While `SharedPreferences` is excellent for small settings, moving to a NoSQL database like **Isar** for larger datasets (caching thousands of products, offline sync, etc.) will provide significant performance boosts.

### Implementation Details
- **Libraries**: `isar`, `isar_flutter_libs`, `path_provider`.
- **Steps**:
    1. Define `@Collection` models (e.g., `ProductModel`).
    2. Create `IsarService` class for initialization and basic CRUD.
    3. Use `isar.writeTxn()` for batch performance.
    4. Implement `watchLazy()` for reactive UI updates (linked to V2.2).

## 2. OpenTelemetry & Structured Logging
Integrating a structured logging system that supports **OpenTelemetry** or standard **ELK** formats.

### Implementation Details
- **Libraries**: `logger`, `sentry_flutter`, `firebase_crashlytics`.
- **Steps**:
    1. Create a `CakyLogger` wrapper around the `logger` package.
    2. Implement different outputs: `ConsoleOutput` (dev), `SentryOutput` (prod).
    3. use `Zone` based error catching to pipe all unhandled exceptions to `Sentry`.
    4. Integration: `Core.get<CakyLogger>().log(message)`.

## 3. Remote Configuration & Feature Flags
Applications often need to toggle features or change API endpoints without a full app store release.

### Implementation Details
- **Libraries**: `firebase_remote_config`.
- **Steps**:
    1. Initialize `FirebaseRemoteConfig` in `Initializer`.
    2. Create `RemoteConfigService` with methods like `getString(key)`, `getBool(key)`.
    3. Implement `fetchAndActivate()` strategy (e.g., fetch on startup).
    4. Use flags in UI: `if (Core.get<RemoteConfigService>().isFeatureEnabled('new_payment')) ...`.

## 4. Multi-Tenant Infrastructure
Many SaaS applications require multi-tenancy support.

### Implementation Details
- **Steps**:
    1. Add `tenantId` to `SharedPrefHelper` or `SecureStorage`.
    2. Update `HeaderInterceptor` to automatically inject `X-Tenant-ID`.
    3. Enhance `ModuleConfig` to accept a `tenant` parameter during registration for scoped DI.
    4. Implementation: `Injector.register(..., scope: tenantId)`.

## 5. Background Task Orchestration
Standardizing how the SDK handles long-running background tasks.

### Implementation Details
- **Libraries**: `workmanager`.
- **Steps**:
    1. Configure `Workmanager().initialize()` in `main.dart`.
    2. Create a static `callbackDispatcher` to handle background tasks away from the UI thread.
    3. Register tasks: `Workmanager().registerOneOffTask('sync', 'data_sync_task')`.
    4. Link with `OfflineQueueInterceptor` (linked to V1) for periodic retries of failed requests.
