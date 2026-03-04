# Feature Foundations (V2)

Pre-built building blocks for common application features in the `impl` package.

## 1. Universal Auth Module
Handling login, registration, and social provider flows.

### Implementation Details
- **Libraries**: `google_sign_in`, `sign_in_with_apple`, `flutter_facebook_auth`.
- **Steps**:
    1. Create an `AuthRepository` with `signInWithGoogle()`, `signInWithApple()`, etc.
    2. Implement `AuthCubit` to manage `Authenticated`, `Unauthenticated`, and `AuthLoading` states.
    3. Use `BaseModel` (from V1) for the `User` object.
    4. Automatically store tokens in `SecureAuthStorage` upon success.

## 2. Modular Notification System
Handling push and local notifications consistently.

### Implementation Details
- **Libraries**: `firebase_messaging`, `flutter_local_notifications`.
- **Steps**:
    1. Implement `NotificationService` that handles `onMessage`, `onMessageOpenedApp`.
    2. Create standard `NotificationModel` to parse incoming JSON payloads.
    3. UI: Add a `NotificationBell` widget to the `concrete` package that tracks unread counts.

## 3. Real-time Chat/Messaging Layer
Many apps need a basic chat or support/comment system.

### Implementation Details
- **Libraries**: `stream_chat_flutter` (for managed) or `socket_io_client` (for custom).
- **Steps**:
    1. Create `ChatFramework` interface with `sendMessage`, `getMessages`, `onMessageReceived`.
    2. Implement a `ChatCubit` that manages message pagination (linked to Skeleton's `PaginationBloc`).
    3. Provide `ChatMessageWidget` in `concrete` for consistent styling.

## 4. Universal Asset & Media Picker
A robust way to handle image/video/file selection and uploads.

### Implementation Details
- **Libraries**: `image_picker`, `file_picker`, `flutter_image_compress`.
- **Steps**:
    1. Implement `MediaPicker` utility to abstract OS-level pickers.
    2. Automatic compression logic: Compress images before upload to save bandwidth.
    3. Integration: `BaseMaker.setAttachment(key, compressedFile)`.

## 5. Audit Logging & Versioning
Tracking changes to critical models for Admin auditing.

### Implementation Details
- **Steps**:
    1. Create `Versionable` mixin for Models.
    2. Implement `diff()` method that compares two JSON maps and returns only changed keys.
    3. Integration: Automatically call `diff()` in the `save()` method of `AutoCrudBloc` to log changes.
