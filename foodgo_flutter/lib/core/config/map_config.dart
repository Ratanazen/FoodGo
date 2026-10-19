import 'dart:math';

import 'package:latlong2/latlong.dart';

enum MapLayerType {
  openStreetMap,
  cartoDark,
  cartoVoyager,
  openTopoMap,
  googleRoadmap,
}

class MapConfig {
  /// Default center coordinates for FoodGo (Phnom Penh, Cambodia)
  static const LatLng defaultCenter = LatLng(11.5564, 104.9282);
  static const double defaultZoom = 14.5;

  /// Subdomains for OpenMap & Carto tiles
  static const List<String> openSubdomains = ['a', 'b', 'c', 'd'];
  static const List<String> googleSubdomains = ['0', '1', '2', '3'];

  /// Optional Google Maps Platform API Key (if using Google fallback)
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// Returns the appropriate tile URL template for the selected map layer
  static String getTileUrl(MapLayerType type) {
    switch (type) {
      case MapLayerType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapLayerType.cartoDark:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapLayerType.cartoVoyager:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
      case MapLayerType.openTopoMap:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapLayerType.googleRoadmap:
        if (googleMapsApiKey.isNotEmpty) {
          return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=$googleMapsApiKey';
        }
        return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
  }

  /// Returns subdomains list for the layer
  static List<String> getSubdomains(MapLayerType type) {
    if (type == MapLayerType.googleRoadmap) {
      return googleSubdomains;
    }
    return openSubdomains;
  }

  /// Human-readable label for map layers
  static String getLayerName(MapLayerType type) {
    switch (type) {
      case MapLayerType.openStreetMap:
        return 'OpenStreetMap (Standard)';
      case MapLayerType.cartoDark:
        return 'OpenMap Dark (FoodGo)';
      case MapLayerType.cartoVoyager:
        return 'OpenMap Voyager (Clean)';
      case MapLayerType.openTopoMap:
        return 'OpenTopoMap (Terrain)';
      case MapLayerType.googleRoadmap:
        return 'Google Roadmap';
    }
  }

  /// Calculates geodesic distance between two points in kilometers (Haversine formula)
  static double calculateDistanceKm(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(end.latitude - start.latitude);
    final dLng = _degreesToRadians(end.longitude - start.longitude);

    final lat1 = _degreesToRadians(start.latitude);
    final lat2 = _degreesToRadians(end.latitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Estimates delivery arrival time in minutes based on urban motorbike speed (~25 km/h)
  static int estimateDeliveryMinutes(double distanceKm) {
    if (distanceKm <= 0.1) return 2;
    final travelMinutes = (distanceKm / 25.0 * 60.0).round();
    return max(3, travelMinutes + 2);
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}
