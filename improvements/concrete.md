# Concrete Package — Improvements

---

## 🟡 1. Build a Design System / Component Library

### Problem
The concrete package has individual widgets but lacks a unified design system. Colors, spacing, typography, and component styles are determined ad-hoc in each widget or by the app's theme.

### Solution
Create a comprehensive design system layer:

```dart
/// The app's design token set, configurable per-app
class CakyDesign {
  // Spacing
  static const spacing = CakySpacing();

  // Colors — derived from current theme
  static CakyColors colors(BuildContext context) =>
      CakyColors.fromColorScheme(context.colorScheme);

  // Typography
  static CakyTypography typography(BuildContext context) =>
      CakyTypography.fromTextTheme(context.textTheme);

  // Elevation
  static const elevation = CakyElevation();

  // Animation
  static const motion = CakyMotion();
}

class CakySpacing {
  const CakySpacing();
  double get xxs => 2;
  double get xs  => 4;
  double get sm  => 8;
  double get md  => 12;
  double get lg  => 16;
  double get xl  => 24;
  double get xxl => 32;
  double get xxxl => 48;
}

class CakyMotion {
  const CakyMotion();
  Duration get fast => const Duration(milliseconds: 150);
  Duration get medium => const Duration(milliseconds: 300);
  Duration get slow => const Duration(milliseconds: 500);
  Curve get standard => Curves.easeInOutCubic;
  Curve get enter => Curves.easeOut;
  Curve get exit => Curves.easeIn;
}
```

**Benefits:** Consistent visuals across all apps using Caky, easier theme customization, and a shared vocabulary between designers and developers.

---

## 🟡 2. Add Accessibility (a11y) Support

### Problem
Current widgets don't include `Semantics`, `ExcludeSemantics`, or proper focus management. Screen readers can't navigate the app effectively.

### Solution
Wrap key widgets with accessibility semantics:

```dart
// Before
class Message extends StatelessWidget {
  final String message;
  Widget build(context) => Text(message);
}

// After
class Message extends StatelessWidget {
  final String message;
  final MessageType type; // info, error, success, warning

  Widget build(context) => Semantics(
    label: '${type.name} message: $message',
    liveRegion: true, // Announce to screen readers immediately
    child: Text(message),
  );
}
```

Add an `a11y` mixin for common patterns:

```dart
mixin AccessibleWidget {
  /// Ensure touch targets are at least 48x48
  Widget ensureMinTouchTarget(Widget child) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    child: child,
  );

  /// Announce a state change to screen readers
  void announce(BuildContext context, String message) {
    SemanticsService.announce(message, Directionality.of(context));
  }
}
```

**Checklist for all widgets:**
- [ ] `Semantics` labels on all interactive elements
- [ ] Minimum 48x48 touch targets
- [ ] Color contrast ratio ≥ 4.5:1
- [ ] Focus traversal order
- [ ] Live region announcements for dynamic content

---

## 🟡 3. Integrated Skeleton Loading

### Problem
Each list/grid widget must implement its own shimmer loading placeholder. There's no standard loading skeleton.

### Solution
Create a `SkeletonBuilder` system:

```dart
class SkeletonBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final bool isLoading;
  final Widget child;

  const SkeletonBuilder({
    required this.isLoading,
    required this.child,
    this.itemCount = 5,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Shimmer.fromColors(
      baseColor: context.isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: context.isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, i) => itemBuilder(i),
      ),
    );
  }
}

// Pre-built skeletons
class SkeletonListTile extends StatelessWidget {
  @override
  Widget build(context) => ListTile(
    leading: Container(width: 48, height: 48, decoration: BoxDecoration(
      color: Colors.white, borderRadius: Corner.sm,
    )),
    title: Container(height: 14, width: 160, color: Colors.white),
    subtitle: Container(height: 10, width: 100, color: Colors.white),
  );
}

class SkeletonCard extends StatelessWidget {
  @override
  Widget build(context) => Card(
    child: Container(height: 200, color: Colors.white),
  );
}
```

