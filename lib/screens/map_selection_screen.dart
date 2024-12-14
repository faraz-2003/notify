import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // For FlutterMap
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart'; // For LatLng
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm; // Alias to avoid conflict

class MapSelectionScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapSelectionScreen({super.key, this.initialLocation});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController(); // FlutterMap's MapController
  LatLng? _selectedLocation;
  bool _isLoading = true;
  List<Marker> _markers = [];
  TextEditingController _searchController = TextEditingController();

  static const _defaultZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialLocation != null) {
        _updateSelectedLocation(widget.initialLocation!);
      } else {
        final currentPosition = await _getCurrentLocation();
        if (currentPosition != null) {
          _updateSelectedLocation(
            LatLng(currentPosition.latitude, currentPosition.longitude),
          );
        }
      }
    } catch (e) {
      _updateSelectedLocation(LatLng(37.7749, -122.4194)); // Default to San Francisco
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("Error getting current location: $e");
      return null;
    }
  }

    void _updateSelectedLocation(LatLng location) {
      setState(() {
        _selectedLocation = location;
        _markers = [
          Marker(
            width: 40.0,
            height: 40.0,
            point: location,
            child: const Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 40,
            ),
          ),
        ];
      });

    _mapController.move(location, _defaultZoom);
  }

  Future<void> _searchPlace(String query) async {
    try {
      final List<osm.SearchInfo> results = await osm.addressSuggestion(query);
      if (results.isNotEmpty) {
        final place = results.first;

        // Ensure `place.point` is not null before accessing `latitude` and `longitude`
        if (place.point != null) {
          final location = LatLng(place.point!.latitude, place.point!.longitude);
          _updateSelectedLocation(location);
        } else {
          print("No valid location found for the query: $query");
        }
      }
    } catch (e) {
      print("Error searching place: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation ?? LatLng(37.7749, -122.4194),
                initialZoom: _defaultZoom,
                onTap: (tapPosition, point) => _updateSelectedLocation(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Places',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _searchPlace(query);
                }
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selected Location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_selectedLocation != null)
                      Text(
                        'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}\n'
                            'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      )
                    else
                      const Text('Tap on the map to select a location'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';  // Add this import
import '../services/location_service.dart';

class MapSelectionScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapSelectionScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isLoading = true;
  List<Marker> _markers = [];

  static const _defaultLocation = LatLng(37.7749, -122.4194); // San Francisco
  static const _defaultZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationService = Provider.of<LocationService>(context, listen: false);

    try {
      if (widget.initialLocation != null) {
        _updateSelectedLocation(widget.initialLocation!);
      } else {
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          _updateSelectedLocation(
            LatLng(position.latitude, position.longitude),
          );
        } else {
          _updateSelectedLocation(_defaultLocation);
        }
      }
    } catch (e) {
      _updateSelectedLocation(_defaultLocation);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateSelectedLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = [
        Marker(
          width: 40.0,
          height: 40.0,
          point: location,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      ];
    });

    _mapController.move(location, _defaultZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
              child: const Text('Confirm'),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation ?? _defaultLocation,
                initialZoom: _defaultZoom,
                onTap: (tapPosition, point) => _updateSelectedLocation(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selected Location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_selectedLocation != null)
                      Text(
                        'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}\n'
                            'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      )
                    else
                      const Text('Tap on the map to select a location'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
/*import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';

class MapSelectionScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapSelectionScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = true;
  Set<Marker> _markers = {};

  static const _defaultLocation = LatLng(37.7749, -122.4194); // San Francisco
  static const _defaultZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationService = context.read<LocationService>();

    try {
      if (widget.initialLocation != null) {
        _updateSelectedLocation(widget.initialLocation!);
      } else {
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          _updateSelectedLocation(
            LatLng(position.latitude, position.longitude),
          );
        } else {
          _updateSelectedLocation(_defaultLocation);
        }
      }
    } catch (e) {
      _updateSelectedLocation(_defaultLocation);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateSelectedLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
          },
        ),
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, _defaultZoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
              child: const Text('Confirm'),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? _defaultLocation,
                zoom: _defaultZoom,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: _updateSelectedLocation,
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selected Location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_selectedLocation != null)
                      Text(
                        'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}\n'
                            'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      )
                    else
                      const Text('Tap on the map to select a location'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/