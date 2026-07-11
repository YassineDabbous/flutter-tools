import 'package:flutter/material.dart';

extension WidgetThemeHelper on BuildContext {
  Size get sz => MediaQuery.of(this).size;
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDark => theme.brightness == Brightness.dark;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
  //

  bool get isMobile => MediaQuery.of(this).size.width < 850;

  bool get isTablet =>
      MediaQuery.of(this).size.width < 1100 &&
      MediaQuery.of(this).size.width >= 850;

  bool get isDesktop => MediaQuery.of(this).size.width >= 1100;
}
