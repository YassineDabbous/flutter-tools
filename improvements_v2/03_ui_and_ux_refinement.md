# UI & UX Refinement (V2)

Elevating the visual quality and interactive feel of the `concrete` package.

## 1. Universal Design Tokens & Theme Engine
The SDK should support a full Design System with tokens for Spacing, Radius, Typography, and Motion.

### Implementation Details
- **Libraries**: `theme_tailor` (optional), `flutter/material.dart`.
- **Steps**:
    1. Define `CakyDesignTokens` class with constants.
    2. Use `ThemeExtension` to inject custom tokens into `ThemeData`.
    3. Implement `ThemeSwitcherCubit` to toggle between Light, Dark, and High-Contrast modes.
    4. Access: `Theme.of(context).extension<CakyTokens>()!.spacingSmall`.

## 2. Advanced Micro-Interactions
Integrating specialized motion patterns for a premium feel.

### Implementation Details
- **Libraries**: `animations`, `flutter_animate`.
- **Steps**:
    1. Standardize page transitions using `OpenContainer` (from `animations` package).
    2. Create `CakyAnimatedList` that uses `TweenAnimationBuilder` for entry staggered animations.
    3. Implement "Pull-to-Refresh" with custom high-fidelity Lottie animations.

## 3. Composable Dashboard System
Providing a library of chart and stat widgets for Admin features.

### Implementation Details
- **Libraries**: `fl_chart`.
- **Steps**:
    1. Create `CakyLineChart` and `CakyBarChart` wrappers that simplify `fl_chart` configuration.
    2. Implement `StatCard` widget with built-in trend indicators (up/down arrows).
    3. Data Integration: Link with `BaseStatisticsCubit` (from Skeleton) for easy data feed.

## 4. Skeletal Layout Templates
Providing full-page skeletal mockups for consistent loading states.

### Implementation Details
- **Steps**:
    1. Use `ShimmerHelper` (from V1) as a building block.
    2. Create `PageSkeleton` widgets (e.g., `ProfileSkeleton`, `ListSkeleton`).
    3. Implement `SkeletonSwitcher` that cross-fades between the skeleton and the actual content once loaded.

## 5. Localized UI Helpers
Automatic RTL switching, date/time formatting, and currency support.

### Implementation Details
- **Libraries**: `intl`, `flutter_localizations`.
- **Steps**:
    1. Define `CakyLocaleManager` that observes the system locale.
    2. Implement `extensions` on `DateTime` and `num` for auto-formatting.
    3. Ensure `concrete` widgets respect `Directionality.of(context)` for automatic RTL mirroring.
    4. Example: `price.toCurrency(context)`.
