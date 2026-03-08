import 'dart:async';
import 'dart:io' show Platform;
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

  Stream<List<LatLng>> get pathStream => _pathController.stream;
  Stream<int> get timerStream => _timerController.stream;
  Stream<bool> get trackingStream => _trackingController.stream;

  List<LatLng> _pathPoints = [];
  int _elapsedSeconds = 0;
  bool _isTracking = false;
  String _mode = 'running';

  List<LatLng> get pathPoints => List.unmodifiable(_pathPoints);
  int get elapsedSeconds => _elapsedSeconds;
  bool get isTracking => _isTracking;
  String get mode => _mode;

  Future<void> initialize() async {
    print('[BG_LOCATION] Initializing background location service...');
    // Nothing special needed for initialization
  }

  Future<void> startTracking(String mode) async {
    print('[BG_LOCATION] Starting tracking with mode: $mode');
    _mode = mode;
    _pathPoints = [];
    _elapsedSeconds = 0;
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
        _pathPoints.add(newPoint);
        _pathController.add(List.from(_pathPoints));
      },
      onError: (error) {
        print('[BG_LOCATION] Location error: $error');
      },
    );
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
  }
}
