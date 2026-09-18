import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/glass_theme.dart';
import '../widgets/glass/glass_widgets.dart';
import '../widgets/glass_container.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  final String orderId;
  const MapScreen({super.key, required this.orderId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _cameraController;
  
  bool _isLoadingLocation = true;
  LatLng? _restaurantLocation;
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  String _orderStatus = 'pending';
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(vsync: this, duration: 1500.ms);
    _fetchTrackingData();
    // Poll every 5 seconds for driver updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _fetchTrackingData(animate: false);
    });
  }
  
  @override
  void dispose() {
    _cameraController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTrackingData({bool animate = true}) async {
    try {
      final data = await ApiService().get('orders/${widget.orderId}/track/');
      if (!mounted) return;
      
      setState(() {
        _orderStatus = data['status'] ?? 'pending';
        
        if (data['restaurant_location'] != null) {
          _restaurantLocation = LatLng(
            double.parse(data['restaurant_location']['lat'].toString()),
            double.parse(data['restaurant_location']['lng'].toString()),
          );
        }
        if (data['customer_location'] != null) {
          _customerLocation = LatLng(
            double.parse(data['customer_location']['lat'].toString()),
            double.parse(data['customer_location']['lng'].toString()),
          );
        }
        if (data['driver_location'] != null) {
          _driverLocation = LatLng(
            double.parse(data['driver_location']['lat'].toString()),
            double.parse(data['driver_location']['lng'].toString()),
          );
        }
        
        _isLoadingLocation = false;
      });

      if (animate && _driverLocation != null) {
        _animatedMapMove(_driverLocation!, 14.5);
      } else if (animate && _restaurantLocation != null) {
        _animatedMapMove(_restaurantLocation!, 14.5);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted || !_mapController.camera.center.latitude.isFinite) return;
    
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

  @override
  Widget build(BuildContext context) {
    // Default fallback center
    final center = _driverLocation ?? _restaurantLocation ?? _customerLocation ?? const LatLng(37.7749, -122.4194);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Track Order',
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 220.0),
        child: FloatingActionButton(
          onPressed: () => _fetchTrackingData(animate: true),
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
              initialCenter: center,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodgo.app',
              ),
              if (_restaurantLocation != null && _customerLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_restaurantLocation!, _customerLocation!],
                      color: GlassTheme.primaryGreen.withValues(alpha: 0.5),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              if (_driverLocation != null && _customerLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_driverLocation!, _customerLocation!],
                      color: GlassTheme.primaryGreen,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_restaurantLocation != null)
                    Marker(
                      point: _restaurantLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.store, color: Colors.blue, size: 40),
                    ),
                  if (_customerLocation != null)
                    Marker(
                      point: _customerLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40)
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.seconds)
                          .tint(color: Colors.redAccent, end: 0.5),
                    ),
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
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
                    Text(
                      'Order Status: ${_orderStatus.toUpperCase()}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusIcon(Icons.receipt, true),
                        _buildLine(true),
                        _buildStatusIcon(Icons.soup_kitchen, _orderStatus != 'pending'),
                        _buildLine(_orderStatus == 'on_the_way' || _orderStatus == 'delivered'),
                        _buildStatusIcon(Icons.directions_bike, _orderStatus == 'on_the_way' || _orderStatus == 'delivered')
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2.seconds, color: Colors.white30),
                        _buildLine(_orderStatus == 'delivered'),
                        _buildStatusIcon(Icons.home, _orderStatus == 'delivered'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Confirmed', style: TextStyle(fontSize: 10, color: GlassTheme.primaryGreen)),
                        Text('Preparing', style: TextStyle(fontSize: 10, color: _orderStatus != 'pending' ? GlassTheme.primaryGreen : GlassTheme.textMuted)),
                        Text('Picked Up', style: TextStyle(fontSize: 10, color: _orderStatus == 'on_the_way' || _orderStatus == 'delivered' ? GlassTheme.primaryGreen : GlassTheme.textMuted)),
                        Text('Delivered', style: TextStyle(fontSize: 10, color: _orderStatus == 'delivered' ? GlassTheme.primaryGreen : GlassTheme.textMuted)),
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
