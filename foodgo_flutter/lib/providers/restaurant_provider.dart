import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class RestaurantProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _restaurants = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<dynamic> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  RestaurantProvider() {
    _loadFromCache();
  }

  static const Duration _cacheTtl = Duration(minutes: 15);

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTime = prefs.getInt('cached_restaurants_timestamp');
      final cached = prefs.getString('cached_restaurants_v2');
      if (cached != null && cached.isNotEmpty && _restaurants.isEmpty) {
        final List<dynamic> decoded = jsonDecode(cached);
        if (decoded.isNotEmpty) {
          _restaurants = decoded;
          notifyListeners();
        }
      }
      if (cachedTime != null) {
        final cachedDate = DateTime.fromMillisecondsSinceEpoch(cachedTime);
        if (DateTime.now().difference(cachedDate) > _cacheTtl) {
          fetchRestaurants();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_restaurants_v2', jsonEncode(data));
      await prefs.setInt(
        'cached_restaurants_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> fetchRestaurants() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.get('restaurants/');
      if (data is List && data.isNotEmpty) {
        _restaurants = data;
        _saveToCache(data);
        _hasError = false;
      } else if (_restaurants.isEmpty) {
        // If server returned empty, fallback to rich offline catalog
        _restaurants = _defaultFallbackRestaurants;
      }
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
      _hasError = true;
      _errorMessage = 'Could not connect to restaurant catalog';

      // If we don't have cached data, populate default catalog so user is never stuck
      if (_restaurants.isEmpty) {
        _restaurants = _defaultFallbackRestaurants;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadDemoFallback() {
    _restaurants = _defaultFallbackRestaurants;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  static final List<dynamic> _defaultFallbackRestaurants = [
    {
      "id": 1,
      "name": "Glass Burger",
      "category": 2,
      "description": "Phnom Penh's finest smashed burgers, hand-crafted sides, and thick shakes.",
      "address": "Street 308, BKK1, Phnom Penh",
      "phone": "+855 12 345 678",
      "logo": "https://images.unsplash.com/photo-1550547660-d9450f859349?w=300&q=80",
      "banner": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80",
      "rating": "4.85",
      "delivery_time_min": 15,
      "delivery_time_max": 35,
      "delivery_fee": "1.50",
      "is_active": true,
      "food_categories": [
        {
          "id": 1,
          "name": "Burgers",
          "items": [
            {
              "id": 1,
              "name": "Classic Double Smash Cheeseburger",
              "description": "Two 100% Angus patties smashed crispy with double American cheese, caramelized onions, house pickles, and secret sauce on brioche.",
              "price": "6.50",
              "image": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80",
              "is_available": true,
            },
            {
              "id": 2,
              "name": "Truffle Bacon Swiss Burger",
              "description": "Angus beef patty with Swiss cheese, crispy smoked bacon, sautéed wild mushrooms, and black truffle aioli.",
              "price": "8.50",
              "image": "https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=600&q=80",
              "is_available": true,
            },
            {
              "id": 3,
              "name": "Crispy Spicy Chicken Burger",
              "description": "Buttermilk fried chicken breast, spicy habanero glaze, creamy coleslaw, and sweet pickles.",
              "price": "5.90",
              "image": "https://images.unsplash.com/photo-1625813506062-0aeb1d7a094b?w=600&q=80",
              "is_available": true,
            },
          ],
        },
        {
          "id": 2,
          "name": "Sides & Drinks",
          "items": [
            {
              "id": 4,
              "name": "Golden Truffle Parmesan Fries",
              "description": "Hand-cut crispy fries tossed in white truffle oil, grated parmesan, and chopped fresh parsley.",
              "price": "3.50",
              "image": "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600&q=80",
              "is_available": true,
            },
            {
              "id": 5,
              "name": "Salted Caramel Milkshake",
              "description": "Velvety vanilla bean ice cream spun with house-made salted caramel and topped with whipped cream.",
              "price": "3.80",
              "image": "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=600&q=80",
              "is_available": true,
            },
          ],
        },
      ],
    },
    {
      "id": 2,
      "name": "Crystal Pizza",
      "category": 3,
      "description": "Wood-fired artisanal pizzas fermented for 48 hours with imported Italian flour and San Marzano tomatoes.",
      "address": "Street 240, Daun Penh, Phnom Penh",
      "phone": "+855 23 888 999",
      "logo": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=300&q=80",
      "banner": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80",
      "rating": "4.92",
      "delivery_time_min": 20,
      "delivery_time_max": 40,
      "delivery_fee": "0.00",
      "is_active": true,
      "food_categories": [
        {
          "id": 3,
          "name": "Pizzas",
          "items": [
            {
              "id": 6,
              "name": "Pepperoni Supreme Pizza",
              "description": "San Marzano tomato sauce, fior di latte mozzarella, double artisan pepperoni cups, hot honey drizzle, fresh basil.",
              "price": "11.50",
              "image": "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600&q=80",
              "is_available": true,
            },
            {
              "id": 7,
              "name": "Margherita Di Bufala",
              "description": "Creamy buffalo mozzarella, fresh cherry tomatoes, basil pesto, and extra virgin olive oil.",
              "price": "9.80",
              "image": "https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=600&q=80",
              "is_available": true,
            },
          ],
        },
      ],
    },
    {
      "id": 3,
      "name": "Phnom Penh Flavors (Khmer Kitchen)",
      "category": 1,
      "description": "Authentic Cambodian royal recipes, rich coconut curries, and fragrant Kampot pepper specialties.",
      "address": "Riverside Sisowath Quay, Phnom Penh",
      "phone": "+855 11 222 333",
      "logo": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300&q=80",
      "banner": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
      "rating": "4.78",
      "delivery_time_min": 20,
      "delivery_time_max": 30,
      "delivery_fee": "1.00",
      "is_active": true,
      "food_categories": [
        {
          "id": 4,
          "name": "Khmer Specialties",
          "items": [
            {
              "id": 8,
              "name": "Kampot Pepper Beef Lok Lak",
              "description": "Tender grass-fed beef cubes seared with Kampot peppercorns, served with lime-pepper dipping sauce and jasmine rice.",
              "price": "7.50",
              "image": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80",
              "is_available": true,
            },
            {
              "id": 9,
              "name": "Traditional Royal Fish Amok",
              "description": "Steamed river snakehead fish in kroeung lemongrass paste, rich coconut cream, and noni leaves served in a banana leaf.",
              "price": "8.00",
              "image": "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600&q=80",
              "is_available": true,
            },
          ],
        },
      ],
    },
  ];
}
