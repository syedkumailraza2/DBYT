import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;

  // Stream controllers for communicating with UI
  final StreamController<List<LatLng>> _pathController = StreamController<List<LatLng>>.broadcast();
  final StreamController<int> _timerController = StreamController<int>.broadcast();
  final StreamController<bool> _trackingController = StreamController<bool>.broadcast();
  final StreamController<TrackingStats> _statsController = StreamController<TrackingStats>.broadcast();

  Stream<List<LatLng>> get pathStream => _pathController.stream;
  Stream<int> get timerStream => _timerController.stream;
  Stream<bool> get trackingStream => _trackingController.stream;
  Stream<TrackingStats> get statsStream => _statsController.stream;

  List<LatLng> _pathPoints = [];
  int _elapsedSeconds = 0;
  bool _isTracking = false;
  String _mode = 'running';
  double _totalDistanceMeters = 0;

  List<LatLng> get pathPoints => List.unmodifiable(_pathPoints);
  int get elapsedSeconds => _elapsedSeconds;
  bool get isTracking => _isTracking;
  String get mode => _mode;
  double get totalDistanceMeters => _totalDistanceMeters;

  // Get current stats
  TrackingStats get currentStats => TrackingStats(
    distanceMeters: _totalDistanceMeters,
    elapsedSeconds: _elapsedSeconds,
    mode: _mode,
  );

  Future<void> initialize() async {
    print('[BG_LOCATION] Initializing background location service...');
    // Nothing special needed for initialization
  }

  Future<void> startTracking(String mode) async {
    print('[BG_LOCATION] Starting tracking with mode: $mode');
    _mode = mode;
    _pathPoints = [];
    _elapsedSeconds = 0;
    _totalDistanceMeters = 0;
    _isTracking = true;
    _trackingController.add(true);

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _elapsedSeconds++;
      _timerController.add(_elapsedSeconds);
    });

    // Configure location settings for background tracking
    // On Android, this will use a foreground service automatically
    late LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 1),
        // This enables foreground service on Android
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "DBYT Territory Tracking",
          notificationText: "Tracking your movement in background",
          enableWakeLock: true,
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      );
    }

    // Start location stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (!_isTracking) return;

        print('[BG_LOCATION] New position: ${position.latitude}, ${position.longitude}');

        final newPoint = LatLng(position.latitude, position.longitude);

        // Calculate distance from previous point
        if (_pathPoints.isNotEmpty) {
          final lastPoint = _pathPoints.last;
          final distance = _calculateDistance(
            lastPoint.latitude,
            lastPoint.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );
          _totalDistanceMeters += distance;
        }

        _pathPoints.add(newPoint);
        _pathController.add(List.from(_pathPoints));
        _statsController.add(currentStats);
      },
      onError: (error) {
        print('[BG_LOCATION] Location error: $error');
      },
    );
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  Future<void> stopTracking() async {
    print('[BG_LOCATION] Stopping tracking');
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _trackingController.add(false);
  }

  Future<List<LatLng>> getPathAndStop() async {
    print('[BG_LOCATION] Getting path and stopping');
    final path = List<LatLng>.from(_pathPoints);
    await stopTracking();
    return path;
  }

  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _pathController.close();
    _timerController.close();
    _trackingController.close();
    _statsController.close();
  }
}

/// Tracking statistics with calculated metrics
class TrackingStats {
  final double distanceMeters;
  final int elapsedSeconds;
  final String mode;

  TrackingStats({
    required this.distanceMeters,
    required this.elapsedSeconds,
    required this.mode,
  });

  /// Distance in kilometers
  double get distanceKm => distanceMeters / 1000;

  /// Average speed in km/h
  double get averageSpeedKmh {
    if (elapsedSeconds == 0) return 0;
    return (distanceMeters / 1000) / (elapsedSeconds / 3600);
  }

  /// Average speed in m/s
  double get averageSpeedMs {
    if (elapsedSeconds == 0) return 0;
    return distanceMeters / elapsedSeconds;
  }

  /// Estimated calories burned based on mode and distance
  /// Using MET (Metabolic Equivalent of Task) values
  double get caloriesBurned {
    // Assume average weight of 70kg
    const double weightKg = 70;

    // MET values for different activities
    double met;
    switch (mode) {
      case 'running':
        met = 9.8; // Running 6 mph
        break;
      case 'jogging':
        met = 7.0; // Jogging
        break;
      case 'cycling':
        met = 7.5; // Cycling moderate effort
        break;
      default:
        met = 7.0;
    }

    // Calories = MET * weight(kg) * time(hours)
    final double hours = elapsedSeconds / 3600;
    return met * weightKg * hours;
  }

  /// Formatted distance string
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  /// Formatted speed string
  String get formattedSpeed {
    return '${averageSpeedKmh.toStringAsFixed(1)} km/h';
  }

  /// Formatted calories string
  String get formattedCalories {
    return '${caloriesBurned.toStringAsFixed(0)} kcal';
  }
}
