# Developer Experience (DX) & Tooling (V2)

Helping developers build faster and with fewer errors.

## 1. CLI Code Generators (Caky Generate)
Using `mason` to scaffold new features.

### Implementation Details
- **Libraries**: `mason_cli`, `mason`.
- **Steps**:
    1. Create a "Caky Bricks" repository with templates for Cubits, Models, and APIs.
    2. Define variables like `{{feature_name}}` and `{{model_name}}` in `brick` files.
    3. Implement a custom shell script `caky` that wraps `mason make`.
    4. Integration: `caky gen crud product` -> Output: folder with complete CRUD boilerplate.

## 2. Dynamic API Mocking (MockServer)
Parallel development of frontend and backend.

### Implementation Details
- **Libraries**: `dio`, `mocktail` (for tests).
- **Steps**:
    1. Create `HttpMockingInterceptor` inheriting from `Interceptor`.
    2. map API endpoints to local assets: `/api/products` -> `assets/mocks/products.json`.
    3. Toggle mock mode via `EnvConfig` (from V1).
    4. Benefit: Build and test complex UI flows without a running backend.

## 3. Adaptive Layout Inspector
Tooling to see how the app looks on different screen sizes.

### Implementation Details
- **Libraries**: `device_preview`.
- **Steps**:
    1. Wrap the root `MaterialApp` in `DevicePreview` inside `main.dart` (only in dev).
    2. Configure common device presets (iPhone 15, iPad Pro, Desktop).
    3. Use this to verify RTL layout consistency (linked to V2.3).

## 4. Advanced Documentation (DocBook)
An interactive documentation site for SDK widgets.

### Implementation Details
- **Libraries**: `storybook_flutter`.
- **Steps**:
    1. Create a separate `caky_storybook` target.
    2. Define `Stories` for each `concrete` widget (e.g., `CakyButtonStory`, `ShimmerStory`).
    3. Use knobs to interactively change widget properties (colors, sizes).
    4. Deploy as a web app for the team.

## 5. Strict Linting & Architecture Guards
Rules to prevent "bad practices".

### Implementation Details
- **Libraries**: `custom_lint`.
- **Steps**:
    1. Create a `caky_lints` package that uses the `custom_lint` API.
    2. Write a rule `ui_should_not_import_api` that checks for prohibited imports in `lib/ui/`.
    3. Implement `missing_dispose_warning` for controllers and streams.
    4. Integration: Add `caky_lints` to `analysis_options.yaml`.
