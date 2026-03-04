# Developer Experience (DX) & Tooling (V2)

Helping developers build faster and with fewer errors.

## 1. CLI Code Generators (Caky Generate)
Using `mason` or custom scripts to scaffold new features.

- **V2 Idea**: Command like `caky gen crud user` which creates the API service, Model, Request, and Cubit for a "User" resource.
- **Benefit**: Near-zero boilerplate.

## 2. Dynamic API Mocking (MockServer)
Sometimes the backend isn't ready.

- **V2 Idea**: An `HttpMockingInterceptor` that reads JSON files from local assets if the server is in "mock mode".
- **Benefit**: Parallel development of frontend and backend.

## 3. Adaptive Layout Inspector
Tooling to see how the app looks on different screen sizes (mobile, tablet, desktop) during development.

- **V2 Idea**: A `DevicePreview` setup integrated into the SDK core.
- **Benefit**: Easier mobile-first development.

## 4. Advanced Documentation (DocBook)
An interactive documentation site for the SDK widgets and logic helpers.

- **V2 Idea**: Integrating with `storybook_flutter` or similar to preview components in isolation.
- **Benefit**: Clear reference for team members using the packages.

## 5. Strict Linting & Architecture Guards
Rules to prevent "bad practices" like calling API from UI.

- **V2 Idea**: Custom `dart_lint` rules specific to the Caky SDK architecture.
- **Benefit**: Enforced code quality and consistency.
