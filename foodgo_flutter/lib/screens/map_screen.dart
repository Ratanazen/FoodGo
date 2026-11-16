import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
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
  final bool isDriver;
  final bool? initialLoading;
  final String? initialStatus;
  const MapScreen({
    super.key,
    required this.orderId,
    this.isDriver = false,
    this.initialLoading,
    this.initialStatus,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _cameraController;
  WebSocketChannel? _channel;

  MapLayerType _selectedLayer = MapLayerType.openStreetMap;
  late bool _isLoading = widget.initialLoading ?? true;
  late String _orderStatus = widget.initialStatus ?? 'pending';
  String? _deliveryStatus;
  String? _restaurantName;
  String? _deliveryAddress;

  LatLng? _restaurantLocation;
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  LatLng? _myLocation;

  Map<String, dynamic>? _driverInfo;
  Map<String, dynamic>? _customerInfo;
  Timer? _liveMovementTimer;
  Timer? _pollingTimer;
  double _routeProgress = 0.45;
  double _currentSpeedKmH = 34.0;
  double _driverBearing = 0.0;
  bool _isPickedUp = false;
  bool _driverAssigned = true;
  String _trackingStage = 'en_route_to_restaurant';
  bool _autoFollowDriver = true;
  bool _autoTrackingActive = false;
  bool _orderNotFoundOnServer = false;
  int? _backendEtaMinutes;
  String? _confirmedAtIso;
  String? _pickedUpAtIso;
  String? _deliveredAtIso;
  DateTime? _lastLiveLocationAt;

  // Nearby restaurants list when in explore mode (orderId is empty)
  List<Map<String, dynamic>> _nearbyRestaurants = [];
  Map<String, dynamic>? _selectedRestaurant;

  bool _statusImpliesPickedUp(String status, {String? deliveryStatus}) {
    const pickedOrder = {
      'picked_up',
      'on_the_way',
      'out_for_delivery',
      'on_delivery',
      'driver_arrived',
      'arrived',
      'delivered',
    };
    const pickedDelivery = {
      'picked_up',
      'on_the_way',
      'out_for_delivery',
      'arrived',
      'delivered',
    };
    return pickedOrder.contains(status) ||
        (deliveryStatus != null && pickedDelivery.contains(deliveryStatus));
  }

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _isPickedUp = _statusImpliesPickedUp(_orderStatus);
    if (_isPickedUp) {
      _trackingStage = _orderStatus == 'delivered' ? 'delivered' : 'on_the_way';
    } else if (_orderStatus == 'arrived_at_restaurant') {
      _trackingStage = 'at_restaurant';
    }

    if (widget.initialLoading != false) {
      if (widget.orderId.isNotEmpty && widget.orderId != '0') {
        _fetchOrderTrackingData();
        _connectWebSocket();
        _startRestPollingFallback();
        _startLiveDriverMovementSimulation();
      } else {
        _fetchNearbyRestaurants();
        _autoInitLocation();
      }
    } else {
      _driverAssigned = true;
      _restaurantLocation ??= const LatLng(11.5564, 104.9282);
      _customerLocation ??= const LatLng(11.5621, 104.9160);
      _driverLocation ??= _isPickedUp
          ? const LatLng(11.5590, 104.9220)
          : const LatLng(11.5546, 104.9268);
      _currentSpeedKmH = _isPickedUp ? 34.0 : 0.0;
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
      _customerInfo ??= {
        'name': 'Somnang Cust',
        'phone': '+855 12 111 222',
        'address': 'Street 271, Boeng Tumpun',
        'special_instructions': 'Gate code 4321',
      };
    }
  }

  void _startRestPollingFallback() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_orderStatus == 'delivered' ||
          _orderStatus == 'cancelled' ||
          _orderStatus == 'failed_delivery') {
        timer.cancel();
        return;
      }
      _fetchOrderTrackingData(silent: true);
    });
  }

  void _startLiveDriverMovementSimulation() {
    _liveMovementTimer?.cancel();
    _liveMovementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted ||
          _restaurantLocation == null ||
          _customerLocation == null) {
        return;
      }
      if (_orderStatus == 'delivered' ||
          _orderStatus == 'cancelled' ||
          _orderStatus == 'failed_delivery') {
        if (_currentSpeedKmH != 0) {
          setState(() => _currentSpeedKmH = 0);
        }
        timer.cancel();
        return;
      }

      // Preserve genuine WebSocket / DB telemetry when recently received
      if (_lastLiveLocationAt != null &&
          DateTime.now().difference(_lastLiveLocationAt!).inSeconds < 12) {
        return;
      }

      // CRITICAL: Before food pickup, keep rider anchored/heading to restaurant,
      // never advancing along the customer delivery route.
      if (!_isPickedUp) {
        if (!_driverAssigned) {
          return;
        }
        final atRestaurant =
            _trackingStage == 'at_restaurant' ||
            _deliveryStatus == 'arrived_at_restaurant';
        final targetAtRest = atRestaurant
            ? _restaurantLocation!
            : LatLng(
                _restaurantLocation!.latitude - 0.0015,
                _restaurantLocation!.longitude - 0.0012,
              );
        setState(() {
          _driverLocation ??= targetAtRest;
          _currentSpeedKmH = atRestaurant ? 0.0 : 18.0;
        });
        return;
      }

      if (_trackingStage == 'arrived' ||
          _orderStatus == 'arrived' ||
          _orderStatus == 'driver_arrived' ||
          _deliveryStatus == 'arrived') {
        setState(() {
          _driverLocation = _customerLocation;
          _currentSpeedKmH = 0.0;
        });
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
    _pollingTimer?.cancel();
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
                _driverAssigned = true;
                _autoTrackingActive = true;
                _lastLiveLocationAt = DateTime.now();
                _driverLocation = LatLng(newLat, newLng);
                _driverBearing = bearing;
                _currentSpeedKmH = speed;
                if (data['is_picked_up'] is bool) {
                  _isPickedUp = data['is_picked_up'] as bool;
                }
                if (data['tracking_stage'] != null) {
                  _trackingStage = data['tracking_stage'].toString();
                }
              });
              if (_autoFollowDriver && _driverLocation != null) {
                _animatedMapMove(_driverLocation!, 15.2);
              }
            }
          } catch (_) {}
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
        },
      );
    } catch (_) {}
  }

  Future<void> _fetchOrderTrackingData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await ApiService().get('orders/${widget.orderId}/track/');
      if (!mounted) return;

      final fetchedStatus = (data['status'] ?? 'pending').toString();
      final fetchedDeliveryStatus = data['delivery_status']?.toString();
      final hasDriver = data['driver_assigned'] is bool
          ? data['driver_assigned'] as bool
          : (data['driver'] != null);
      final picked = data['is_picked_up'] is bool
          ? data['is_picked_up'] as bool
          : _statusImpliesPickedUp(
              fetchedStatus,
              deliveryStatus: fetchedDeliveryStatus,
            );

      setState(() {
        _orderNotFoundOnServer = false;
        _orderStatus = fetchedStatus;
        _deliveryStatus = fetchedDeliveryStatus;
        _driverAssigned = hasDriver;
        _isPickedUp = picked;
        _trackingStage =
            data['tracking_stage']?.toString() ??
            (picked
                ? (fetchedStatus == 'delivered' ? 'delivered' : 'on_the_way')
                : (hasDriver ? 'en_route_to_restaurant' : 'awaiting_driver'));
        _autoTrackingActive = data['auto_tracking'] == true;
        _backendEtaMinutes = data['eta_minutes'] is int
            ? data['eta_minutes'] as int
            : int.tryParse(data['eta_minutes']?.toString() ?? '');
        _confirmedAtIso = data['confirmed_at']?.toString();
        _pickedUpAtIso = data['picked_up_at']?.toString();
        _deliveredAtIso = data['delivered_at']?.toString();
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
          if (data['last_location_update'] != null) {
            _lastLiveLocationAt = DateTime.now();
          }
        } else if (!hasDriver) {
          _driverLocation = null;
        }
        if (data['driver'] != null && data['driver'] is Map) {
          _driverInfo = Map<String, dynamic>.from(data['driver']);
        } else if (!hasDriver) {
          _driverInfo = null;
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

        if (data['customer'] != null && data['customer'] is Map) {
          _customerInfo = Map<String, dynamic>.from(data['customer']);
        } else {
          _customerInfo ??= {
            'name': 'Customer',
            'phone': '+855 12 345 678',
            'address': _deliveryAddress ?? 'Phnom Penh, Cambodia',
            'special_instructions': '',
          };
        }

        _isLoading = false;
      });

      if (!silent) {
        final focusTarget =
            _driverLocation ?? _restaurantLocation ?? _customerLocation;
        if (focusTarget != null) {
          _animatedMapMove(focusTarget, 14.8);
        }
      } else if (_autoFollowDriver && _driverLocation != null) {
        _animatedMapMove(_driverLocation!, 15.0);
      }
    } catch (e) {
      if (mounted && !silent) {
        final isNotFound = e is DioException && e.response?.statusCode == 404;
        setState(() {
          _isLoading = false;
          _orderNotFoundOnServer = isNotFound;
          // Graceful fallback coordinates
          _restaurantLocation = const LatLng(11.5564, 104.9282);
          _customerLocation = const LatLng(11.5621, 104.9160);
          _driverLocation = _driverAssigned
              ? (_isPickedUp
                    ? const LatLng(11.5590, 104.9220)
                    : const LatLng(11.5546, 104.9268))
              : null;
          _currentSpeedKmH = _isPickedUp ? 34.0 : 0.0;
          _customerInfo ??= {
            'name': 'Customer',
            'phone': '+855 12 345 678',
            'address': 'Phnom Penh, Cambodia',
            'special_instructions': '',
          };
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(context).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final accentGreen = isDark
            ? GlassTheme.primaryGreenAccent
            : const Color(0xFF15803D);
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
                  Text(
                    'Select Map Layer',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'OpenMap Engine',
                      style: textTheme.labelSmall?.copyWith(
                        color: accentGreen,
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
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
                ? accentGreen.withValues(alpha: 0.16)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03)),
            border: Border.all(
              color: isSelected
                  ? accentGreen
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black12),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? accentGreen : secondaryText),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? accentGreen : primaryText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: accentGreen, size: 20),
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

              // Polyline connecting pickup/delivery route accurately
              if (_isTrackingMode) ...[
                if (_restaurantLocation != null && _customerLocation != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_restaurantLocation!, _customerLocation!],
                        color: GlassTheme.primaryGreen.withValues(
                          alpha: _isPickedUp ? 0.35 : 0.22,
                        ),
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                if (!_isPickedUp &&
                    _driverLocation != null &&
                    _restaurantLocation != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_driverLocation!, _restaurantLocation!],
                        color: Colors.orangeAccent,
                        strokeWidth: 4.5,
                      ),
                    ],
                  ),
                if (_isPickedUp &&
                    _driverLocation != null &&
                    _customerLocation != null)
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

                  // 3. Driver Live Marker with pre-pickup vs in-transit status pill
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 210,
                      height: 82,
                      child: GestureDetector(
                        onTap: () {
                          final riderName =
                              _driverInfo?['name'] ?? 'Delivery Driver';
                          final vehicle =
                              _driverInfo?['vehicle_type'] ?? 'Motorcycle';
                          final infoMsg = !_isPickedUp
                              ? '$vehicle • Heading to restaurant to pick up order (not picked up yet)'
                              : '$vehicle • Speed: ${_currentSpeedKmH.toStringAsFixed(0)} km/h • On the way to your doorstep!';
                          _showMarkerInfo(riderName.toString(), infoMsg);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Floating Driver Name & Status/Speed Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isPickedUp
                                      ? GlassTheme.primaryGreen
                                      : Colors.orangeAccent,
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
                                        decoration: BoxDecoration(
                                          color: _isPickedUp
                                              ? GlassTheme.primaryGreen
                                              : Colors.orangeAccent,
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
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        !_isPickedUp
                                            ? ((_trackingStage ==
                                                          'at_restaurant' ||
                                                      _deliveryStatus ==
                                                          'arrived_at_restaurant')
                                                  ? '${_driverInfo?['name'] ?? 'Driver'} • At Restaurant'
                                                  : '${_driverInfo?['name'] ?? 'Driver'} • To Pickup')
                                            : '${_driverInfo?['name'] ?? 'Driver'} • ${_currentSpeedKmH.toStringAsFixed(0)} km/h',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
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
                                        color:
                                            (_isPickedUp
                                                    ? GlassTheme.primaryGreen
                                                    : Colors.orangeAccent)
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
                                      color: _isPickedUp
                                          ? GlassTheme.primaryGreen
                                          : Colors.orangeAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (_isPickedUp
                                                      ? GlassTheme.primaryGreen
                                                      : Colors.orangeAccent)
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
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

                if (_isTrackingMode) ...[
                  // Auto-Follow Live Driver Camera Toggle
                  FloatingActionButton.small(
                    heroTag: 'auto_follow_btn',
                    backgroundColor: _autoFollowDriver
                        ? GlassTheme.primaryGreen
                        : Colors.black87,
                    foregroundColor: Colors.white,
                    tooltip: _autoFollowDriver
                        ? 'Auto-Follow Driver: ON'
                        : 'Auto-Follow Driver: OFF',
                    onPressed: () {
                      setState(() => _autoFollowDriver = !_autoFollowDriver);
                      if (_autoFollowDriver && _driverLocation != null) {
                        _animatedMapMove(_driverLocation!, 15.2);
                      }
                    },
                    child: Icon(
                      _autoFollowDriver ? Icons.gps_fixed : Icons.gps_off,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Re-center on Driver / Target
                FloatingActionButton.small(
                  heroTag: 'target_btn',
                  backgroundColor: GlassTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    setState(() => _autoFollowDriver = true);
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
                          child: Builder(
                            builder: (context) {
                              final brightness = Theme.of(context).brightness;
                              final textTheme = Theme.of(context).textTheme;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedRestaurant!['name'] ??
                                        'Restaurant',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTypography.primaryTextColor(
                                        brightness,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_selectedRestaurant!['address'] ?? 'Phnom Penh'} • Rating ${_selectedRestaurant!['rating'] ?? '4.8'}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppTypography.secondaryTextColor(
                                        brightness,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: AppTypography.secondaryTextColor(
                              Theme.of(context).brightness,
                            ),
                          ),
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
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else if (widget.isDriver) {
                context.go('/driver-dashboard');
              } else {
                context.go('/home');
              }
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
                Icons.arrow_back,
                color: Colors.black87,
                size: 22,
              ),
            ),
          ),

          // Order # Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isDriver) ...[
                  const Icon(
                    Icons.delivery_dining,
                    size: 18,
                    color: GlassTheme.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.isDriver ? 'Delivery #$orderNum' : 'Order #$orderNum',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
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

    final etaMin = _backendEtaMinutes ?? etaMinutes ?? (_isPickedUp ? 12 : 22);
    final distance = distanceKm != null ? distanceKm.toStringAsFixed(1) : '3.4';

    String headline = 'Preparing your food';
    String subtitle = "${_restaurantName ?? "McDonald's"} is cooking it fresh";
    if (widget.isDriver) {
      final custName = _customerInfo?['name'] ?? 'Customer';
      if (_orderStatus == 'delivered') {
        headline = 'Delivered to $custName';
        subtitle = 'Delivery completed successfully';
      } else if (_orderStatus == 'arrived' ||
          _orderStatus == 'driver_arrived') {
        headline = 'Arrived at $custName';
        subtitle = 'Ready for QR handover at drop-off';
      } else if (_orderStatus == 'on_the_way' ||
          _orderStatus == 'on_delivery' ||
          _orderStatus == 'out_for_delivery') {
        headline = 'Delivering to $custName';
        subtitle = 'Drop-off is $distance km away • $etaMin min';
      } else if (_isPickedUp) {
        headline = 'Order Picked Up';
        subtitle = 'Auto-tracking en route to $custName';
      } else if (_trackingStage == 'at_restaurant' ||
          _deliveryStatus == 'arrived_at_restaurant') {
        headline = 'At ${_restaurantName ?? "Restaurant"}';
        subtitle = 'Waiting for food handover (not picked up yet)';
      } else {
        headline = 'Pickup at ${_restaurantName ?? "Restaurant"}';
        subtitle = 'Heading to restaurant • Not picked up yet';
      }
    } else {
      if (_orderStatus == 'delivered') {
        headline = 'Order Delivered!';
        subtitle = 'Enjoy your delicious meal!';
      } else if (_orderStatus == 'arrived' ||
          _orderStatus == 'driver_arrived') {
        headline = 'Driver Has Arrived';
        subtitle = '${driver['name']} is waiting at your drop-off';
      } else if (_orderStatus == 'on_the_way' ||
          _orderStatus == 'on_delivery' ||
          _orderStatus == 'out_for_delivery') {
        headline = 'On the way to you';
        subtitle = '${driver['name']} is $distance km away';
      } else if (_isPickedUp) {
        headline = 'Rider Picked Up';
        subtitle = '${driver['name']} picked up your order';
      } else if (!_driverAssigned) {
        headline = 'Finding a Driver';
        subtitle = 'Auto-assigning nearest courier for pickup';
      } else if (_trackingStage == 'at_restaurant' ||
          _deliveryStatus == 'arrived_at_restaurant') {
        headline = 'Rider at Restaurant';
        subtitle =
            '${driver['name']} is waiting for pickup (not picked up yet)';
      } else {
        headline = 'Heading to Pickup';
        subtitle =
            '${driver['name']} is going to the restaurant (not picked up yet)';
      }
    }

    final liveBadgeLabel = _orderStatus == 'delivered'
        ? 'Completed'
        : (!_driverAssigned
              ? 'Auto-Assigning Rider'
              : (!_isPickedUp
                    ? 'Pre-Pickup • Auto-Tracking'
                    : (_autoTrackingActive
                          ? 'Auto-Tracking Live'
                          : 'Live Delivery')));
    final etaSubLabel = _orderStatus == 'delivered'
        ? 'Completed'
        : (_isPickedUp ? 'En route' : 'Pickup + Trip');

    return DraggableScrollableSheet(
      initialChildSize: 0.44,
      minChildSize: 0.28,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.dynamicSurfaceDark : Colors.white,
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
                                  decoration: BoxDecoration(
                                    color: _isPickedUp
                                        ? accentGreen
                                        : Colors.orangeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.3, 1.3),
                                ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                liveBadgeLabel,
                                style: textTheme.bodySmall?.copyWith(
                                  color: _isPickedUp
                                      ? accentGreen
                                      : (isDark
                                            ? Colors.orangeAccent
                                            : const Color(0xFFB45309)),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          headline,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: secondaryText,
                          ),
                        ),
                        if (_orderNotFoundOnServer) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'Order #${widget.orderId} is not found on the active server (preview map only).',
                              style: textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? Colors.amberAccent
                                    : const Color(0xFF92400E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
                          style: textTheme.titleLarge?.copyWith(
                            color: accentGreen,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          etaSubLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: secondaryText,
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

              // Courier / Driver Contact Card OR Waiting Card OR Customer Card (for Driver View)
              if (widget.isDriver)
                _buildCustomerCard(context, _customerInfo ?? {}, isDark)
              else if (!_driverAssigned)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? GlassTheme.dynamicSurfaceCardDark
                        : const Color(0xFFF9FBF9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? GlassTheme.dynamicBorderDark
                          : const Color(0xFFEEEEEE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.two_wheeler,
                          color: isDark
                              ? Colors.orangeAccent
                              : const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto-Dispatching Nearby Driver',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Live GPS map tracking starts automatically as soon as your rider is assigned.',
                              style: textTheme.bodySmall?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
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

              // Action Buttons: Mode-Specific Handover & Back Navigation
              if (widget.isDriver) ...[
                ElevatedButton.icon(
                  onPressed: () => DeliveryScannerModal.show(
                    context,
                    orderId: widget.orderId.toString(),
                    isDriver: true,
                    onConfirmed: () => _fetchOrderTrackingData(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? GlassTheme.primaryGreen
                        : const Color(0xFF15803D),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 22),
                  label: Text(
                    'Complete Delivery (Scan Drop-off QR)',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => DeliveryQrModal.show(
                    context,
                    orderId: widget.orderId.toString(),
                    isDriver: true,
                    onDelivered: () => _fetchOrderTrackingData(),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryText,
                    side: BorderSide(color: accentGreen.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: Text(
                    'Show Courier Handover QR',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/driver-dashboard');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryText,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFDDDDDD),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.delivery_dining, size: 18),
                  label: Text(
                    'Back to Driver Dashboard',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => DeliveryQrModal.show(
                    context,
                    orderId: widget.orderId.toString(),
                    isDriver: false,
                    onDelivered: () => _fetchOrderTrackingData(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? GlassTheme.primaryGreen
                        : const Color(0xFF15803D),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.qr_code_2, size: 22),
                  label: Text(
                    'Show Delivery Confirmation QR',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
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
                    foregroundColor: primaryText,
                    side: BorderSide(color: accentGreen.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text(
                    'Scan Driver Handover QR',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryText,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFDDDDDD),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: Text(
                    'Back to Home',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                ),
              ],
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final stepAccent = isDark
        ? Theme.of(context).colorScheme.primary
        : GlassTheme.dynamicPrimaryDark;
    final steps = [
      'Confirmed',
      'Preparing',
      'Picked up',
      'On the way',
      'Delivered',
    ];
    int currentStep = 0;
    if (_orderStatus == 'delivered') {
      currentStep = 4;
    } else if (_orderStatus == 'on_the_way' ||
        _orderStatus == 'on_delivery' ||
        _orderStatus == 'out_for_delivery' ||
        _orderStatus == 'driver_arrived' ||
        _orderStatus == 'arrived') {
      currentStep = 3;
    } else if (_isPickedUp) {
      currentStep = 2;
    } else if (_orderStatus == 'preparing' ||
        _orderStatus == 'ready' ||
        _orderStatus == 'ready_for_pickup' ||
        _orderStatus == 'arrived_at_restaurant') {
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
                      ? stepAccent
                      : (isDark ? Colors.white24 : const Color(0xFFE0E0E0)),
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
            return Expanded(
              child: Text(
                steps[index],
                textAlign: index == 0
                    ? TextAlign.start
                    : (index == steps.length - 1
                          ? TextAlign.end
                          : TextAlign.center),
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: isPassed ? FontWeight.bold : FontWeight.w500,
                  color: isPassed ? stepAccent : secondaryText,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Customer Contact & Drop-off Card (Driver View)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCustomerCard(
    BuildContext context,
    Map<String, dynamic> customer,
    bool isDark,
  ) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final dangerColor = isDark ? Colors.redAccent : const Color(0xFFB91C1C);
    final infoBlue = isDark ? Colors.lightBlueAccent : const Color(0xFF1D4ED8);
    final warningAmber = isDark ? Colors.amber : const Color(0xFFB45309);
    final phone = customer['phone']?.toString() ?? '+855 12 345 678';
    final name = customer['name']?.toString() ?? 'Customer';
    final address =
        customer['address']?.toString() ??
        (_deliveryAddress ?? 'Customer Dropoff Location');
    final instructions = customer['special_instructions']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? GlassTheme.dynamicSurfaceCardDark
            : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? GlassTheme.dynamicBorderDark
              : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: dangerColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: dangerColor, width: 1.5),
                ),
                child: Icon(Icons.person, color: dangerColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: infoBlue.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Recipient',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: infoBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // Message / Chat Button
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat with customer $name opened.'),
                      backgroundColor: GlassTheme.primaryGreenDark,
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
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: accentGreen,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Call Button
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Calling customer at $phone (copied to clipboard)',
                      ),
                      backgroundColor: GlassTheme.primaryGreenDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF15803D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dropoff Address Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: dangerColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: warningAmber.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: warningAmber.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: warningAmber, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Note: $instructions',
                      style: textTheme.labelSmall?.copyWith(
                        color: warningAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final starAmber = isDark
        ? const Color(0xFFFFB300)
        : const Color(0xFFB45309);
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
        color: isDark
            ? GlassTheme.dynamicSurfaceCardDark
            : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? GlassTheme.dynamicBorderDark
              : const Color(0xFFEEEEEE),
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
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star, color: starAmber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '$rating • $trips trips',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
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
                      backgroundColor: GlassTheme.primaryGreenDark,
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
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: accentGreen,
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
                      backgroundColor: GlassTheme.primaryGreenDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF15803D),
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
                      Icon(Icons.two_wheeler, size: 16, color: accentGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          vehicle,
                          style: textTheme.bodySmall?.copyWith(
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
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
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
  String _formatShortTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildOrderTimeline(bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final isPreparingOrLater =
        _isPickedUp ||
        const {
          'confirmed',
          'driver_assigned',
          'driver_accepted',
          'preparing',
          'ready',
          'ready_for_pickup',
          'arrived_at_restaurant',
        }.contains(_orderStatus);
    final isOnTheWayOrDelivered =
        _isPickedUp &&
        (_orderStatus == 'on_the_way' ||
            _orderStatus == 'on_delivery' ||
            _orderStatus == 'out_for_delivery' ||
            _orderStatus == 'driver_arrived' ||
            _orderStatus == 'arrived' ||
            _orderStatus == 'delivered');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order status',
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 10),
        _buildTimelineTile(
          'Order confirmed',
          _formatShortTime(_confirmedAtIso),
          isDone: _orderStatus != 'pending' && _orderStatus != 'cancelled',
          isLast: false,
          isDark: isDark,
        ),
        _buildTimelineTile(
          'Preparing your food',
          '',
          isDone: isPreparingOrLater,
          isLast: false,
          isDark: isDark,
        ),
        _buildTimelineTile(
          'Rider picked up',
          _isPickedUp
              ? _formatShortTime(_pickedUpAtIso)
              : (_driverAssigned ? 'Not picked up yet' : 'Finding rider'),
          isDone: _isPickedUp,
          isLast: false,
          isDark: isDark,
        ),
        _buildTimelineTile(
          'On the way',
          '',
          isDone: isOnTheWayOrDelivered,
          isLast: false,
          isDark: isDark,
        ),
        _buildTimelineTile(
          'Delivered',
          _formatShortTime(_deliveredAtIso),
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
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isDone
                    ? accentGreen
                    : (isDark ? Colors.white24 : Colors.grey.shade400),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isDone
                    ? accentGreen
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
              color: isDone ? primaryText : secondaryText,
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
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Theme.of(context).colorScheme.primary
                          : GlassTheme.dynamicPrimaryDark,
                    ),
                  ),
                )
              : Text(
                  time,
                  style: textTheme.labelSmall?.copyWith(color: secondaryText),
                ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Route Summary Card: Origin -> Destination with Dotted Line & Distance Pill
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRouteSummaryCard(bool isDark, String distance) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final fromName = _restaurantName ?? "McDonald's - Bukit Bintang";
    final toName = _deliveryAddress ?? "Home • 12 Jalan Ampang, Kuala Lumpur";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? GlassTheme.dynamicSurfaceCardDark
            : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? GlassTheme.dynamicBorderDark
              : const Color(0xFFEEEEEE),
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
                child: Center(
                  child: Text(
                    'M',
                    style: textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFDA291C),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: textTheme.labelSmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                    Text(
                      fromName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryText,
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
                    Text(
                      'To',
                      style: textTheme.labelSmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                    Text(
                      toName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryText,
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
                Icon(Icons.route, size: 14, color: accentGreen),
                const SizedBox(width: 5),
                Text(
                  '$distance km • 6 min ride',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentGreen,
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
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your order',
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: primaryText,
          ),
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
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
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
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: accentGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
        ),
        Text(
          price,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
      ],
    );
  }

  void _showMarkerInfo(String title, String description) {
    showDialog(
      context: context,
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(context).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);
        final accentGreen = isDark
            ? GlassTheme.primaryGreenAccent
            : const Color(0xFF15803D);
        return AlertDialog(
          backgroundColor: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: GlassTheme.borderRadiusSmall,
            side: BorderSide(
              color: isDark
                  ? GlassTheme.dynamicBorderDark
                  : const Color(0xFFE5E7EB),
            ),
          ),
          title: Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),
          content: Text(
            description,
            style: textTheme.bodyMedium?.copyWith(color: secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: textTheme.labelLarge?.copyWith(color: accentGreen),
              ),
            ),
          ],
        );
      },
    );
  }
}
