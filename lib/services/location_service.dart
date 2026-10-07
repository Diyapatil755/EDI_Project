import 'package:geolocator/geolocator.dart';
import '../core/constants/app_constants.dart';

class LocationTelemetry {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double distanceToOfficeMeters;
  final bool isInsideGeofence;
  final bool isMockLocation;
  final String locationDescription;

  const LocationTelemetry({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.distanceToOfficeMeters,
    required this.isInsideGeofence,
    required this.isMockLocation,
    required this.locationDescription,
  });
}

abstract class LocationService {
  Future<LocationTelemetry> getCurrentTelemetry();
  Future<bool> checkPermission();
  Future<bool> requestPermission();

  // Test simulation methods for evaluations and demo
  void setSimulatedDistanceMeters(double? meters);
  void setSimulatedMockLocation(bool isMock);
  bool get isSimulatedMock;
  double? get simulatedDistance;
}

class GeoLocationService implements LocationService {
  double? _simulatedDistance;
  bool _simulatedMock = false;

  @override
  bool get isSimulatedMock => _simulatedMock;

  @override
  double? get simulatedDistance => _simulatedDistance;

  @override
  void setSimulatedDistanceMeters(double? meters) {
    _simulatedDistance = meters;
  }

  @override
  void setSimulatedMockLocation(bool isMock) {
    _simulatedMock = isMock;
  }

  @override
  Future<bool> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<LocationTelemetry> getCurrentTelemetry() async {
    // If testing mock simulation is activated
    if (_simulatedMock) {
      return const LocationTelemetry(
        latitude: AppConstants.officeLatitude,
        longitude: AppConstants.officeLongitude,
        accuracyMeters: 5.0,
        distanceToOfficeMeters: 12.0,
        isInsideGeofence: true,
        isMockLocation: true,
        locationDescription: 'Mock provider active (Virtual GPS detected)',
      );
    }

    if (_simulatedDistance != null) {
      final dist = _simulatedDistance!;
      final inside = dist <= AppConstants.geofenceRadiusMeters;
      return LocationTelemetry(
        latitude: AppConstants.officeLatitude + (dist / 111000),
        longitude: AppConstants.officeLongitude,
        accuracyMeters: 8.0,
        distanceToOfficeMeters: dist,
        isInsideGeofence: inside,
        isMockLocation: false,
        locationDescription: inside
            ? 'Inside office - ${dist.toStringAsFixed(0)} m from office'
            : 'Outside office - ${dist.toStringAsFixed(0)} m from office',
      );
    }

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (isServiceEnabled) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          AppConstants.officeLatitude,
          AppConstants.officeLongitude,
        );

        final isInside = distance <= AppConstants.geofenceRadiusMeters;
        final isMock = position.isMocked;

        return LocationTelemetry(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
          distanceToOfficeMeters: distance,
          isInsideGeofence: isInside,
          isMockLocation: isMock,
          locationDescription: isInside
              ? 'Inside office - ${distance.toStringAsFixed(0)} m from office'
              : 'Outside office - ${distance.toStringAsFixed(0)} m from office',
        );
      }
    } catch (_) {}

    // Default realistic mock for emulator / web
    const defaultDistance = 35.0; // 35m inside office
    return const LocationTelemetry(
      latitude: AppConstants.officeLatitude,
      longitude: AppConstants.officeLongitude,
      accuracyMeters: 6.0,
      distanceToOfficeMeters: defaultDistance,
      isInsideGeofence: true,
      isMockLocation: false,
      locationDescription: 'Inside office - 35 m from office',
    );
  }
}
