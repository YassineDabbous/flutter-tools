# Caky SDK — Package Documentation

A modular Flutter SDK built on a **layered architecture** that separates concerns into backend-agnostic abstractions, UI components, and swappable backend providers.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        YOUR APPLICATION                         │
├──────────────────────────────────────────────────────────────────┤
│   impl/*              │  Provider Packages (pick one)           │
│   (optional add-ons)  │  ┌────────────────┐ ┌────────────────┐  │
│   · nav_go_router     │  │ laravel_provid.│ │ supabase_prov. │  │
│   · media / media_*   │  │ (Dio/Retrofit) │ │ (supabase_fl.) │  │
│   · file_picker       │  └───────┬────────┘ └───────┬────────┘  │
│   · impl_locator      │          │                   │          │
│   · impl_device_info  │          └─────────┬─────────┘          │
│   · template_pack     │                    │                    │
│   · advanced_editor   │                    ▼                    │
│   · glassmorphism     │  ┌────────────────────────────────────┐ │
│                       │  │            action                  │ │
│                       │  │  (bulk ops, undo, batch progress)  │ │
│                       │  └───────────────┬────────────────────┘ │
│                       │                  │                      │
│                       │                  ▼                      │
│                       │  ┌────────────────────────────────────┐ │
│                       │  │           concrete                 │ │
│                       │  │  (UI widgets, tools, components)   │ │
│                       │  └───────────────┬────────────────────┘ │
│                       │                  │                      │
│                       │                  ▼                      │
│                       │  ┌────────────────────────────────────┐ │
│                       │  │           skeleton                 │ │
│                       │  │  (base models, API contracts,      │ │
│                       │  │   BLoC mixins, form handlers)      │ │
│                       │  └───────────────┬────────────────────┘ │
│                       │                  │                      │
│                       │                  ▼                      │
│                       │  ┌────────────────────────────────────┐ │
│                       │  │             core                   │ │
│                       │  │  (DI, auth, config, routing,       │ │
│                       │  │   failures, blocs, extensions)     │ │
│                       │  └────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## Package Index

| Package | Description | Doc |
|---------|-------------|-----|
| **core** | Foundation: DI, auth, config, routing, failures, blocs, extensions | [core.md](./core.md) |
| **skeleton** | Abstract API contracts, base models, BLoC mixins, form/filter handlers | [skeleton.md](./skeleton.md) |
| **concrete** | UI widgets, display components, input fields, tools, modals | [concrete.md](./concrete.md) |
| **action** | Bulk actions, undo/redo, batch progress tracking, action UI | [action.md](./action.md) |
| **laravel_provider** | Laravel backend implementation via Dio + Retrofit | [laravel_provider.md](./laravel_provider.md) |
| **supabase_provider** | Supabase backend implementation via supabase_flutter | [supabase_provider.md](./supabase_provider.md) |
| **impl/\*** | Optional add-on packages (navigation, media, etc.) | [impl.md](./impl.md) |

## Guides

| Guide | Description |
|-------|-------------|
| [Building a CRUD Feature](./guides/crud-feature.md) | End-to-end walkthrough: model → API → BLoC → UI |

## Dependency Graph

```
core ← skeleton ← concrete ← action
                 ↑                ↑
          laravel_provider   supabase_provider
```

- **core** depends on nothing (pure foundation).
- **skeleton** depends on `core`.
- **concrete** depends on `core` + `skeleton`.
- **action** depends on `core` + `skeleton` + `concrete`.
- **laravel_provider** depends on `skeleton` + `core`.
- **supabase_provider** depends on `skeleton` + `core`.
- **impl/\*** packages depend on `core` and/or `skeleton`.

## Quick Start

```yaml
# pubspec.yaml — pick the packages you need
dependencies:
  core:
    path: ../packages/core
  skeleton:
    path: ../packages/skeleton
  concrete:
    path: ../packages/concrete
  laravel_provider:          # OR supabase_provider
    path: ../packages/laravel_provider
```

Then read the [CRUD Feature Guide](./guides/crud-feature.md) for a step-by-step integration walkthrough.
