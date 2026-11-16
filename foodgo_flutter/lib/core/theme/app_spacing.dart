import 'package:flutter/material.dart';

/// 8pt Grid Spacing Scale & Radius Tokens for FoodGo
class AppSpacing {
  AppSpacing._();

  // Spacing Scale
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 14.0,
    vertical: 8.0,
  );

  // Border Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 22.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedCard = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius roundedModal = BorderRadius.vertical(
    top: Radius.circular(24.0),
  );
  static const BorderRadius roundedPill = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // Minimum Interactive Touch Target
  static const double minTouchTarget = 48.0;
}
