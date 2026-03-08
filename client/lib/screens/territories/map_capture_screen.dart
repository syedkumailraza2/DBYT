import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/territory_service.dart';

class MapCaptureScreen extends StatefulWidget {
  const MapCaptureScreen({super.key});

  @override
  State<MapCaptureScreen> createState() => _MapCaptureScreenState();
}

class _MapCaptureScreenState extends State<MapCaptureScreen> {
  // Map controller
  GoogleMapController? _mapController;

  // Location tracking
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _pathPoints = [];
  Set<Polyline> _polylines = {};
  Set<Polygon> _polygons = {};

  // State
  bool _isPermissionGranted = false;
  bool _isLoading = true;
  bool _isTracking = false;
  String _errorMsg = '';
  String _selectedMode = 'running';
  int _elapsedSeconds = 0;
  Timer? _timer;

  // Services
  late TerritoryService _territoryService;

  // Initial camera position (will be updated to user location)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

  final List<Map<String, dynamic>> _modes = [
    {'id': 'walking', 'label': 'Walking', 'icon': Icons.directions_walk},
    {'id': 'running', 'label': 'Running', 'icon': Icons.directions_run},
    {'id': 'cycling', 'label': 'Cycling', 'icon': Icons.directions_bike},
  ];

  @override
  void initState() {
    super.initState();
    _territoryService = TerritoryService(ApiService());
    _initialize();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    print('[MAP_CAPTURE] Requesting location permission...');

    var status = await Permission.location.status;
    print('[MAP_CAPTURE] Current permission status: $status');

    if (!status.isGranted) {
      status = await Permission.location.request();
      print('[MAP_CAPTURE] Permission after request: $status');
    }

    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
        _isLoading = false;
      });
      print('[MAP_CAPTURE] Permission granted');
    } else {
      setState(() {
        _errorMsg = 'Location permission is required to capture territories.';
        _isPermissionGranted = false;
        _isLoading = false;
      });
      print('[MAP_CAPTURE] Permission denied');
    }
  }

  Future<void> _goToUserLocation() async {
    if (!_isPermissionGranted) return;

    try {
      print('[MAP_CAPTURE] Getting current position...');
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      LatLng userLatLng = LatLng(pos.latitude, pos.longitude);
      print('[MAP_CAPTURE] User location: ${pos.latitude}, ${pos.longitude}');

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userLatLng, 17),
      );
    } catch (e) {
      print('[MAP_CAPTURE] Error getting location: $e');
    }
  }

  void _startTracking() {
    print('[MAP_CAPTURE] Starting tracking...');
    setState(() {
      _isTracking = true;
      _pathPoints = [];
      _polylines = {};
      _polygons = {};
      _elapsedSeconds = 0;
    });

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });

    // Start location stream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // Update every 2 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      print('[MAP_CAPTURE] New position: ${position.latitude}, ${position.longitude}');

      final newPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        _pathPoints.add(newPoint);
        _updatePolylines();
      });

      // Keep camera centered on user
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(newPoint),
      );
    });
  }

  void _updatePolylines() {
    _polylines = {
      Polyline(
        polylineId: const PolylineId('tracking_path'),
        points: List.from(_pathPoints),
        width: 5,
        color: AppColors.primaryTeal,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  void _stopTracking() {
    print('[MAP_CAPTURE] Stopping tracking...');
    _positionStream?.cancel();
    _timer?.cancel();

    setState(() {
      _isTracking = false;
    });

    if (_pathPoints.length < 3) {
      _showSnackBar('You need at least 3 points to create a territory', isError: true);
      return;
    }

    // Close the polygon by connecting last point to first
    final closedPath = List<LatLng>.from(_pathPoints);
    if (closedPath.first != closedPath.last) {
      closedPath.add(closedPath.first);
    }

    setState(() {
      _polygons = {
        Polygon(
          polygonId: const PolygonId('captured_territory'),
          points: closedPath,
          strokeWidth: 3,
          strokeColor: AppColors.primaryTeal,
          fillColor: AppColors.primaryTeal.withValues(alpha: 0.3),
        ),
      };
      _polylines = {};
    });

    // Show save dialog
    _showSaveDialog();
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Save Territory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mode: ${_modes.firstWhere((m) => m['id'] == _selectedMode)['label']}',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${_formatTime(_elapsedSeconds)}',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Points: ${_pathPoints.length}',
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _discardTerritory();
            },
            child: Text(
              'Discard',
              style: TextStyle(color: AppColors.ctaRed),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveTerritory();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _discardTerritory() {
    setState(() {
      _pathPoints = [];
      _polylines = {};
      _polygons = {};
      _elapsedSeconds = 0;
    });
  }

  Future<void> _saveTerritory() async {
    print('[MAP_CAPTURE] Saving territory...');

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Convert LatLng to List<List<double>> [lng, lat] format for GeoJSON
    final coordinates = _pathPoints.map((point) {
      return [point.longitude, point.latitude];
    }).toList();

    // Close the polygon
    if (coordinates.isNotEmpty &&
        (coordinates.first[0] != coordinates.last[0] ||
         coordinates.first[1] != coordinates.last[1])) {
      coordinates.add(coordinates.first);
    }

    final result = await _territoryService.createTerritory(
      coordinates: coordinates,
      mode: _selectedMode,
      timeTaken: _elapsedSeconds,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (result.success) {
      _showSnackBar('Territory captured successfully!', isError: false);
      Navigator.pop(context, true); // Return to territories tab with success
    } else {
      _showSnackBar(result.message, isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: isError ? AppColors.ctaRed : AppColors.ctaGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Capture Territory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isTracking) {
              _showExitWarning();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  void _showExitWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Tracking?'),
        content: const Text('You are currently tracking. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _positionStream?.cancel();
              _timer?.cancel();
              Navigator.pop(context);
            },
            child: Text(
              'Exit',
              style: TextStyle(color: AppColors.ctaRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isPermissionGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 80,
                color: AppColors.grey400,
              ),
              const SizedBox(height: 16),
              Text(
                'Location Access Required',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMsg,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _requestLocationPermission,
                icon: const Icon(Icons.refresh),
                label: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Map
        GoogleMap(
          polylines: _polylines,
          polygons: _polygons,
          initialCameraPosition: _initialPosition,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            _goToUserLocation();
          },
        ),

        // Mode selector (only when not tracking)
        if (!_isTracking)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildModeSelector(),
          ),

        // Timer and stats (when tracking)
        if (_isTracking)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildTrackingStats(),
          ),

        // My location button
        Positioned(
          right: 16,
          bottom: 120,
          child: FloatingActionButton.small(
            heroTag: 'location',
            onPressed: _goToUserLocation,
            backgroundColor: AppColors.white,
            child: Icon(
              Icons.my_location,
              color: AppColors.primaryTeal,
            ),
          ),
        ),

        // Start/Stop button
        Positioned(
          left: 16,
          right: 16,
          bottom: 32,
          child: _buildActionButton(),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _modes.map((mode) {
          final isSelected = _selectedMode == mode['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = mode['id'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode['icon'] as IconData,
                      color: isSelected ? AppColors.white : AppColors.grey600,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['label'] as String,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected ? AppColors.white : AppColors.grey600,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrackingStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.timer,
            label: 'Time',
            value: _formatTime(_elapsedSeconds),
          ),
          _buildStatItem(
            icon: Icons.place,
            label: 'Points',
            value: '${_pathPoints.length}',
          ),
          _buildStatItem(
            icon: _modes.firstWhere((m) => m['id'] == _selectedMode)['icon'] as IconData,
            label: 'Mode',
            value: _modes.firstWhere((m) => m['id'] == _selectedMode)['label'] as String,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isTracking ? _stopTracking : _startTracking,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isTracking ? AppColors.ctaRed : AppColors.ctaGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTracking ? Icons.stop : Icons.play_arrow,
              color: AppColors.white,
            ),
            const SizedBox(width: 8),
            Text(
              _isTracking ? 'Stop & Save' : 'Start Tracking',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
