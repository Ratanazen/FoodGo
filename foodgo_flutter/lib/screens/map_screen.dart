import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/theme/glass_theme.dart';
import '../core/config/map_config.dart';
import '../core/config/app_config.dart';
import '../core/storage/secure_storage.dart';
import '../widgets/glass/glass_widgets.dart';
import '../widgets/glass_container.dart';
import '../services/api_service.dart';
import '../widgets/delivery_scanner_modal.dart';
import '../widgets/delivery_qr_modal.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'map_screen_location.dart';
import '../core/utils/location_helper.dart';

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

  MapLayerType _selectedLayer = MapLayerType.openStreetMap;
  bool _isLoading = true;
  String _orderStatus = 'pending';
  String? _restaurantName;
  String? _deliveryAddress;

  LatLng? _restaurantLocation;
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  LatLng? _myLocation;

  Map<String, dynamic>? _driverInfo;
  Timer? _liveMovementTimer;
  double _routeProgress = 0.45;
  double _currentSpeedKmH = 34.0;
  double _driverBearing = 0.0;

  // Nearby restaurants list when in explore mode (orderId is empty)
  List<Map<String, dynamic>> _nearbyRestaurants = [];
  Map<String, dynamic>? _selectedRestaurant;

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.orderId.isNotEmpty && widget.orderId != '0') {
      _fetchOrderTrackingData();
      _connectWebSocket();
      _startLiveDriverMovementSimulation();
    } else {
      _fetchNearbyRestaurants();
      _autoInitLocation();
    }
  }

  void _startLiveDriverMovementSimulation() {
    _liveMovementTimer?.cancel();
    _liveMovementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted ||
          _restaurantLocation == null ||
          _customerLocation == null) {
        return;
      }
      if (_orderStatus == 'delivered') {
        timer.cancel();
        return;
      }
      setState(() {
        _routeProgress += 0.03;
        if (_routeProgress > 0.95) _routeProgress = 0.95;

        final startLat = _restaurantLocation!.latitude;
        final startLng = _restaurantLocation!.longitude;
        final endLat = _customerLocation!.latitude;
        final endLng = _customerLocation!.longitude;

        final newLat = startLat + (endLat - startLat) * _routeProgress;
        final newLng = startLng + (endLng - startLng) * _routeProgress;
        _driverLocation = LatLng(newLat, newLng);

        final dLat = endLat - startLat;
        final dLng = endLng - startLng;
        _driverBearing =
            (math.atan2(dLng, dLat) * 180.0 / math.pi + 360.0) % 360.0;

        _currentSpeedKmH = 28.0 + (timer.tick % 5) * 2.5;
      });
    });
  }

  @override
  void dispose() {
    _liveMovementTimer?.cancel();
    _cameraController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  bool get _isTrackingMode =>
      widget.orderId.isNotEmpty && widget.orderId != '0';

  Future<void> _connectWebSocket() async {
    try {
      final token = await SecureStorage().getAccessToken() ?? '';
      final defaultWsBase = AppConfig.wsBaseUrl;
      final normalizedWsBase = defaultWsBase.endsWith('/')
          ? defaultWsBase
          : '$defaultWsBase/';
      final tokenParam = token.isNotEmpty
          ? '?token=$token'
          : '?token=simulator-token';
      final wsUrl = Uri.parse('$normalizedWsBase${widget.orderId}/$tokenParam');
      _channel = WebSocketChannel.connect(wsUrl);
      _channel?.stream.listen(
        (message) {
          if (!mounted) return;
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'driver_location') {
              final newLat = double.parse(data['lat'].toString());
              final newLng = double.parse(data['lng'].toString());
              final bearing =
                  double.tryParse(data['bearing']?.toString() ?? '') ??
                  _driverBearing;
              final speed =
                  double.tryParse(data['speed']?.toString() ?? '') ??
                  _currentSpeedKmH;

              setState(() {
                _driverLocation = LatLng(newLat, newLng);
                _driverBearing = bearing;
                _currentSpeedKmH = speed;
              });
              _animatedMapMove(_driverLocation!, 15.0);
            }
          } catch (_) {}
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
        },
      );
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
        if (data['driver'] != null && data['driver'] is Map) {
          _driverInfo = Map<String, dynamic>.from(data['driver']);
        } else {
          _driverInfo ??= {
            'id': 1,
            'name': 'Ahmad Faizal',
            'phone': '+855 12 888 999',
            'vehicle_type': 'Honda EX5 • Red',
            'license_plate': 'WXY 4821',
            'rating': 4.9,
            'trips': 2384,
            'avatar':
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=160&q=80',
          };
        }

        _isLoading = false;
      });

      final focusTarget =
          _driverLocation ?? _restaurantLocation ?? _customerLocation;
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
      final List<dynamic> list = data is List
          ? data
          : (data['results'] as List<dynamic>? ?? []);
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
          final lat =
              double.tryParse(first['lat'].toString()) ??
              MapConfig.defaultCenter.latitude;
          final lng =
              double.tryParse(first['lng'].toString()) ??
              MapConfig.defaultCenter.longitude;
          _animatedMapMove(LatLng(lat, lng), 14.2);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _autoInitLocation() async {
    final loc = await getDeviceLocation();
    if (loc != null && mounted) {
      final details = await LocationHelper.resolveLocation(
        loc.latitude,
        loc.longitude,
      );
      setState(() {
        _myLocation = loc;
        _deliveryAddress ??= details.fullAddress;
      });
      _animatedMapMove(loc, 15.0);
    }
  }

  Future<void> _fetchCurrentLocation() async {
    final loc = await getDeviceLocation();
    if (loc != null && mounted) {
      final details = await LocationHelper.resolveLocation(
        loc.latitude,
        loc.longitude,
      );
      if (!mounted) return;
      setState(() {
        _myLocation = loc;
        _deliveryAddress = details.fullAddress;
      });
      _animatedMapMove(loc, 15.8);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.my_location,
                color: GlassTheme.limeAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS Location: ${details.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      _animatedMapMove(MapConfig.defaultCenter, 14.5);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centered on Phnom Penh default location'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;

    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: _cameraController,
      curve: Curves.easeInOutCubic,
    );

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
                  const Text(
                    'Select Map Layer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'OpenMap Engine',
                      style: TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLayerOption(
                MapLayerType.openStreetMap,
                'OpenStreetMap',
                'Official community street map (Keyless & Open)',
                Icons.public,
              ),
              _buildLayerOption(
                MapLayerType.cartoDark,
                'OpenMap Dark Mode',
                'Sleek dark theme matching FoodGo styling',
                Icons.dark_mode,
              ),
              _buildLayerOption(
                MapLayerType.cartoVoyager,
                'OpenMap Voyager',
                'Clean, crisp modern street map',
                Icons.map,
              ),
              _buildLayerOption(
                MapLayerType.openTopoMap,
                'OpenTopoMap',
                'Topographical contours and elevation features',
                Icons.terrain,
              ),
              _buildLayerOption(
                MapLayerType.googleRoadmap,
                'Google Roadmap',
                'Optional Google vector street map fallback',
                Icons.layers,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLayerOption(
    MapLayerType type,
    String title,
    String subtitle,
    IconData icon,
  ) {
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
            color: isSelected
                ? GlassTheme.primaryGreen.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isSelected
                  ? GlassTheme.primaryGreen
                  : Colors.white.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? GlassTheme.primaryGreen : Colors.white70,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? GlassTheme.primaryGreen
                            : Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: GlassTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: GlassTheme.primaryGreen,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center =
        _driverLocation ??
        _restaurantLocation ??
        _customerLocation ??
        MapConfig.defaultCenter;

    // Calculate distance and ETA
    double? distanceKm;
    int? etaMinutes;
    if (_driverLocation != null && _customerLocation != null) {
      distanceKm = MapConfig.calculateDistanceKm(
        _driverLocation!,
        _customerLocation!,
      );
      etaMinutes = MapConfig.estimateDeliveryMinutes(distanceKm);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _isTrackingMode
          ? null
          : GlassAppBar(
              title: 'Explore on Map',
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Exit Map',
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.layers_outlined, color: Colors.white),
                  tooltip: 'Switch Map Layer',
                  onPressed: _showLayerSelector,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh',
                  onPressed: _fetchNearbyRestaurants,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Exit Map',
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/home');
                    }
                  },
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
                subdomains: MapConfig.getSubdomains(_selectedLayer),
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
                        onTap: () => _showMarkerInfo(
                          'Restaurant',
                          _restaurantName ?? 'Preparing your meal here',
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: GlassTheme.mapBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: Colors.white,
                            size: 28,
                          ),
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
                        onTap: () => _showMarkerInfo(
                          'Drop-Off Destination',
                          _deliveryAddress ?? 'Your delivery location',
                        ),
                        child:
                            Container(
                                  decoration: BoxDecoration(
                                    color: GlassTheme.mapRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true),
                                )
                                .scale(
                                  begin: const Offset(1.0, 1.0),
                                  end: const Offset(1.15, 1.15),
                                  duration: 800.ms,
                                ),
                      ),
                    ),

                  // 3. Driver Live Marker with animated pulsing halo and speed tag
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 140,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => _showMarkerInfo(
                          _driverInfo?['name'] ?? 'Delivery Driver',
                          '${_driverInfo?['vehicle_type'] ?? 'Motorcycle'} • Speed: ${_currentSpeedKmH.toStringAsFixed(0)} km/h • On the way to your doorstep!',
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Floating Driver Name & Speed Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: GlassTheme.primaryGreen,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: GlassTheme.primaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                      .animate(
                                        onPlay: (c) => c.repeat(reverse: true),
                                      )
                                      .scale(
                                        begin: const Offset(0.8, 0.8),
                                        end: const Offset(1.5, 1.5),
                                      ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_driverInfo?['name'] ?? 'Driver'} • ${_currentSpeedKmH.toStringAsFixed(0)} km/h',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Pulsing Driver Motorcycle Icon
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: GlassTheme.primaryGreen
                                            .withValues(alpha: 0.3),
                                      ),
                                    )
                                    .animate(onPlay: (c) => c.repeat())
                                    .scale(
                                      begin: const Offset(0.9, 0.9),
                                      end: const Offset(1.5, 1.5),
                                      duration: 1200.ms,
                                    )
                                    .fadeOut(duration: 1200.ms),

                                Transform.rotate(
                                  angle: _driverBearing * (math.pi / 180.0),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: GlassTheme.primaryGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: GlassTheme.primaryGreen
                                              .withValues(alpha: 0.6),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.two_wheeler,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                          boxShadow: const [
                            BoxShadow(color: Colors.blueAccent, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),

                  // 5. Explore Mode: Nearby Restaurant Pins
                  if (!_isTrackingMode)
                    ..._nearbyRestaurants.map((res) {
                      final lat =
                          double.tryParse(res['lat']?.toString() ?? '') ??
                          11.5564;
                      final lng =
                          double.tryParse(res['lng']?.toString() ?? '') ??
                          104.9282;
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),

          // ── Map Attribution ───────────────────────
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.public,
                    size: 12,
                    color: GlassTheme.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    MapConfig.getLayerName(_selectedLayer),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Top Navigation Bar (TikTok Tracking Mode Floating Pill & Buttons) ──
          if (_isTrackingMode) _buildTrackingTopBar(context),

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
                    final target =
                        _driverLocation ??
                        _restaurantLocation ??
                        _customerLocation;
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

          // ── Draggable Bottom Sheet (TikTok Reference Live Order Tracking Sheet) ──
          if (_isTrackingMode)
            _buildDraggableTrackingSheet(context, distanceKm, etaMinutes),

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
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: GlassTheme.primaryGreen,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRestaurant!['name'] ?? 'Restaurant',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedRestaurant!['address'] ?? 'Phnom Penh'} • Rating ${_selectedRestaurant!['rating'] ?? '4.8'}',
                                style: TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () =>
                              setState(() => _selectedRestaurant = null),
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
                child: CircularProgressIndicator(
                  color: GlassTheme.primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Top Floating Navigation Bar (TikTok Reference Mode)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTrackingTopBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final orderNum = widget.orderId.isNotEmpty && widget.orderId != '0'
        ? widget.orderId
        : '1904';

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Back Button
          InkWell(
            onTap: () => context.go('/home'),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 22,
              ),
            ),
          ),

          // Order # Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Order #$orderNum',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),

          // Circular Target / Recenter Button
          InkWell(
            onTap: () {
              final target =
                  _driverLocation ?? _restaurantLocation ?? _customerLocation;
              if (target != null) _animatedMapMove(target, 15.0);
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.near_me,
                color: GlassTheme.primaryGreen,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Draggable Bottom Sheet (TikTok Reference Live Tracking Layout)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDraggableTrackingSheet(
    BuildContext context,
    double? distanceKm,
    int? etaMinutes,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final driver =
        _driverInfo ??
        {
          'name': 'Ahmad Faizal',
          'rating': 4.9,
          'trips': 2384,
          'vehicle_type': 'Honda EX5 • Red',
          'license_plate': 'WXY 4821',
          'phone': '+855 12 888 999',
          'avatar':
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=160&q=80',
        };

    final etaMin = etaMinutes ?? 15;
    final distance = distanceKm != null ? distanceKm.toStringAsFixed(1) : '3.4';

    String headline = 'Preparing your food';
    String subtitle = "${_restaurantName ?? "McDonald's"} is cooking it fresh";
    if (_orderStatus == 'delivered') {
      headline = 'Order Delivered!';
      subtitle = 'Enjoy your delicious meal!';
    } else if (_orderStatus == 'on_the_way' || _orderStatus == 'on_delivery') {
      headline = 'On the way to you';
      subtitle = '${driver['name']} is $distance km away';
    } else if (_orderStatus == 'picked_up') {
      headline = 'Rider Picked Up';
      subtitle = '${driver['name']} picked up your order';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.44,
      minChildSize: 0.28,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFD6D6D6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Status Row: Live Dot + Headline + Subtitle | ETA Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: GlassTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.3, 1.3),
                                ),
                            const SizedBox(width: 6),
                            const Text(
                              'Live • 0:16',
                              style: TextStyle(
                                color: GlassTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          headline,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: GlassTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ETA Card Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? GlassTheme.primaryGreen.withValues(alpha: 0.2)
                          : const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? GlassTheme.primaryGreen.withValues(alpha: 0.4)
                            : const Color(0xFFC8E6C9),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$etaMin min',
                          style: const TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Arriving 11:15 PM',
                          style: TextStyle(
                            fontSize: 10,
                            color: GlassTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 5-Stage Stepper: Confirmed -> Preparing -> Picked up -> On the way -> Delivered
              _buildFiveStepProgress(),
              const SizedBox(height: 20),

              // Courier / Driver Contact Card
              _buildDriverCard(context, driver, isDark),
              const SizedBox(height: 20),

              // Order Status Timeline
              _buildOrderTimeline(isDark),
              const SizedBox(height: 18),

              // Route Summary Card
              _buildRouteSummaryCard(isDark, distance),
              const SizedBox(height: 18),

              // Your Order Itemized Dishes
              _buildItemizedOrderSection(isDark),
              const SizedBox(height: 24),

              // Action Buttons: Show Delivery Confirmation QR / Scan Driver QR
              ElevatedButton.icon(
                onPressed: () => DeliveryQrModal.show(
                  context,
                  orderId: widget.orderId.toString(),
                  isDriver: false,
                  onDelivered: () => _fetchOrderTrackingData(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.qr_code_2, size: 22),
                label: const Text(
                  'Show Delivery Confirmation QR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: () => DeliveryScannerModal.show(
                  context,
                  orderId: widget.orderId.toString(),
                  isDriver: false,
                  onConfirmed: () => _fetchOrderTrackingData(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  side: BorderSide(
                    color: GlassTheme.primaryGreen.withValues(alpha: 0.6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text(
                  'Scan Driver Handover QR',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  side: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFDDDDDD),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text(
                  'Back to Home',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5-Step Visual Stepper (TikTok Reference Style)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFiveStepProgress() {
    final steps = [
      'Confirmed',
      'Preparing',
      'Picked up',
      'On the way',
      'Delivered',
    ];
    int currentStep = 1; // Default to 'Preparing' (matches reference video)
    if (_orderStatus == 'delivered') {
      currentStep = 4;
    } else if (_orderStatus == 'on_the_way' || _orderStatus == 'on_delivery') {
      currentStep = 3;
    } else if (_orderStatus == 'picked_up') {
      currentStep = 2;
    } else if (_orderStatus == 'preparing') {
      currentStep = 1;
    } else {
      currentStep = 0;
    }

    return Column(
      children: [
        Row(
          children: List.generate(steps.length, (index) {
            final isCompletedOrCurrent = index <= currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index < steps.length - 1 ? 5 : 0,
                ),
                height: 4,
                decoration: BoxDecoration(
                  color: isCompletedOrCurrent
                      ? GlassTheme.royalSmalt
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isPassed = index <= currentStep;
            return Text(
              steps[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isPassed ? FontWeight.bold : FontWeight.w500,
                color: isPassed ? GlassTheme.royalSmalt : GlassTheme.textMuted,
              ),
            );
          }),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Driver Contact Card
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDriverCard(
    BuildContext context,
    Map<String, dynamic> driver,
    bool isDark,
  ) {
    final phone = driver['phone']?.toString() ?? '+855 12 888 999';
    final name = driver['name']?.toString() ?? 'Ahmad Faizal';
    final rating = driver['rating']?.toString() ?? '4.9';
    final trips = driver['trips']?.toString() ?? '2384';
    final vehicle = driver['vehicle_type']?.toString() ?? 'Honda EX5 • Red';
    final plate = driver['license_plate']?.toString() ?? 'WXY 4821';
    final avatar =
        driver['avatar']?.toString() ??
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=160&q=80';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? GlassTheme.surfaceCardDark : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: CachedNetworkImage(
                  imageUrl: avatar,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFB300),
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$rating • $trips trips',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: GlassTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chat Button (Light Green Container)
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat with driver $name opened.'),
                      backgroundColor: GlassTheme.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: GlassTheme.primaryGreen,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Call Button (Vibrant Green Container)
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Calling driver at $phone (copied to clipboard)',
                      ),
                      backgroundColor: GlassTheme.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: GlassTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vehicle & License Plate Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.two_wheeler,
                        size: 16,
                        color: GlassTheme.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          vehicle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF444444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF263238),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Order Status Milestone Timeline
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildOrderTimeline(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order status',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        _buildTimelineTile(
          'Order confirmed',
          '10:55 PM',
          isDone: true,
          isLast: false,
          isDark: isDark,
        ),
        _buildTimelineTile(
          'Preparing your food',
          '10:55 PM',
          isDone: true,
          isLast: false,
          isDark: isDark,
        ),
        _buildTimelineTile(
          'Rider picked up',
          '0:01',
          isDone: _orderStatus == 'on_the_way' || _orderStatus == 'delivered',
          isLast: false,
          isDark: isDark,
        ),
        _buildTimelineTile(
          'On the way',
          '',
          isDone: _orderStatus == 'on_the_way' || _orderStatus == 'delivered',
          isLast: false,
          isDark: isDark,
        ),
        _buildTimelineTile(
          'Delivered',
          '',
          isDone: _orderStatus == 'delivered',
          isLast: true,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTimelineTile(
    String title,
    String time, {
    required bool isDone,
    required bool isLast,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isDone ? GlassTheme.primaryGreen : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isDone ? GlassTheme.primaryGreen : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
              color: isDone
                  ? (isDark ? Colors.white : const Color(0xFF222222))
                  : GlassTheme.textMuted,
            ),
          ),
        ),
        if (time.isNotEmpty)
          time.startsWith('0:')
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? GlassTheme.deepSmalt.withValues(alpha: 0.45)
                        : GlassTheme.paleSmalt.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? GlassTheme.paleSmalt
                          : GlassTheme.royalSmalt,
                    ),
                  ),
                )
              : Text(
                  time,
                  style: TextStyle(fontSize: 11, color: GlassTheme.textMuted),
                ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Route Summary Card: Origin -> Destination with Dotted Line & Distance Pill
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRouteSummaryCard(bool isDark, String distance) {
    final fromName = _restaurantName ?? "McDonald's - Bukit Bintang";
    final toName = _deliveryAddress ?? "Home • 12 Jalan Ampang, Kuala Lumpur";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? GlassTheme.surfaceCardDark : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC72C),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Color(0xFFDA291C),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From',
                      style: TextStyle(
                        fontSize: 10,
                        color: GlassTheme.textMuted,
                      ),
                    ),
                    Text(
                      fromName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFE53935), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To',
                      style: TextStyle(
                        fontSize: 10,
                        color: GlassTheme.textMuted,
                      ),
                    ),
                    Text(
                      toName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.route,
                  size: 14,
                  color: GlassTheme.primaryGreen,
                ),
                const SizedBox(width: 5),
                Text(
                  '$distance km • 6 min ride',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: GlassTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Itemized Order Section ("Your order")
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildItemizedOrderSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your order',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        _buildReceiptItem(
          '2x',
          'Big Mac',
          '\$10.98',
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&q=80',
          isDark,
        ),
        const SizedBox(height: 8),
        _buildReceiptItem(
          '1x',
          'French Fries',
          '\$2.90',
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=200&q=80',
          isDark,
        ),
        const SizedBox(height: 8),
        _buildReceiptItem(
          '1x',
          'McFlurry Oreo',
          '\$3.00',
          'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=200&q=80',
          isDark,
        ),
      ],
    );
  }

  Widget _buildReceiptItem(
    String qty,
    String name,
    String price,
    String imageUrl,
    bool isDark,
  ) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 38,
            height: 38,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          qty,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: GlassTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Text(
          price,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  void _showMarkerInfo(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.badgeTagDark,
        shape: RoundedRectangleBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          description,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: GlassTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
