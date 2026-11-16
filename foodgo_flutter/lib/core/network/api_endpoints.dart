/// Centralized REST API endpoints for the FoodGo application.
class ApiEndpoints {
  ApiEndpoints._();

  // Authentication
  static const String login = 'token/';
  static const String refresh = 'token/refresh/';
  static const String register = 'register/';
  static const String googleAuth = 'auth/google/';
  static const String phoneAuth = 'auth/phone/';
  static const String verifyOtp = 'auth/verify-otp/';
  static const String profile = 'auth/profile/';

  // Catalog & Foods
  static const String foods = 'foods/';
  static const String categories = 'categories/';
  static const String restaurants = 'restaurants/';
  static const String recommendations = 'foods/recommendations/';
  static const String search = 'foods/search/';

  // Cart & Checkout
  static const String cart = 'cart/';
  static const String cartValidate = 'cart/validate/';
  static const String orders = 'orders/';
  static const String addresses = 'addresses/';
  static const String paymentMethods = 'payments/methods/';
  static const String khqrGenerate = 'payments/khqr/generate/';
  static const String khqrStatus = 'payments/khqr/status/';

  // Delivery & Tracking
  static const String liveTracking = 'tracking/';
  static const String notifications = 'notifications/';
  static const String currencyRates = 'currency/rates/';

  // Driver & Restaurant Portals
  static const String driverPortal = 'driver/portal/';
  static const String restaurantPortal = 'restaurant/portal/';
}
