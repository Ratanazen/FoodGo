import 'package:flutter/material.dart';

/// Semantic icon registry for the FoodGo design system.
///
/// Standardises on the Material Icons / Symbols family shipped with Flutter
/// to guarantee crisp rendering across device pixel densities, contrast-awareness,
/// and consistent stroke weight and geometric proportions.
abstract final class AppIcons {
  // ── Navigation & Core Chrome ──────────────────────────────────────────────
  static const IconData home = Icons.home_outlined;
  static const IconData homeSelected = Icons.home_rounded;
  static const IconData saved = Icons.favorite_outline_rounded;
  static const IconData savedSelected = Icons.favorite_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteBorder = Icons.favorite_outline_rounded;
  static const IconData cart = Icons.shopping_bag_outlined;
  static const IconData cartSelected = Icons.shopping_bag_rounded;
  static const IconData offers = Icons.local_offer_outlined;
  static const IconData offersSelected = Icons.local_offer_rounded;
  static const IconData profile = Icons.person_outline_rounded;
  static const IconData profileSelected = Icons.person_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.tune_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData map = Icons.map_outlined;
  static const IconData orders = Icons.receipt_long_rounded;
  static const IconData ordersSelected = Icons.receipt_long;

  // ── Actions & Controls ───────────────────────────────────────────────────
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData forward = Icons.arrow_forward_ios_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData chevronDown = Icons.keyboard_arrow_down_rounded;
  static const IconData reset = Icons.refresh_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData remove = Icons.remove_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData copy = Icons.content_copy_rounded;
  static const IconData edit = Icons.edit_outlined;
  static const IconData send = Icons.send_rounded;
  static const IconData arrowForward = Icons.arrow_forward_rounded;
  static const IconData radioSelected = Icons.radio_button_checked;
  static const IconData radioUnselected = Icons.radio_button_unchecked;
  static const IconData fastDelivery = Icons.bolt_rounded;
  static const IconData server = Icons.dns_rounded;
  static const IconData dns = Icons.dns_rounded;

  // ── Food Categories ──────────────────────────────────────────────────────
  static const IconData allCategories = Icons.restaurant_menu_rounded;
  static const IconData foodCategory = Icons.restaurant_menu_rounded;
  static const IconData burger = Icons.lunch_dining_rounded;
  static const IconData pizza = Icons.local_pizza_rounded;
  static const IconData asian = Icons.ramen_dining_rounded;
  static const IconData noodle = Icons.dinner_dining_rounded;
  static const IconData drink = Icons.local_cafe_rounded;
  static const IconData dessert = Icons.icecream_rounded;
  static const IconData snack = Icons.fastfood_rounded;
  static const IconData bakery = Icons.bakery_dining_rounded;
  static const IconData organic = Icons.eco_rounded;
  static const IconData salad = Icons.eco_rounded;
  static const IconData healthy = Icons.spa_rounded;
  static const IconData sushi = Icons.set_meal_rounded;
  static const IconData chicken = Icons.kebab_dining_rounded;
  static const IconData seafood = Icons.set_meal_rounded;
  static const IconData meat = Icons.kebab_dining_rounded;

  // ── Location & Delivery Tracking ─────────────────────────────────────────
  static const IconData location = Icons.location_on_rounded;
  static const IconData locationOutline = Icons.location_on_outlined;
  static const IconData gps = Icons.my_location_rounded;
  static const IconData delivery = Icons.delivery_dining_rounded;
  static const IconData motorcycle = Icons.two_wheeler_rounded;
  static const IconData route = Icons.alt_route_rounded;
  static const IconData eta = Icons.schedule_rounded;
  static const IconData distance = Icons.straighten_rounded;

  // ── QR & Scanner ─────────────────────────────────────────────────────────
  static const IconData qrScan = Icons.qr_code_scanner_rounded;
  static const IconData qrCode = Icons.qr_code_2_rounded;
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData gallery = Icons.photo_library_rounded;
  static const IconData link = Icons.link_rounded;
  static const IconData badge = Icons.badge_outlined;
  static const IconData flashlightOn = Icons.flash_on_rounded;
  static const IconData flashlightOff = Icons.flash_off_rounded;

