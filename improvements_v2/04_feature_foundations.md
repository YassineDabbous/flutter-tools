# Feature Foundations (V2)

Pre-built building blocks for common application features in the `impl` package.

## 1. Universal Auth Module
Nearly every app needs login, registration, and profile management.

- **V2 Idea**: Full-featured `AuthCubit` that handles Social Login (Apple/Google), Password reset, and OTP flows.
- **Benefit**: Start building features in minutes, not days.

## 2. Modular Notification System
Handling push and local notifications consistently across platforms.

- **V2 Idea**: A `NotificationCenter` that abstracts Firebase Messaging and provides a UI for in-app notifications.
- **Benefit**: Plug-and-play notification support.

## 3. Real-time Chat/Messaging Layer
Many apps need a basic chat or support/comment system.

- **V2 Idea**: A `ChatFramework` base that works with Stream, Pusher, or simple WebSockets.
- **Benefit**: Instant messaging capabilities without re-inventing the wheel.

## 4. Universal Asset & Media Picker
A robust way to handle image/video/file selection and uploads.

- **V2 Idea**: A `MediaManager` that integrates with `image_picker` and `file_picker` with built-in compression and chunked-upload support.
- **Benefit**: Reliable media handling across all platforms.

## 5. Audit Logging & Versioning
Tracking changes to critical models for Admin auditing.

- **V2 Idea**: Implement `Versionable` interface so models can track "delta" changes locally or on-server.
- **Benefit**: High security and transparency for enterprise apps.
