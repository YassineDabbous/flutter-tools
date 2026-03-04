# New Feature Ideas

> Brand new capabilities that don't exist yet but would significantly enhance the SDK's value proposition.

---

## 🟠 1. Admin Dashboard Foundation

### Idea
As seen in the `demo` project's `admin/` folder, many screens share a common layout: `AdminScreenWrapper`, `AdminAppBar`, and `DefaultGrid`. These should be moved from the demo into the `concrete` package to provide a standard Admin SDK.

### Features
- `AdminScaffold`: Handles sidebar, top bar, and responsive behavior.
- `AdminQuickSearch`: Automated search bar tied to `BaseController`.
- `AdminActionToolbar`: Automatically renders `ActionButton`s based on `BaseController.selectedIds`.
- `AdminStatsHeader`: Renders `StatisticsResponse` at the top of list screens.

---

## 🟡 2. Unified E-commerce Cart & Checkout Foundation

### Idea
The demo implementation of `CartCubit` and `CartInterceptor` shows a need for a standardized "Cart System" in the SDK.

### Features
- `BaseCartCubit`: Standard logic for add/remove/update/clear items.
- `CartPersistenceLayer`: Auto-save cart to LocalStorage or sync with API.
- `CartHeaderSync`: Automatically injects `X-Cart-ID` into every HTTP request.
- `CheckoutStepFlow`: Standard BLoC for multi-step checkouts (Shipping → Payment → Review).

---

## 🟡 3. Offline-First with Local Database Sync

### Concept
Move from "crash on no internet" to "work offline, sync when connected". This is the single highest-value addition for mobile apps in areas with unreliable connectivity.

### Architecture
```
┌─────────────────────────────────────────────┐
│                  BLoC / Cubit               │
├─────────────────────────────────────────────┤
│              Repository (new)               │
├──────────────────┬──────────────────────────┤
│  Remote Source    │     Local Source (new)   │
│  (API Service)   │     (Drift / Isar DB)    │
├──────────────────┴──────────────────────────┤
│         SyncEngine (new)                    │
│  Tracks changes, resolves conflicts,        │
│  syncs in background                        │
└─────────────────────────────────────────────┘
```

### Key Components

**1. `SyncableModel` mixin:**
```dart
mixin SyncableModel on BaseModel {
  DateTime? syncedAt;
  DateTime? modifiedAt;
  SyncStatus syncStatus = SyncStatus.synced;

  bool get needsSync => syncStatus != SyncStatus.synced;
  bool get isLocalOnly => syncStatus == SyncStatus.created;
}

enum SyncStatus { synced, created, modified, deleted }
```

**2. `SyncEngine`:**
```dart
class SyncEngine {
  final Duration syncInterval;
  Timer? _timer;

  void start() {
    _timer = Timer.periodic(syncInterval, (_) => sync());
  }

  Future<SyncReport> sync() async {
    final changes = await localDb.getPendingChanges();
    final report = SyncReport();

    for (final change in changes) {
      try {
        switch (change.status) {
          case SyncStatus.created:
            final remoteId = await api.create(change.data);
            await localDb.updateRemoteId(change.localId, remoteId);
            report.created++;
          case SyncStatus.modified:
            await api.update(id: change.remoteId, data: change.data);
            report.updated++;
          case SyncStatus.deleted:
            await api.delete(id: change.remoteId);
            report.deleted++;
          case SyncStatus.synced:
            break;
        }
        await localDb.markSynced(change.localId);
      } catch (e) {
        report.failed++;
        await localDb.markFailed(change.localId, e.toString());
      }
    }
    return report;
  }
}
```

**3. Conflict resolution strategies:**
```dart
enum ConflictStrategy {
  serverWins,     // Always use server version
  clientWins,     // Always use local version
  lastWriteWins,  // Compare timestamps
  manual,         // Prompt user to resolve
}
```

### Benefits
- Users can browse cached data while offline
- Create/edit operations are queued locally
- Background sync when connectivity returns
- Conflict resolution for concurrent edits

---

## 🟡 2. Real-Time Features via WebSocket/SSE

### Concept
Add server push capabilities for live updates, chat, notifications, and collaborative editing.

### Architecture
```dart
abstract class RealtimeClient {
  Future<void> connect();
  Future<void> disconnect();
  Stream<RealtimeEvent> listen(String channel);
  void subscribe(String channel);
  void unsubscribe(String channel);
  bool get isConnected;
}

class RealtimeEvent {
  final String channel;
  final String type;      // 'created', 'updated', 'deleted', 'custom'
  final dynamic data;
  final DateTime timestamp;
}
```

