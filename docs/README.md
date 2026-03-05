# SDK Packages — Architecture & Documentation

> A modular Flutter SDK for building production-ready mobile & web apps.

---

## Package Hierarchy

```
┌─────────────────────────────────────────────────────────┐
│                     Your Application                     │
├──────────┬──────────────────┬────────────────────────────┤
│  action  │     concrete     │     impl/* (pluggable)     │
├──────────┴──────────────────┤                            │
│          skeleton           │  nav_go_router             │
├─────────────────────────────┤  impl_locator              │
│            core             │  impl_device_info          │
│                             │  impl_notifier_onesignal   │
│  DI · HTTP · Auth · BLoC    │  media · media_audio/video │
│  Router · Storage · i18n    │  file_picker · glassmorphism│
│  Contracts · Extensions     │  advanced_editor           │
│  Constants                  │  template_pack             │
└─────────────────────────────┴────────────────────────────┘
```

### Dependency Flow

```
core  ──▶  skeleton  ──▶  concrete  ──▶  action
  │            │               │
  └────────────┴───────────────┴──▶  impl/* (pluggable implementations)
```

| Package | Role | Depends On |
|---------|------|------------|
| **core** | Foundation: DI, HTTP (Dio), Auth, BLoC, Router, Storage, i18n, Contracts, Extensions | `flutter`, pub packages |
| **skeleton** | Abstract bases: API service, BLoC mixins (CRUD, Pagination, Statistics), Handlers (Form, Filter, Editor), HTTP response models | `core` |
| **concrete** | Reusable UI widgets (inputs, modals, scroll, media, sidebar) and utility tools (Linker, Clipboard, Sharer, NetworkChecker) | `core`, `skeleton` |
| **action** | Bulk action system: ActionCubit, ActionHandler, ActionButton with confirmation dialogs | `core`, `skeleton`, `concrete` |
| **impl/*** | 12 pluggable implementation packages for navigation, media, device info, notifications, etc. | varies |

---

## Documentation Index

### Package References
| Doc | Description |
|-----|-------------|
| [core.md](core.md) | Dependency Injection, HTTP client, Auth system, BLoCs, Router, Storage, Contracts, Extensions, Constants |
| [skeleton.md](skeleton.md) | Base classes for API services, BLoC state management, Form/Filter/Editor handlers, HTTP response models |
| [concrete.md](concrete.md) | UI widget library (inputs, modals, media, scroll, sidebar) and utility tools |
| [action.md](action.md) | Bulk action system for batch operations on selected resources |
| [impl.md](impl.md) | Pluggable implementations: GoRouter navigation, OneSignal push, media players, file picker, etc. |

### Practical Guides
| Guide | Description |
|-------|-------------|
| [Getting Started](guides/getting-started.md) | Initial setup, configuration, registration, and app bootstrap |
| [Building a CRUD Feature](guides/crud-feature.md) | End-to-end walkthrough: model, API, BLoC, forms, list screen |
| [Authentication Flow](guides/authentication.md) | Login, logout, account switching, route guards, and token management |

---

## Design Principles

1. **Layered Architecture** — Each layer depends only on the layers below it; no circular dependencies.
2. **Contract-First** — Interfaces in `core/contracts/` (e.g., `Notifier`, `Locator`, `DeviceInfo`, `NetworkInfo`) are implemented in `impl/` packages, making implementations swappable.
3. **BLoC Pattern** — All business logic uses `flutter_bloc` Cubits. The `skeleton` package provides composable mixins (`CrudBloc`, `PaginationBloc`, `StatisticsBloc`) to avoid boilerplate.
4. **Backend Alignment** — HTTP responses (`BasicResponse`, `PaginationResponse`), method spoofing for multipart PUT/PATCH, validation error handling (422), and the `DynamicQueryRequest` query builder are all designed to work seamlessly with both Laravel and Supabase APIs.
5. **Dual-Token Auth** — Supports a root session token and per-profile active tokens for multi-account switching.
6. **Code Generation** — Uses `json_serializable` + `retrofit_generator` for type-safe API clients and JSON serialization.
