import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/glass/glass_widgets.dart';
import '../../widgets/glass_container.dart';
import '../../core/theme/glass_theme.dart';
import 'map_screen_location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  // Default to Phnom Penh coordinates as a sensible fallback
  LatLng _currentLocation = const LatLng(11.5564, 104.9282);
  bool _isLoadingLocation = false;
  
  // Animation controller for smooth map movement
  late final AnimationController _cameraController;

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final Animation<double> animation = CurvedAnimation(parent: _cameraController, curve: Curves.easeInOut);

    _cameraController.reset();
    
    _cameraController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });
    
    _cameraController.forward();
  }

  Future<void> _getCurrentLocation() async {
    // Geolocator is not supported safely on desktop out-of-the-box without extra plugins
    if (kIsWeb || 
        defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }

    setState(() => _isLoadingLocation = true);

    final result = await getDeviceLocation();
    if (result != null && mounted) {
      setState(() {
        _currentLocation = result;
        _isLoadingLocation = false;
      });
      // Use smooth animation to the new location!
      _animatedMapMove(_currentLocation, 15.0);
    } else if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverLocation = LatLng(
      _currentLocation.latitude + 0.005,
      _currentLocation.longitude + 0.005,
    );

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
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodgo.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      _currentLocation,
                      driverLocation,
                    ],
                    color: GlassTheme.primaryGreen,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Destination marker with pulsing animation
                  Marker(
                    point: _currentLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40)
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.seconds)
                        .tint(color: Colors.redAccent, end: 0.5),
                  ),
                  // Delivery driver marker with gentle bobbing animation
                  Marker(
                    point: driverLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.delivery_dining, color: GlassTheme.primaryGreen, size: 30),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .slideY(begin: 0, end: -0.2, duration: 800.ms, curve: Curves.easeInOut),
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
                        _buildStatusIcon(Icons.directions_bike, false)
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2.seconds, color: Colors.white30),
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
            ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
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
