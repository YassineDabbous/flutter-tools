# Caky Packages — Improvement Proposals

> Actionable improvements, refactoring ideas, and new feature proposals for the Caky SDK. Organized by package and priority.

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

### Skeleton Package — [Details →](skeleton.md)
1. 🟠 Use Dart 3 sealed classes for exhaustive state pattern matching
2. 🟠 Add repository layer between BLoC and API
3. 🟠 Make `PaginationBloc` support cursor-based pagination
4. 🟡 Add optimistic update support to `CrudBloc`
5. 🟡 Extract common BLoC patterns into a code generator
6. 🟡 Add real-time data sync via WebSocket integration

### Concrete Package — [Details →](concrete.md)
1. 🟡 Build a comprehensive design system / component library
2. 🟡 Add accessibility (a11y) support to all widgets
3. 🟡 Add skeleton loading (shimmer) integration for all list/grid widgets
4. 🟢 Add dark mode adaptive colors to all components
5. 🟢 Add responsive breakpoint-aware layouts

### Action Package — [Details →](action.md)
1. 🟡 Support undo/redo for destructive actions
2. 🟡 Add batch progress tracking (progress bar for bulk operations)
3. 🟡 Support offline queued actions
4. 🟢 Add action audit trail / history

### Impl Packages — [Details →](impl.md)
1. 🟡 Add fallback/mock implementations for all contracts
2. 🟡 Create platform-adaptive contract resolver
3. 🟢 Add impl_biometric for biometric authentication
4. 🟢 Add impl_analytics for event tracking

### Architecture — [Details →](architecture.md)
1. 🔴 Add comprehensive test infrastructure
2. 🟠 Introduce a Result type for error handling
3. 🟠 Add environment-based configuration
4. 🟡 Create a CLI tool for scaffolding features
5. 🟡 Add API versioning support

### New Features — [Details →](new-features.md)
1. 🟡 Offline-first with local database sync
2. 🟡 Real-time features via WebSocket/SSE
3. 🟡 Feature flags system
4. 🟢 App update checker
5. 🟢 Crash reporting integration
6. 🟢 In-app feedback/bug reporting
