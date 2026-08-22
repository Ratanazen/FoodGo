import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/glass/glass_widgets.dart';
import '../../widgets/glass_container.dart';
import '../../core/theme/glass_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Select Delivery Location',
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(51.509364, -0.128928), // Example coordinates
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.foodgo',
              ),
              const MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(51.509364, -0.128928),
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
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
                    const Text('Order Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        text: 'Confirm Location',
                        icon: Icons.check,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusIcon(IconData icon, bool active) {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(20),
      customColor: active ? GlassTheme.primaryGreen.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
      child: Icon(icon, color: active ? GlassTheme.primaryGreen : GlassTheme.textMuted, size: 20),
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
}