# Logic & State Management Improvements (V2)

Moving towards more reactive and declarative logic layers in the `skeleton` package.

## 1. State Machine BLoCs
Complex screens often behave like state machines. Standard BLoCs/Cubits can sometimes become a mess of booleans.

### Implementation Details
- **Libraries**: `bloc_concurrency`, `stream_transform`.
- **Steps**:
    1. Define `States` and `Events` clearly.
    2. Use `on<Event>(..., transformer: restartable())` to handle race conditions.
    3. Implement a `transition(State nextState)` method to gate valid transitions.
    4. Example: `if (state is! LoadingState) emit(nextState);`.

## 2. Declarative Form Validation (Formz)
Using a package like `formz` to standardize input models.

### Implementation Details
- **Libraries**: `formz`.
- **Steps**:
    1. Create input classes inheriting from `FormzInput<T, E>`.
    2. Overload the `validator` method with logic (e.g., email Regex).
    3. Integration in `BaseMaker`: Replace raw primitives with `Formz` types.
    4. UI: `errorText: state.email.invalid ? 'Invalid Email' : null`.

## 3. Reactive Data Watchers
The UI should react to data changes without manual refreshes.

### Implementation Details
- **Libraries**: `isar`, `rxdart`.
- **Steps**:
    1. In `PaginationBloc`, listen to the Isar collection: `isar.products.watchLazy().listen(...)`.
    2. Use `debounceTime` from `rxdart` to avoid UI flicker during rapid writes.
    3. Automatically trigger `refresh()` logic when the local database changes.

## 4. Selection & Multi-Select Logic
Simplifying multi-selection across paginated lists.

### Implementation Details
- **Steps**:
    1. Create `SelectionBlocMixin<T>`.
    2. Store a `Set<T> selectedItems` in the state.
    3. Implement methods: `toggle(item)`, `selectAll(List<T> currentItems)`, `clear()`.
    4. UI: Use `CheckboxListTile` that communicates with the `SelectionBloc`.

## 5. Navigation 2.0 (Router Abstraction)
Abstraction over `go_router` or `auto_route`.

### Implementation Details
- **Libraries**: `go_router`.
- **Steps**:
    1. Create a `CakyRouter` helper class.
    2. Define routes as static constants or Enums.
    3. Implement `pushNamed`, `replaceNamed` that also log telemetry (linked to V2.1).
    4. Integration: `Core.get<CakyRouter>().toDashboard()`.