**Laravel Echo / Pusher implementation:**
```dart
class LaravelEchoClient implements RealtimeClient {
  late final Echo echo;

  @override
  Future<void> connect() async {
    echo = Echo(PusherClient(
      Core.get<Config>().pusherKey,
      PusherOptions(cluster: 'us2'),
      authEndpoint: '${Core.get<Config>().baseUrl}/broadcasting/auth',
    ));
  }

  @override
  Stream<RealtimeEvent> listen(String channel) {
    final controller = StreamController<RealtimeEvent>();
    echo.channel(channel)
      .listen('.created', (data) => controller.add(RealtimeEvent(
        channel: channel, type: 'created', data: data, timestamp: DateTime.now(),
      )))
      .listen('.updated', (data) => controller.add(RealtimeEvent(
        channel: channel, type: 'updated', data: data, timestamp: DateTime.now(),
      )));
    return controller.stream;
  }
}
```

**Auto-integration with PaginationBloc:**
```dart
// Automatically refresh lists when server pushes an update
mixin LiveList<Model> on PaginationBloc {
  void startWatching(String channel) {
    Core.get<RealtimeClient>().listen(channel).listen((event) {
      switch (event.type) {
        case 'created':
          lista.insert(0, deserialize(event.data));
          emit(bs.pageLoaded(data: lista, maxReached: maxReached, nextPage: page));
        case 'deleted':
          lista.removeWhere((item) => (item as dynamic).id == event.data['id']);
          emit(bs.pageLoaded(data: lista, maxReached: maxReached, nextPage: page));
      }
    });
  }
}
```

---

## 🟡 3. Feature Flags System

### Concept
Enable/disable features remotely without deploying app updates. Critical for A/B testing, staged rollouts, and kill switches.

```dart
abstract class FeatureFlags {
  Future<void> fetch();
  bool isEnabled(String flag);
  T value<T>(String flag, T defaultValue);
  Stream<void> get onUpdate;
}

class RemoteFeatureFlags implements FeatureFlags {
  Map<String, dynamic> _flags = {};
  final _controller = StreamController<void>.broadcast();

  @override
  Future<void> fetch() async {
    final response = await Core.get<BaseDio>().dio.get('/flags');
    _flags = response.data;
    _controller.add(null);
  }

  @override
  bool isEnabled(String flag) => _flags[flag] == true;

  @override
  T value<T>(String flag, T defaultValue) =>
      (_flags[flag] as T?) ?? defaultValue;
}
```

**Usage in widgets:**
```dart
if (Core.get<FeatureFlags>().isEnabled('new_checkout_flow')) {
  return NewCheckoutScreen();
} else {
  return LegacyCheckoutScreen();
}
```

**Usage in routes:**
```dart
NavRoute(
  path: '/beta-feature',
  builder: (_, __) => Authenticity.hard(
    condition: (_) => Core.get<FeatureFlags>().isEnabled('beta_access'),
    child: BetaFeatureScreen(),
    guest: NotAvailableScreen(),
  ),
)
```

---

## 🟢 4. App Update Checker

### Concept
Prompt users to update when a new version is available. Support mandatory and optional updates.

```dart
class AppUpdateChecker {
  Future<UpdateInfo?> check() async {
    try {
      final response = await Core.get<BaseDio>().dio.get('/app/version');
      final latestVersion = response.data['version'];
      final minimumVersion = response.data['minimum_version'];
      final currentVersion = Core.get<Config>().appVersionNumber;

      if (_isOlderThan(currentVersion, minimumVersion)) {
        return UpdateInfo(
          type: UpdateType.mandatory,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          updateUrl: response.data['update_url'],
          changelog: response.data['changelog'],
        );
      } else if (_isOlderThan(currentVersion, latestVersion)) {
        return UpdateInfo(
          type: UpdateType.optional,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          updateUrl: response.data['update_url'],
          changelog: response.data['changelog'],
        );
      }
      return null;
    } catch (e) {
      return null; // Don't block the app if check fails
    }
  }
}

enum UpdateType { mandatory, optional }

class UpdateInfo {
  final UpdateType type;
  final String currentVersion;
  final String latestVersion;
  final String updateUrl;
  final String? changelog;
}
```

**UI integration:**
```dart
// In AppWrapper or Registrar — check on app launch
final update = await Core.get<AppUpdateChecker>().check();
if (update != null) {
  showUpdateDialog(context, update);
}
```