Usage:
```dart
BlocBuilder<ProductCubit, ProductState>(
  builder: (context, state) => SkeletonBuilder(
    isLoading: state is ProductPageLoadingState,
    itemBuilder: (i) => SkeletonListTile(),
    child: ProductListView(products: state.data),
  ),
)
```

---

## 🟢 4. Dark Mode Adaptive Components

### Problem
Dialog helpers like `dialogConfirmation` and widgets like `ActionHandler` use hardcoded colors (e.g., `Colors.grey[300]`, `Colors.green`, `Colors.red`). These don't adapt well to dark mode.

### Solution
Replace hardcoded colors with theme-aware colors:

```dart
// Before
Container(color: Colors.grey[300])

// After
Container(color: context.colorScheme.surfaceContainerHighest)

// Before
Icon(Icons.done, color: Colors.green)

// After
Icon(Icons.done, color: context.colorScheme.primary)

// Before
Icon(Icons.close, color: Colors.red)

// After
Icon(Icons.close, color: context.colorScheme.error)
```

Create utility getters:

```dart
extension AdaptiveColors on BuildContext {
  Color get successColor => isDark ? Colors.green[300]! : Colors.green[700]!;
  Color get warningColor => isDark ? Colors.orange[300]! : Colors.orange[700]!;
  Color get dangerColor => colorScheme.error;
  Color get infoColor => isDark ? Colors.blue[300]! : Colors.blue[700]!;
  Color get overlayColor => isDark
      ? Colors.black.withOpacity(0.5)
      : Colors.grey.withOpacity(0.3);
}
```

---

## 🟢 5. Responsive Layout Helpers

### Problem
The current `context.isMobile/isTablet/isDesktop` extension is useful, but there's no ready-made responsive layout builder.

### Solution
```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop && desktop != null) return desktop!;
    if (context.isTablet && tablet != null) return tablet!;
    return mobile;
  }
}

// Grid column helper
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;

  const ResponsiveGrid({
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.isDesktop
        ? desktopColumns
        : context.isTablet
            ? tabletColumns
            : mobileColumns;

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: Sz.md,
      mainAxisSpacing: Sz.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
```

---

## 🟢 6. Empty State & Error State Components

### Problem
Every list screen must build its own "no results" and "error" views. No reusable components exist.

### Solution
```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    this.icon = Icons.inbox_outlined,
    this.title = 'No results',
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: context.colorScheme.onSurfaceVariant.withOpacity(0.5)),
        const SizedBox(height: Sz.lg),
        Text(title, style: context.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: Sz.sm),
          Text(subtitle!, style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          )),
        ],
        if (action != null) ...[
          const SizedBox(height: Sz.xl),
          action!,
        ],
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 64, color: context.dangerColor),
        const SizedBox(height: Sz.lg),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: Sz.xl),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text('retry'.i18n()),
          ),
        ],
      ],
    ),
  );
}
```

---

## 🟢 7. Add `Snackbar` Varieties

### Problem
The current `showSnackBar()` is basic — text only. No success/error/warning variants.

### Solution
```dart
void showSuccess(BuildContext context, String message) =>
    _show(context, message, Icons.check_circle, context.successColor);

void showError(BuildContext context, String message) =>
    _show(context, message, Icons.error, context.dangerColor);

void showWarning(BuildContext context, String message) =>
    _show(context, message, Icons.warning, context.warningColor);

void showInfo(BuildContext context, String message) =>
    _show(context, message, Icons.info, context.infoColor);

void _show(BuildContext context, String message, IconData icon, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: Edges.lg,
    shape: RoundedRectangleBorder(borderRadius: Corner.md),
    backgroundColor: color,
    content: Row(children: [
      Icon(icon, color: Colors.white),
      const SizedBox(width: Sz.sm),
      Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
    ]),
    duration: const Duration(seconds: 3),
  ));
}
```
