import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/glass/glass_widgets.dart';
import '../../widgets/glass_container.dart';
import '../../core/theme/glass_theme.dart';

// Only import geolocator on supported platforms
import 'map_screen_location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  // Default to Phnom Penh coordinates as a sensible fallback
  LatLng _currentLocation = const LatLng(11.5564, 104.9282);
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // Geolocator is not supported on Linux/Web desktops in the same way
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS) {
      return;
    }

    setState(() => _isLoadingLocation = true);

    final result = await getDeviceLocation();
    if (result != null && mounted) {
      setState(() {
        _currentLocation = result;
        _isLoadingLocation = false;
      });
      _mapController.move(_currentLocation, 15.0);
    } else if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Track Order',
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 220.0),
        child: FloatingActionButton(
          onPressed: _getCurrentLocation,
          backgroundColor: GlassTheme.primaryGreen,
          child: _isLoadingLocation
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.foodgo',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                  // Mock delivery driver marker nearby
                  Marker(
                    point: LatLng(
                      _currentLocation.latitude + 0.005,
                      _currentLocation.longitude + 0.005,
                    ),
                    child: const Icon(Icons.delivery_dining, color: GlassTheme.primaryGreen, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GlassContainer(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Order Progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusIcon(Icons.receipt, true),
                        _buildLine(true),
                        _buildStatusIcon(Icons.soup_kitchen, true),
                        _buildLine(false),
                        _buildStatusIcon(Icons.directions_bike, false),
                        _buildLine(false),
                        _buildStatusIcon(Icons.home, false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Confirmed', style: TextStyle(fontSize: 10, color: GlassTheme.primaryGreen)),
                        Text('Preparing', style: TextStyle(fontSize: 10, color: GlassTheme.primaryGreen)),
                        Text('Picked Up', style: TextStyle(fontSize: 10, color: GlassTheme.textMuted)),
                        Text('Delivered', style: TextStyle(fontSize: 10, color: GlassTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        text: 'Back to Home',
                        icon: Icons.home,
                        onPressed: () => context.go('/home'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(IconData icon, bool active) {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(20),
      customColor: active
          ? GlassTheme.primaryGreen.withValues(alpha: 0.2)
          : Colors.grey.withValues(alpha: 0.2),
      child: Icon(
        icon,
        color: active ? GlassTheme.primaryGreen : GlassTheme.textMuted,
        size: 20,
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active
            ? GlassTheme.primaryGreen
            : GlassTheme.textMuted.withValues(alpha: 0.3),
      ),
    );
  }
}