import 'package:flutter/painting.dart';

class Sz {
  static const double scale = 1;
  static const double zero = 0;
  static const double xs = 4 * Sz.scale;
  static const double sm = 8 * Sz.scale;
  static const double md = 12 * Sz.scale;
  static const double lg = 16 * Sz.scale;
  static const double xl = 32 * Sz.scale;
  static const double xxl = 64 * Sz.scale;
}

class Edges {
  static const EdgeInsets xs = EdgeInsets.all(Sz.xs);
  static const EdgeInsets sm = EdgeInsets.all(Sz.sm);
  static const EdgeInsets md = EdgeInsets.all(Sz.md);
  static const EdgeInsets lg = EdgeInsets.all(Sz.lg);
  static const EdgeInsets xl = EdgeInsets.all(Sz.xl);
  static const EdgeInsets xxl = EdgeInsets.all(Sz.xxl);
}

class Corner {
  static const BorderRadius xs = BorderRadius.all(Radius.circular(Sz.xs));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(Sz.sm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(Sz.md));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(Sz.lg));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(Sz.xl));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(Sz.xxl));
}
