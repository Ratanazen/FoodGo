import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/config/map_config.dart';
import '../core/theme/glass_theme.dart';
import '../core/utils/location_helper.dart';
import '../screens/map_screen_location.dart';
import 'glass/glass_widgets.dart';

class LocationPickerModal extends StatefulWidget {
  final LatLng initialPosition;
  final ValueChanged<LocationDetails> onLocationConfirmed;

  const LocationPickerModal({
    super.key,
    required this.initialPosition,
    required this.onLocationConfirmed,
  });

  static Future<LocationDetails?> show(
    BuildContext context, {
    LatLng? initialPosition,
  }) async {
    LocationDetails? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPickerModal(
        initialPosition: initialPosition ?? MapConfig.defaultCenter,
        onLocationConfirmed: (details) {
          result = details;
          Navigator.of(ctx).pop();
        },
      ),
    );
    return result;
  }

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  final MapController _mapController = MapController();
  late LatLng _currentCenter;
  LocationDetails? _resolvedLocation;
  bool _isResolving = false;
  bool _isLocatingGps = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialPosition;
    _resolveCurrentCenter();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _currentCenter = camera.center;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _resolveCurrentCenter();
    });
  }

  Future<void> _resolveCurrentCenter() async {
    if (!mounted) return;
    setState(() => _isResolving = true);
    final details = await LocationHelper.resolveLocation(
      _currentCenter.latitude,
      _currentCenter.longitude,
    );
    if (!mounted) return;
    setState(() {
      _resolvedLocation = details;
      _isResolving = false;
    });
  }

  Future<void> _fetchGpsLocation() async {
    setState(() => _isLocatingGps = true);
    final loc = await getDeviceLocation();
    setState(() => _isLocatingGps = false);

    if (loc != null && mounted) {
      _currentCenter = loc;
      _mapController.move(loc, 16.0);
      _resolveCurrentCenter();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS Location Acquired'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get GPS. Using current pin location.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? GlassTheme.dialogDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            // ── Interactive Map ──
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 15.0,
                minZoom: 10.0,
                maxZoom: 18.0,
                onPositionChanged: _onPositionChanged,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.foodgo_flutter',
                ),
              ],
            ),

            // ── Fixed Center Pin ──
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GlassTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Top Header with Close and Search Title ──
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black87 : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black87 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.map,
                            color: GlassTheme.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Find & Pick Delivery Location',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Right Side Action Buttons (GPS & Zoom) ──
            Positioned(
              right: 16,
              bottom: 180,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'picker_gps_btn',
                    backgroundColor: isDark ? Colors.black87 : Colors.white,
                    foregroundColor: GlassTheme.primaryGreen,
                    onPressed: _isLocatingGps ? null : _fetchGpsLocation,
                    child: _isLocatingGps
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'picker_zoom_in_btn',
                    backgroundColor: isDark ? Colors.black87 : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    onPressed: () {
                      _mapController.move(
                        _currentCenter,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'picker_zoom_out_btn',
                    backgroundColor: isDark ? Colors.black87 : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    onPressed: () {
                      _mapController.move(
                        _currentCenter,
                        _mapController.camera.zoom - 1,
                      );
                    },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),

            // ── Bottom Card: Location Details & Confirm ──
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? GlassTheme.dialogDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.place,
                            color: GlassTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isResolving
                                    ? 'Resolving Location...'
                                    : (_resolvedLocation?.title ??
                                          'Location Coordinates'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _resolvedLocation?.fullAddress ??
                                    '${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      text: 'Confirm Location',
                      variant: GlassButtonVariant.primary,
                      height: 48,
                      isFullWidth: true,
                      onPressed: () {
                        final loc =
                            _resolvedLocation ??
                            LocationDetails(
                              title: 'Selected Pin Location',
                              fullAddress:
                                  'Pin (${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)})',
                              district: 'Daun Penh',
                              city: 'Phnom Penh',
                              latitude: _currentCenter.latitude,
                              longitude: _currentCenter.longitude,
                            );
                        widget.onLocationConfirmed(loc);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