  // ── Payment & Transactions ───────────────────────────────────────────────
  static const IconData payment = Icons.payments_outlined;
  static const IconData paymentFilled = Icons.payments_rounded;
  static const IconData wallet = Icons.account_balance_wallet_outlined;
  static const IconData walletFilled = Icons.account_balance_wallet_rounded;
  static const IconData creditCard = Icons.credit_card_rounded;
  static const IconData bankTransfer = Icons.account_balance_rounded;
  static const IconData receipt = Icons.receipt_rounded;
  static const IconData coupon = Icons.confirmation_number_outlined;
  static const IconData discount = Icons.percent_rounded;

  // ── Profile & Account ────────────────────────────────────────────────────
  static const IconData addresses = Icons.home_work_outlined;
  static const IconData security = Icons.shield_outlined;
  static const IconData lock = Icons.lock_outline_rounded;
  static const IconData passwordVisible = Icons.visibility_outlined;
  static const IconData passwordHidden = Icons.visibility_off_outlined;
  static const IconData phone = Icons.phone_android_rounded;
  static const IconData email = Icons.mail_outline_rounded;
  static const IconData mail = Icons.mail_outline_rounded;
  static const IconData notifications = Icons.notifications_none_rounded;
  static const IconData notificationsActive =
      Icons.notifications_active_rounded;
  static const IconData support = Icons.support_agent_rounded;
  static const IconData help = Icons.help_outline_rounded;
  static const IconData settings = Icons.settings_outlined;
  static const IconData language = Icons.language_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData login = Icons.login_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData starOutline = Icons.star_outline_rounded;

  // ── Admin & Operational ──────────────────────────────────────────────────
  static const IconData admin = Icons.analytics_outlined;
  static const IconData dashboard = Icons.dashboard_outlined;
  static const IconData users = Icons.people_outline_rounded;
  static const IconData restaurants = Icons.storefront_rounded;
  static const IconData drivers = Icons.sports_motorsports_rounded;
  static const IconData trendUp = Icons.trending_up_rounded;
  static const IconData trendDown = Icons.trending_down_rounded;

  // ── Appearance & Themes ──────────────────────────────────────────────────
  static const IconData theme = Icons.palette_outlined;
  static const IconData themeFilled = Icons.palette_rounded;
  static const IconData sparkles = Icons.auto_awesome_rounded;
  static const IconData systemMode = Icons.brightness_auto_rounded;
  static const IconData lightMode = Icons.light_mode_rounded;
  static const IconData darkMode = Icons.dark_mode_rounded;
  static const IconData motion = Icons.motion_photos_on_outlined;
  static const IconData festive = Icons.celebration_rounded;

  // ── Feedback & State ─────────────────────────────────────────────────────
  static const IconData success = Icons.check_circle_outline_rounded;
  static const IconData successFilled = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData errorFilled = Icons.error_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData loading = Icons.hourglass_top_rounded;
  static const IconData offline = Icons.cloud_off_rounded;
  static const IconData emptyState = Icons.fastfood_outlined;

  /// Accessible wrapper for icons with semantic label and desktop tooltip.
  static Widget render(
    IconData iconData, {
    double size = AppIconSizes.md,
    Color? color,
    String? semanticLabel,
    String? tooltip,
  }) {
    final iconWidget = Icon(
      iconData,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, preferBelow: false, child: iconWidget);
    }

    return iconWidget;
  }
}

/// Standardised icon dimensions across the FoodGo design system.
///
/// Prevents arbitrary 13/17/23/27px sizes that create visual vibration.
abstract final class AppIconSizes {
  /// 12px: Badges, tiny status indicators, chip accessories
  static const double xxs = 12;

  /// 14px: Inline caption hints, rating stars
  static const double xs = 14;

  /// 18px: Form field accessories, secondary buttons, list item secondary icons
  static const double sm = 18;

  /// 22px: Standard action buttons, primary list trailing icons, dialog icons
  static const double md = 22;

  /// 26px: Bottom navigation icons, hero actions
  static const double lg = 26;

  /// 32px: Prominent feature icons, category headers
  static const double xl = 32;

  /// 44px: Avatar badges, modal header accent icons
  static const double xxl = 44;

  /// 72px: Empty states, error illustration anchors
  static const double emptyState = 72;
}
