# Logic & State Management Improvements (V2)

Moving towards more reactive and declarative logic layers in the `skeleton` package.

## 1. State Machine BLoCs
Complex screens often behave like state machines. Standard BLoCs/Cubits can sometimes become a mess of booleans.

- **V2 Idea**: Implement a `StateMachineCubit` or integrate `bloc_concurrency` for event-transformer patterns.
- **Benefit**: Explicit transitions between states, reduced state-leakage bugs.

## 2. Declarative Form Validation (Formz)
Currently, form validation is scattered. Using a package like `formz` can standardize how input models are defined and validated.

- **V2 Idea**: A `ValidatableMaker` that uses `formz` to automatically handle validation state for complex inputs.
- **Benefit**: Reusable validation logic, cleaner UI-side form handling.

## 3. Reactive Data Watchers
Instead of manual `refresh()` calls, the UI should react to data changes.

- **V2 Idea**: Implement a `ReactiveListCubit` that observes a local database (Isar) or a WebSocket stream.
- **Benefit**: "Always-fresh" UI with zero effort from the developer.

## 4. Selection & Multi-Select Logic
Many Admin UIs require complex multi-selection across paginated lists.

- **V2 Idea**: A `SelectionBloc` mixin that handles item tracking, "Select All", and batch action triggers.
- **Benefit**: Drastically simplifies list-based management interfaces.

## 5. Navigation 2.0 (Router Abstraction)
Abstraction over `go_router` or `auto_route` to provide a unified navigation API.

- **V2 Idea**: A `NavigationService` that supports deep-linking into specific Cubit states.
- **Benefit**: Decoupled UI and navigation logic, easier deep-link management.
