# Caky Packages — Improvement Proposals

---

## Priority Matrix

| Priority | Category | Files |
|----------|----------|-------|
| 🔴 **Critical** | Security, reliability, data integrity | [core.md](core.md) |
| 🟠 **High** | Architecture, testability, DX | [architecture.md](architecture.md), [skeleton.md](skeleton.md) |
| 🟡 **Medium** | Usability, performance, missing patterns | [concrete.md](concrete.md), [action.md](action.md) |
| 🟢 **Low** | New features, polish, future-proofing | [new-features.md](new-features.md), [impl.md](impl.md) |

---

## Summary of All Improvements

### Core Package — [Details →](core.md)
1. 🔴 Replace `dynamic` casting in `BaseModel` with type-safe interface
2. 🔴 Add token refresh/rotation mechanism
3. 🔴 Encrypt tokens at rest in SharedPreferences
4. 🟠 Replace global static `Core` with scoped DI (or make it testable)
5. 🟠 Add retry interceptor with exponential backoff
6. 🟠 Make `SharedPrefHelper` generic type system compile-time safe
7. 🟡 Add connectivity-aware request queuing
8. 🟡 Replace `print()` calls with structured logging
9. 🟡 Add `AuthLocalManager.updateToken()` method
10. 🟡 Improve `Config` with validation
11. 🟡 Add `onTokenAboutToExpire` callback
12. 🟡 Improve cache with ETags
13. 🟡 Crash Reporting Registry (Sentry/Crashlytics) — **New**

### Skeleton Package — [Details →](skeleton.md)
1. 🟠 Automatic CRUD Mixin (Zero-Boilerplate) — **New**
2. 🟠 Use Dart 3 sealed classes for exhaustive state matching
3. 🟠 Add repository layer between BLoC and API
4. 🟠 Make `PaginationBloc` support cursor-based pagination
5. 🟡 Add optimistic update support to `CrudBloc`
6. 🟡 Extract common BLoC patterns into a code generator
7. 🟡 Add real-time data sync via WebSocket integration
8. 🟡 Improve `BaseMaker` with attachment tracking
9. 🟡 Add `DynamicQueryRequest` convenience builders
10. 🟡 Add form state preservation (draft saving)

### Concrete Package — [Details →](concrete.md)
1. 🟡 Build a comprehensive design system / component library
2. 🟡 Add accessibility (a11y) support to all widgets
3. 🟡 Add skeleton loading (shimmer) integration
4. 🟢 Add dark mode adaptive colors
5. 🟢 Add responsive breakpoint-aware layouts
6. 🟢 Standardized Empty and Error State components
7. 🟢 Snackbar varieties (success, error, info)

### Action Package — [Details →](action.md)
1. 🟡 Support undo/redo for destructive actions
2. 🟡 Add batch progress tracking
3. 🟡 Support offline queued actions
4. 🟢 Add action audit trail / history
5. 🟢 Action templates / presets

### Impl Packages — [Details →](impl.md)
1. 🟡 Add fallback/mock implementations for all contracts
2. 🟡 Create platform-adaptive contract resolver
3. 🟢 Add `impl_biometric` for biometric authentication
4. 🟢 Add `impl_analytics` for event tracking
5. 🟢 Add `impl_deep_link` for universal links
6. 🟢 Standardize impl package folder structure

### Architecture — [Details →](architecture.md)
1. 🔴 Add comprehensive test infrastructure
2. 🟠 Introduce a `Result` type for error handling
3. 🟠 Add environment-based configuration
4. 🟡 Convention-over-Configuration Cubits — **New**
5. 🟡 Modular Registration System — **New**
6. 🟡 State-to-Header Synchronization — **New**
7. 🟡 Add API versioning support
8. 🟡 Cross-package dependency audit
9. 🟡 Add structured error codes

### New Features — [Details →](new-features.md)
1. 🟠 Admin Dashboard Foundation (Admin SDK) — **New**
2. 🟡 Unified E-commerce Cart & Checkout Foundation — **New**
3. 🟡 Offline-first with local database sync
4. 🟡 Real-time features via WebSocket/SSE
5. 🟡 Feature flags system
6. 🟢 App update checker
7. 🟢 Crash reporting integration
8. 🟢 In-app feedback/bug reporting
9. 🟢 Smart prefetching
