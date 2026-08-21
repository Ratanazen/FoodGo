import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Delivery Location')),
      body: FlutterMap(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context); // Return selected location logic here
        },
        label: const Text('Confirm Location'),
        icon: const Icon(Icons.check),
        backgroundColor: const Color(0xFF0072FF),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
