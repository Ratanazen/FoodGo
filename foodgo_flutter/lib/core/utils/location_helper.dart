import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';

class LocationDetails {
  final String title;
  final String fullAddress;
  final String district;
  final String city;
  final double latitude;
  final double longitude;

  const LocationDetails({
    required this.title,
    required this.fullAddress,
    required this.district,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => fullAddress;
}

class LocationHelper {
  /// Known reference landmarks in Phnom Penh for instant offline resolution
  static final List<Map<String, dynamic>> _ppLandmarks = [
    {
      'name': 'Street 240, Daun Penh',
      'district': 'Daun Penh',
      'lat': 11.5605,
      'lng': 104.9282,
    },
    {
      'name': 'Riverside / Sisowath Quay',
      'district': 'Daun Penh',
      'lat': 11.5683,
      'lng': 104.9312,
    },
    {
      'name': 'Wat Phnom Cultural Hill',
      'district': 'Daun Penh',
      'lat': 11.5760,
      'lng': 104.9230,
    },
    {
      'name': 'BKK1 / Street 51 Pasteurs',
      'district': 'Boeung Keng Kang',
      'lat': 11.5510,
      'lng': 104.9260,
    },
    {
      'name': 'Bassac Lane Boutique Area',
      'district': 'Chamkarmon',
      'lat': 11.5490,
      'lng': 104.9315,
    },
    {
      'name': 'Toul Tompoung / Russian Market',
      'district': 'Chamkarmon',
      'lat': 11.5405,
      'lng': 104.9150,
    },
    {
      'name': 'TK Avenue / Street 315',
      'district': 'Tuol Kouk',
      'lat': 11.5835,
      'lng': 104.8965,
    },
    {
      'name': 'Olympic National Stadium',
      'district': '7 Makara',
      'lat': 11.5580,
      'lng': 104.9120,
    },
    {
      'name': 'Aeon Mall Sen Sok City',
      'district': 'Sen Sok',
      'lat': 11.5950,
      'lng': 104.8780,
    },
    {
      'name': 'Chroy Changvar Riverside',
      'district': 'Chroy Changvar',
      'lat': 11.5890,
      'lng': 104.9350,
    },
    {
      'name': 'Phnom Penh Int Airport Area',
      'district': 'Por Senchey',
      'lat': 11.5460,
      'lng': 104.8440,
    },
  ];

  /// Resolves latitude/longitude into human-readable Cambodian location name.
  /// Tries fast online reverse geocoding (1.5s timeout) with offline spatial fallback.
  static Future<LocationDetails> resolveLocation(double lat, double lng) async {
    // 1. Attempt online reverse geocoding via OpenStreetMap Nominatim
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(milliseconds: 1500),
          receiveTimeout: const Duration(milliseconds: 1500),
          headers: {'User-Agent': 'FoodGo-Cambodia-App/1.0'},
        ),
      );
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road =
              address['road'] ?? address['pedestrian'] ?? address['suburb'];
          final district =
              address['suburb'] ??
              address['city_district'] ??
              address['county'] ??
              'Daun Penh';
          final city = address['city'] ?? address['state'] ?? 'Phnom Penh';

          String title = road != null
              ? '$road, $district'
              : district.toString();
          String full = '$title, $city';
          return LocationDetails(
            title: title,
            fullAddress: full,
            district: district.toString(),
            city: city.toString(),
            latitude: lat,
            longitude: lng,
          );
        }
      }
    } catch (_) {
      // Graceful fallback to offline Phnom Penh spatial resolution
    }

    // 2. Offline nearest landmark resolution
    Map<String, dynamic> nearest = _ppLandmarks.first;
    double minDistance = double.infinity;

    for (final lm in _ppLandmarks) {
      final lmLat = lm['lat'] as double;
      final lmLng = lm['lng'] as double;
      final dist = _calculateDistance(lat, lng, lmLat, lmLng);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = lm;
      }
    }

    final landmarkName = nearest['name'] as String;
    final district = nearest['district'] as String;
    final city = 'Phnom Penh';

    return LocationDetails(
      title: landmarkName,
      fullAddress: '$landmarkName, $city',
      district: district,
      city: city,
      latitude: lat,
      longitude: lng,
    );
  }

  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }
}
