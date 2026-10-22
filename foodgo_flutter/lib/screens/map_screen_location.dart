import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Returns the current device location as a [LatLng], or null if unavailable.
/// Only called on supported platforms (Android, iOS, Windows).
Future<LatLng?> getDeviceLocation() async {
  if (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows) {
    if (!kIsWeb) return null;
  }

  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        return LatLng(lastPos.latitude, lastPos.longitude);
      }
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }

    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    return null;
  } catch (_) {
    return null;
  }
}
