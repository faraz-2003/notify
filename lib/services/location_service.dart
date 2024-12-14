// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Check and request location permissions
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission if denied
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      // Check if permissions are permanently denied
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      return true;
    } catch (e) {
      print('Error checking/requesting location permissions: $e');
      return false;
    }
  }

  /// Get the current location
  Future<Position?> getCurrentLocation() async {
    try {
      if (await checkAndRequestPermissions()) {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
      return null;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get continuous location updates
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Minimum distance (in meters) before update
      ),
    );
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
      double startLatitude,
      double startLongitude,
      double endLatitude,
      double endLongitude,
      ) {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (e) {
      print('Error calculating distance: $e');
      return double.infinity;
    }
  }

  /// Check if a location is within specified radius
  bool isLocationWithinRadius(
      double centerLatitude,
      double centerLongitude,
      double targetLatitude,
      double targetLongitude,
      double radiusInMeters,
      ) {
    double distance = calculateDistance(
      centerLatitude,
      centerLongitude,
      targetLatitude,
      targetLongitude,
    );
    return distance <= radiusInMeters;
  }

  /// Calculate bearing between two points
  double calculateBearing(
      double startLatitude,
      double startLongitude,
      double endLatitude,
      double endLongitude,
      ) {
    try {
      // Convert degrees to radians
      double startLat = startLatitude * math.pi / 180;
      double startLong = startLongitude * math.pi / 180;
      double endLat = endLatitude * math.pi / 180;
      double endLong = endLongitude * math.pi / 180;

      double dLong = endLong - startLong;

      double y = math.sin(dLong) * math.cos(endLat);
      double x = math.cos(startLat) * math.sin(endLat) -
          math.sin(startLat) * math.cos(endLat) * math.cos(dLong);

      double bearing = math.atan2(y, x);
      bearing = (bearing * 180 / math.pi + 360) % 360; // Convert to degrees

      return bearing;
    } catch (e) {
      print('Error calculating bearing: $e');
      return 0;
    }
  }

  /// Get human-readable direction between two points
  String getDirectionFromBearing(double bearing) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW'
    ];
    int index = ((bearing + 11.25) % 360 / 22.5).floor();
    return directions[index];
  }

  /// Format distance in a human-readable way
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}