---

## 🟢 5. Crash Reporting Integration

### Concept
Add a crash reporting contract similar to `Notifier`:

```dart
abstract class CrashReporter {
  Future<void> init();
  void reportError(dynamic error, StackTrace stackTrace, {Map<String, dynamic>? context});
  void setUser(String id, {String? email, String? name});
  void log(String message);
  void addBreadcrumb(String category, String message, {Map<String, dynamic>? data});
}
```

**Integration with existing error handling:**
```dart
// In ExceptionHandler
Exception ex(Exception err) {
  Core.get<CrashReporter>().reportError(err, StackTrace.current, context: {
    'type': err.runtimeType.toString(),
  });
  // ... existing error mapping
}

// In MyBaseBloc
BaseState mapErrorToState(dynamic e) {
  Core.get<CrashReporter>().addBreadcrumb('bloc', 'Error in ${runtimeType}', data: {
    'error': e.toString(),
  });
  return _mapErrorToState(e);
}
```

---

## 🟢 6. In-App Feedback / Bug Reporting

### Concept
Let users shake the device or tap a button to submit feedback with a screenshot and device info.

```dart
class FeedbackService {
  Future<void> showFeedbackSheet(BuildContext context) async {
    // 1. Capture screenshot
    final screenshot = await _captureScreen(context);

    // 2. Gather device info
    final deviceInfo = await Core.get<DeviceInfo>();
    final info = {
      'app_version': Core.get<Config>().appVersionNumber,
      'device_uuid': await deviceInfo.uuid(),
      'device_name': await deviceInfo.name(),
      'user_id': auth().currentUser?.user.id,
      'route': Core.nav.path,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 3. Show feedback form
    showModalBottomSheet(
      context: context,
      builder: (_) => FeedbackForm(
        screenshot: screenshot,
        deviceInfo: info,
        onSubmit: (message, category) => _submit(message, category, screenshot, info),
      ),
    );
  }
}
```

---

## 🟢 7. Multi-Tenant Dynamic Theming

### Concept
Load theme configuration (colors, logo, fonts) from the server per tenant, enabling white-labeling without app updates.

```dart
class DynamicTheme {
  static Future<ThemeData> fromServer() async {
    final response = await Core.get<BaseDio>().dio.get('/customization/theme');
    final data = response.data;

    return ThemeData(
      colorScheme: ColorScheme(
        primary: Color(int.parse(data['primary_color'])),
        secondary: Color(int.parse(data['secondary_color'])),
        // ...
      ),
      fontFamily: data['font_family'],
    );
  }
}
```

---

## 🟢 8. Smart Prefetching

### Concept
Predict which data the user will need next and preload it:

```dart
class Prefetcher {
  final Map<String, DateTime> _prefetched = {};
  final Duration _staleness = const Duration(minutes: 5);

  /// Prefetch data for a route before navigating
  Future<void> prefetchForRoute(String route) async {
    if (_isStale(route)) return;

    switch (route) {
      case '/products':
        await Core.get<ProductCubit>().refresh();
      case '/orders':
        await Core.get<OrderCubit>().refresh();
    }
    _prefetched[route] = DateTime.now();
  }

  bool _isStale(String route) {
    final last = _prefetched[route];
    return last != null && DateTime.now().difference(last) < _staleness;
  }
}

// In navigation — prefetch before transition
Core.nav.push('/products');
Core.get<Prefetcher>().prefetchForRoute('/products');
```

---

## 🟢 9. Query Builder DSL

### Concept
A type-safe, fluent Dart DSL for building complex `DynamicQueryRequest` filters:

```dart
final query = Query<Product>()
    .where('price').greaterThan(100)
    .where('status').equals('active')
    .where('name').contains('widget')
    .orderBy('created_at', desc: true)
    .select(['id', 'name', 'price'])
    .groupBy('category')
    .metric('sum', field: 'price')
    .page(1, perPage: 20);

// Compiles to DynamicQueryRequest fields:
// {
//   'price': 100,
//   'status': 'active',
//   'name': 'widget',
//   '_operators': {'price': '>', 'name': 'like%'},
//   '_sort[]': ['-created_at'],
//   '_fields[]': ['id', 'name', 'price'],
//   '_group[]': ['category'],
//   '_metric': 'sum:price',
//   'page': 1,
//   'per_page': 20,
// }
```

This would replace manual filter construction and make query-building self-documenting.
