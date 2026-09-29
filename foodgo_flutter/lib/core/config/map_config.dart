import 'dart:math';
import 'package:latlong2/latlong.dart';

enum MapLayerType {
  googleRoadmap,
  googleSatellite,
  googleTerrain,
  openStreetMap,
}

class MapConfig {
  /// Google Maps Platform API Key
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyC3asDbdqC77DpPZt8DSttWJ2r9hLGT2PA',
  );

  /// Default center coordinates for FoodGo (Phnom Penh, Cambodia)
  static const LatLng defaultCenter = LatLng(11.5564, 104.9282);
  static const double defaultZoom = 14.5;

  /// High-performance Google Maps tile subdomains
  static const List<String> googleSubdomains = ['0', '1', '2', '3'];

  /// Returns the appropriate tile URL template for the selected map layer
  static String getTileUrl(MapLayerType type) {
    switch (type) {
      case MapLayerType.googleRoadmap:
        return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=$googleMapsApiKey';
      case MapLayerType.googleSatellite:
        return 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}&key=$googleMapsApiKey';
      case MapLayerType.googleTerrain:
        return 'https://mt{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}&key=$googleMapsApiKey';
      case MapLayerType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  /// Human-readable label for map layers
  static String getLayerName(MapLayerType type) {
    switch (type) {
      case MapLayerType.googleRoadmap:
        return 'Google Roadmap';
      case MapLayerType.googleSatellite:
        return 'Google Satellite';
      case MapLayerType.googleTerrain:
        return 'Google Terrain';
      case MapLayerType.openStreetMap:
        return 'OpenStreetMap';
    }
  }

  /// Calculates geodesic distance between two points in kilometers (Haversine formula)
  static double calculateDistanceKm(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(end.latitude - start.latitude);
    final dLng = _degreesToRadians(end.longitude - start.longitude);

    final lat1 = _degreesToRadians(start.latitude);
    final lat2 = _degreesToRadians(end.latitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
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
