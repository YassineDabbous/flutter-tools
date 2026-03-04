# Multi-Provider Architecture Proposal

This folder contains a detailed analysis and roadmap for decoupling the Caky SDK into backend-agnostic core packages and specialized provider packages.

## Documents

| Document | Focus |
| :--- | :--- |
| [01 Strategy](./01_multi_provider_strategy.md) | The "Why" and "What" of package separation. |
| [02 Migration Plan](./02_migration_plan.md) | Technical steps to decouple Core and Skeleton from Laravel/Dio. |

## Why now?

With the addition of **Supabase** plans, keeping Laravel-specific dependencies in the `core` package will lead to "Dependency Bloat" and architectural confusion. Moving to a provider model ensures the Caky SDK remains elite and adaptable to any backend in the future.
