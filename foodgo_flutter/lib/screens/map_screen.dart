import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/theme/glass_theme.dart';
import '../core/config/map_config.dart';
import '../widgets/glass/glass_widgets.dart';
import '../widgets/glass_container.dart';
import '../services/api_service.dart';
import 'map_screen_location.dart';

class MapScreen extends StatefulWidget {
  final String orderId;
  const MapScreen({super.key, required this.orderId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _cameraController;
  WebSocketChannel? _channel;

  MapLayerType _selectedLayer = MapLayerType.googleRoadmap;
  bool _isLoading = true;
  String _orderStatus = 'pending';
  String? _restaurantName;
  String? _deliveryAddress;

  LatLng? _restaurantLocation;
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  LatLng? _myLocation;

  // Nearby restaurants list when in explore mode (orderId is empty)
  List<Map<String, dynamic>> _nearbyRestaurants = [];
  Map<String, dynamic>? _selectedRestaurant;

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    if (widget.orderId.isNotEmpty && widget.orderId != '0') {
      _fetchOrderTrackingData();
      _connectWebSocket();
    } else {
      _fetchNearbyRestaurants();
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  bool get _isTrackingMode => widget.orderId.isNotEmpty && widget.orderId != '0';

  void _connectWebSocket() {
    try {
      const defaultWsBase = String.fromEnvironment('FOODGO_WS_URL', defaultValue: 'ws://127.0.0.1:8000/ws/tracking/');
      final normalizedWsBase = defaultWsBase.endsWith('/') ? defaultWsBase : '$defaultWsBase/';
      final wsUrl = Uri.parse('$normalizedWsBase${widget.orderId}/');
      _channel = WebSocketChannel.connect(wsUrl);
      _channel?.stream.listen((message) {
        if (!mounted) return;
        try {
          final data = jsonDecode(message);
          if (data['type'] == 'driver_location') {
            setState(() {
              _driverLocation = LatLng(
                double.parse(data['lat'].toString()),
                double.parse(data['lng'].toString()),
              );
            });
            _animatedMapMove(_driverLocation!, 15.0);
          }
        } catch (_) {}
      }, onError: (error) {
        debugPrint('WebSocket error: $error');
      });
    } catch (_) {}
  }

  Future<void> _fetchOrderTrackingData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().get('orders/${widget.orderId}/track/');
      if (!mounted) return;

      setState(() {
        _orderStatus = data['status'] ?? 'pending';
        _restaurantName = data['restaurant_name'];
        _deliveryAddress = data['delivery_address'];

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

        _isLoading = false;
      });

      final focusTarget = _driverLocation ?? _restaurantLocation ?? _customerLocation;
      if (focusTarget != null) {
        _animatedMapMove(focusTarget, 14.8);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Graceful fallback coordinates
          _restaurantLocation = const LatLng(11.5564, 104.9282);
          _customerLocation = const LatLng(11.5621, 104.9160);
          _driverLocation = const LatLng(11.5590, 104.9220);
        });
      }
    }
  }

  Future<void> _fetchNearbyRestaurants() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().get('restaurants/');
      final List<dynamic> list = data is List ? data : (data['results'] as List<dynamic>? ?? []);
      if (!mounted) return;

      final restaurants = <Map<String, dynamic>>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          restaurants.add(item);
        }
      }

      setState(() {
        _nearbyRestaurants = restaurants;
        _isLoading = false;
      });

      if (_nearbyRestaurants.isNotEmpty) {
        final first = _nearbyRestaurants.first;
        if (first['lat'] != null && first['lng'] != null) {
          final lat = double.tryParse(first['lat'].toString()) ?? MapConfig.defaultCenter.latitude;
          final lng = double.tryParse(first['lng'].toString()) ?? MapConfig.defaultCenter.longitude;
          _animatedMapMove(LatLng(lat, lng), 14.2);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCurrentLocation() async {
    final loc = await getDeviceLocation();
    if (loc != null && mounted) {
      setState(() => _myLocation = loc);
      _animatedMapMove(loc, 15.5);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centered on your location'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission required or unavailable'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;

    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final Animation<double> animation = CurvedAnimation(parent: _cameraController, curve: Curves.easeInOutCubic);

    _cameraController.reset();
    void listener() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    }

    _cameraController.addListener(listener);
    _cameraController.forward().then((_) {
      _cameraController.removeListener(listener);
    });
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _animatedMapMove(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _animatedMapMove(_mapController.camera.center, currentZoom - 1.0);
  }

  void _showLayerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Map Layer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Google Maps Engine', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLayerOption(
                MapLayerType.googleRoadmap,
                'Google Roadmap',
                'Official street vectors with labeled landmarks',
                Icons.map,
              ),
              _buildLayerOption(
                MapLayerType.googleSatellite,
                'Google Satellite / Hybrid',
                'High-resolution aerial satellite imagery with streets',
                Icons.satellite_alt,
              ),
              _buildLayerOption(
                MapLayerType.googleTerrain,
                'Google Terrain',
                'Topographical contours and elevation features',
                Icons.terrain,
              ),
              _buildLayerOption(
                MapLayerType.openStreetMap,
                'OpenStreetMap',
                'Open community street raster tiles',
                Icons.public,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLayerOption(MapLayerType type, String title, String subtitle, IconData icon) {
    final isSelected = _selectedLayer == type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          setState(() => _selectedLayer = type);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? GlassTheme.primaryGreen.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isSelected ? GlassTheme.primaryGreen : Colors.white.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? GlassTheme.primaryGreen : Colors.white70),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? GlassTheme.primaryGreen : Colors.white)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: GlassTheme.textMuted)),
                  ],
                ),
              ),
              if (isSelected) const Icon(Icons.check_circle, color: GlassTheme.primaryGreen, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _driverLocation ?? _restaurantLocation ?? _customerLocation ?? MapConfig.defaultCenter;

    // Calculate distance and ETA
    double? distanceKm;
    int? etaMinutes;
    if (_driverLocation != null && _customerLocation != null) {
      distanceKm = MapConfig.calculateDistanceKm(_driverLocation!, _customerLocation!);
      etaMinutes = MapConfig.estimateDeliveryMinutes(distanceKm);
    }

    final isGoogleLayer = _selectedLayer != MapLayerType.openStreetMap;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: _isTrackingMode ? 'Live Order Tracking' : 'Explore on Google Maps',
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined, color: Colors.white),
            tooltip: 'Switch Map Layer',
            onPressed: _showLayerSelector,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _isTrackingMode ? _fetchOrderTrackingData : _fetchNearbyRestaurants,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map View ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: MapConfig.defaultZoom,
              minZoom: 4,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.getTileUrl(_selectedLayer),
                subdomains: isGoogleLayer ? MapConfig.googleSubdomains : const ['a', 'b', 'c'],
                userAgentPackageName: 'com.foodgo.app',
              ),

              // Polyline connecting restaurant -> driver -> customer
              if (_isTrackingMode) ...[
                if (_restaurantLocation != null && _customerLocation != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_restaurantLocation!, _customerLocation!],
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.35),
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
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
              ],

              // Markers
              MarkerLayer(
                markers: [
                  // 1. Restaurant marker
                  if (_restaurantLocation != null)
                    Marker(
                      point: _restaurantLocation!,
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () => _showMarkerInfo('Restaurant', _restaurantName ?? 'Preparing your meal here'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: GlassTheme.mapBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, spreadRadius: 1)],
                          ),
                          child: const Icon(Icons.storefront, color: Colors.white, size: 28),
                        ),
                      ),
                    ),

                  // 2. Customer Drop-off Marker
                  if (_customerLocation != null)
                    Marker(
                      point: _customerLocation!,
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () => _showMarkerInfo('Drop-Off Destination', _deliveryAddress ?? 'Your delivery location'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: GlassTheme.mapRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, spreadRadius: 1)],
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 30),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15), duration: 800.ms),
                      ),
                    ),

                  // 3. Driver Live Marker
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 56,
                      height: 56,
                      child: GestureDetector(
                        onTap: () => _showMarkerInfo('Delivery Driver', 'Driver is on the way to your doorstep!'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: GlassTheme.primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(color: GlassTheme.primaryGreen.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.delivery_dining, color: Colors.white, size: 32),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .slideY(begin: 0, end: -0.15, duration: 700.ms, curve: Curves.easeInOut),
                      ),
                    ),

                  // 4. My Location Marker
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.blueAccent, blurRadius: 8)],
                        ),
                      ),
                    ),

                  // 5. Explore Mode: Nearby Restaurant Pins
                  if (!_isTrackingMode)
                    ..._nearbyRestaurants.map((res) {
                      final lat = double.tryParse(res['lat']?.toString() ?? '') ?? 11.5564;
                      final lng = double.tryParse(res['lng']?.toString() ?? '') ?? 104.9282;
                      final name = res['name']?.toString() ?? 'Restaurant';
                      return Marker(
                        point: LatLng(lat, lng),
                        width: 48,
                        height: 48,
                        child: Tooltip(
                          message: name,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedRestaurant = res);
                              _animatedMapMove(LatLng(lat, lng), 15.0);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: GlassTheme.mapDriverBike,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
                              ),
                              child: const Icon(Icons.restaurant, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),

          // ── Google Watermark / Attribution ───────────────────────
          if (isGoogleLayer)
            Positioned(
              left: 12,
              bottom: _isTrackingMode ? 260 : 130,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, size: 12, color: Colors.white70),
                    SizedBox(width: 4),
                    Text(
                      'Google Maps',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top ETA & Distance Floating Pill (Tracking Mode) ─────
          if (_isTrackingMode && distanceKm != null && etaMinutes != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              left: 16,
              right: 16,
              child: GlassContainer(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                customColor: Colors.black.withValues(alpha: 0.75),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: GlassTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Arrival: ~$etaMinutes mins',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km to your drop-off • Driver moving',
                            style: TextStyle(fontSize: 12, color: GlassTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.two_wheeler, color: GlassTheme.primaryGreen, size: 28),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.3, end: 0),
            ),

          // ── Floating Action Controls (Right Side) ────────────────
          Positioned(
            right: 16,
            bottom: _isTrackingMode ? 260 : 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Layer Selector Button
                FloatingActionButton.small(
                  heroTag: 'layer_btn',
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  onPressed: _showLayerSelector,
                  child: const Icon(Icons.layers, size: 20),
                ),
                const SizedBox(height: 8),

                // Re-center on Driver / Target
                FloatingActionButton.small(
                  heroTag: 'target_btn',
                  backgroundColor: GlassTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    final target = _driverLocation ?? _restaurantLocation ?? _customerLocation;
                    if (target != null) _animatedMapMove(target, 15.0);
                  },
                  child: const Icon(Icons.near_me, size: 20),
                ),
                const SizedBox(height: 8),

                // Current GPS Location Button
                FloatingActionButton.small(
                  heroTag: 'my_location_btn',
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.blueAccent,
                  onPressed: _fetchCurrentLocation,
                  child: const Icon(Icons.my_location, size: 20),
                ),
                const SizedBox(height: 8),

                // Zoom In
                FloatingActionButton.small(
                  heroTag: 'zoom_in_btn',
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, size: 20),
                ),
                const SizedBox(height: 8),

                // Zoom Out
                FloatingActionButton.small(
                  heroTag: 'zoom_out_btn',
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, size: 20),
                ),
              ],
            ),
          ),

          // ── Bottom Sheet (Tracking Mode) ─────────────────────────
          if (_isTrackingMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassContainer(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header & Order Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${widget.orderId}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _orderStatus.toUpperCase().replaceAll('_', ' '),
                              style: const TextStyle(
                                color: GlassTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status Step Timeline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusIcon(Icons.receipt, true),
                          _buildLine(true),
                          _buildStatusIcon(Icons.soup_kitchen, _orderStatus != 'pending'),
                          _buildLine(_orderStatus == 'on_the_way' || _orderStatus == 'on_delivery' || _orderStatus == 'delivered'),
                          _buildStatusIcon(Icons.directions_bike, _orderStatus == 'on_the_way' || _orderStatus == 'on_delivery' || _orderStatus == 'delivered')
                              .animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: const Duration(seconds: 2), color: Colors.white30),
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
                          Text('On Delivery', style: TextStyle(fontSize: 10, color: (_orderStatus == 'on_the_way' || _orderStatus == 'on_delivery' || _orderStatus == 'delivered') ? GlassTheme.primaryGreen : GlassTheme.textMuted)),
                          Text('Delivered', style: TextStyle(fontSize: 10, color: _orderStatus == 'delivered' ? GlassTheme.primaryGreen : GlassTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text('Back to Home'),
                              onPressed: () => context.go('/home'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassButton(
                              text: 'Order Details',
                              icon: Icons.receipt_long,
                              onPressed: () => context.go('/orders'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom Sheet (Explore Mode: Selected Restaurant) ─────
          if (!_isTrackingMode && _selectedRestaurant != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: GlassContainer(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.store, color: GlassTheme.primaryGreen, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRestaurant!['name'] ?? 'Restaurant',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedRestaurant!['address'] ?? 'Phnom Penh'} • Rating ${_selectedRestaurant!['rating'] ?? '4.8'}',
                                style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => setState(() => _selectedRestaurant = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        text: 'View Menu & Order',
                        icon: Icons.restaurant_menu,
                        onPressed: () {
                          final rid = _selectedRestaurant!['id'];
                          context.push('/restaurant/$rid');
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.3, end: 0),
            ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: GlassTheme.primaryGreen),
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
      customColor: active ? GlassTheme.primaryGreen.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
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
        color: active ? GlassTheme.primaryGreen : GlassTheme.textMuted.withValues(alpha: 0.3),
      ),
    );
  }

  void _showMarkerInfo(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.badgeTagDark,
        shape: RoundedRectangleBorder(borderRadius: GlassTheme.borderRadiusSmall),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text(description, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: GlassTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }
}
