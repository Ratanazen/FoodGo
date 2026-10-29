import 'package:flutter/material.dart';

/// Semantic icon registry for the FoodGo design system.
///
/// The app standardises on the Material Symbols/Icons family (already shipped
/// with Flutter) instead of mixing icon packs. Screens should reference these
/// semantic names so navigation, status and action icons stay visually and
/// behaviourally consistent across themes.
abstract final class AppIcons {
  // Navigation
  static const IconData home = Icons.home_outlined;
  static const IconData homeSelected = Icons.home_rounded;
  static const IconData saved = Icons.favorite_outline_rounded;
  static const IconData savedSelected = Icons.favorite_rounded;
  static const IconData cart = Icons.shopping_bag_outlined;
  static const IconData cartSelected = Icons.shopping_bag_rounded;
  static const IconData offers = Icons.local_offer_outlined;
  static const IconData offersSelected = Icons.local_offer_rounded;
  static const IconData profile = Icons.person_outline_rounded;
  static const IconData profileSelected = Icons.person_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData map = Icons.map_outlined;
  static const IconData orders = Icons.receipt_long_rounded;

  // Actions & chrome
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData reset = Icons.refresh_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData filter = Icons.tune_rounded;

  // Appearance
  static const IconData theme = Icons.palette_outlined;
  static const IconData systemMode = Icons.brightness_auto_rounded;
  static const IconData lightMode = Icons.light_mode_rounded;
  static const IconData darkMode = Icons.dark_mode_rounded;
  static const IconData motion = Icons.motion_photos_on_outlined;

  // Domain
  static const IconData restaurant = Icons.restaurant_rounded;
  static const IconData delivery = Icons.delivery_dining_rounded;
  static const IconData qrScan = Icons.qr_code_scanner_rounded;
  static const IconData payment = Icons.payments_outlined;
  static const IconData notifications = Icons.notifications_none_rounded;
  static const IconData support = Icons.support_agent_rounded;
  static const IconData admin = Icons.analytics_outlined;

  // Status
  static const IconData success = Icons.check_circle_outline_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData loading = Icons.hourglass_top_rounded;
}

/// Shared icon dimensions. Keeping these fixed avoids the 13/17/23/26px
/// one-off sizes that make interfaces feel visually noisy.
abstract final class AppIconSizes {
  static const double xs = 14;
  static const double sm = 18;
  static const double md = 22;
  static const double lg = 28;
  static const double xl = 40;
  static const double emptyState = 72;
}
