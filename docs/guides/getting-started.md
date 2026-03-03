# Getting Started

> Step-by-step guide to setting up and bootstrapping a new app with the Caky packages.

---

## 1. Project Structure

```
my_app/
├── lib/
│   ├── main.dart
│   ├── config.dart          # App configuration
│   ├── registrar.dart       # Dependency registration
│   ├── initializer.dart     # Service lifecycle manager
│   ├── routes.dart          # Route definitions
│   └── features/
│       ├── product/
│       │   ├── model.dart
│       │   ├── request.dart
│       │   ├── api.dart
│       │   ├── cubit.dart
│       │   └── screens/
│       └── ...
├── pubspec.yaml
└── assets/
    └── lang/i18n/           # Translation files
```

## 2. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # Core packages (pick what you need)
  action:
    path: ../packages/action
  # This transitively brings in: concrete → skeleton → core

  # Pick impl packages as needed
  nav_go_router:
    path: ../packages/impl/nav_go_router
  impl_device_info:
    path: ../packages/impl/impl_device_info
  impl_notifier_onesignal:
    path: ../packages/impl/impl_notifier_onesignal
```

## 3. Create Your Config

```dart
// config.dart
import 'package:core/core.dart';
import 'package:flutter/material.dart';

class AppConfig extends Config {
  @override
  String get baseUrl => 'https://api.myapp.com/v1';

  @override
  int get appID => 1;

  @override
  String get appName => 'My App';

  @override
  String get appVersionNumber => '1.0.0';

  @override
  String get appLogo => 'assets/imgs/logo.png';

  @override
  List<CustomLang> get supportedLocales => [
    const CustomLang('English', Locale('en', 'US')),
    const CustomLang('العربية', Locale('ar', 'IQ')),
  ];

  @override
  List<CustomTheme> get themes => [
    CustomTheme('Light', ThemeData.light()),
    CustomTheme('Dark', ThemeData.dark()),
  ];

  @override
  String get oneSignalAppID => 'your-onesignal-app-id';
}
```

## 4. Create Your Routes

```dart
// routes.dart
import 'package:core/core.dart';

class AppRoutes extends R {
  @override
  String get redirectAfterLogin => '/home';

  @override
  String get redirectAfterLogout => login();

  @override
  String get redirectAfterHardLogout => login();
}
```

## 5. Create Your Initializer

```dart
// initializer.dart
import 'package:core/core.dart';

class AppInitializer extends I {
  @override
  Future init() async {
    // Initialize services that need setup at app start
    await Core.get<Notifier>().init();
  }

  @override
  void refresh() {
    // Called when language changes, etc.
  }

  @override
  void activate({required AuthResponse user}) {
    // Called after successful login
    Core.get<Notifier>().subscribe(user.user.id);
  }

  @override
  void deactivate({AuthResponse? user}) {
    // Called on logout
    Core.get<Notifier>().logout();
  }
}
```

## 6. Create Your Registrar

```dart
// registrar.dart
import 'package:core/core.dart';

class AppRegistrar extends Registrar {
  @override
  void register() {
    // Configuration
    Core.i.addSingleton<Config>(() => AppConfig());
    Core.i.addSingleton<R>(() => AppRoutes());
    Core.i.addSingleton<I>(() => AppInitializer());

    // Platform implementations
    Core.i.addSingleton<AppNavigator>(() => GoRouterNavigator(...));
    Core.i.addSingleton<DeviceInfo>(() => DeviceInfoImpl());
    Core.i.addSingleton<Notifier>(() => OneSignalNotifier());

    // Feature services
    Core.i.add<ProductApiService>(() => ProductApiService.instance());
    Core.i.add<ProductCubit>(() => ProductCubit());

    // Action system
    Core.i.add<ActionApiService>(() => ActionApiService.instance());
    Core.i.add<ActionCubit>(() => ActionCubit());
  }
}
```

## 7. Bootstrap in `main.dart`

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:concrete/concrete.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize path provider (for caching)
  await AppPathProvider.initPath();

  // 2. Initialize SharedPreferences
  final prefs = SharedPrefHelper();
  await prefs.init();
  Core.i.addInstance<SharedPrefHelper>(prefs);

  // 3. Register all dependencies
  final registrar = AppRegistrar();
  await registrar.init();

  // 4. Initialize services
  await Core.get<I>().init();

  runApp(
    RestartWidget(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => Core.get<ThemeBloc>()..getTheme()),
          BlocProvider(create: (_) => Core.get<LanguageBloc>()..getLang()),
          BlocProvider(create: (_) => Core.get<FontBloc>()..getFont()),
          BlocProvider(create: (_) => Core.get<AuthenticationCubit>()),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<LanguageBloc, LanguageState>(
              builder: (context, langState) {
                return MaterialApp(
                  navigatorKey: Core.navigatorKey,
                  theme: themeState.theme.themeData,
                  locale: langState.getLocale().data,
                  // ... localization delegates, routes, etc.
                  builder: (context, child) => AppWrapper(child: child!),
                );
              },
            );
          },
        ),
      ),
    ),
  );
}
```

## 8. Protect Routes with Auth Guards

```dart
// In your route definitions
MaterialPageRoute(
  builder: (_) => Authenticity.hard(child: HomeScreen()),
)

// Or for optional auth
MaterialPageRoute(
  builder: (_) => Authenticity.soft(
    child: ProfileScreen(),
    guest: LoginPrompt(),
  ),
)
```

---

## What Happens at Startup

```
main()
  ├── AppPathProvider.initPath()        ← File system paths
  ├── SharedPrefHelper.init()           ← SharedPreferences
  ├── Registrar.init()
  │   ├── Register auth managers        ← AuthLocalManager, AuthenticationCubit
  │   ├── Register SharedPrefHelper     ← Already initialized
  │   ├── Register BaseDio              ← With interceptors
  │   ├── register() (your code)        ← Config, Routes, I, features
  │   └── commit()                      ← Finalize DI container
  ├── I.init()                          ← App initializer
  └── runApp()
      ├── RestartWidget                 ← App restart capability
      ├── MultiBlocProvider             ← Theme, Language, Font, Auth
      ├── MaterialApp                   ← With Core.navigatorKey
      └── AppWrapper                    ← Global auth state listener
```
