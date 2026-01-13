import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Location service for handling device location
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  /// Returns true if permission is granted
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, can't request
      debugPrint('Location permission denied forever');
      return false;
    }

    if (permission == LocationPermission.denied) {
      debugPrint('Location permission denied');
      return false;
    }

    return true;
  }

  /// Get current position
  /// Returns null if permission not granted or service disabled
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check/Request permission
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      );

      _lastPosition = position;
      debugPrint('Got position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Get last known position (faster, but may be stale)
  Future<Position?> getLastKnownPosition() async {
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        _lastPosition = position;
      }
      return position;
    } catch (e) {
      debugPrint('Error getting last known location: $e');
      return null;
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Open app settings (for when permission is denied forever)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings (for when location service is disabled)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Stream position updates
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // in meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}

/// Extension to format Position nicely
extension PositionExtension on Position {
  String get formatted => '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  
  Map<String, double> toLatLng() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}
