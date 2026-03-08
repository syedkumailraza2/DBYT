import 'api_service.dart';

class TerritoryService {
  final ApiService _apiService;

  TerritoryService(this._apiService);

  Future<TerritoryResult> createTerritory({
    required List<List<double>> coordinates,
    required String mode,
    required int timeTaken,
  }) async {
    print('[TERRITORY_SERVICE] Creating territory...');
    print('[TERRITORY_SERVICE] Mode: $mode, TimeTaken: $timeTaken, Points: ${coordinates.length}');

    final response = await _apiService.post('/territory', {
      'coordinates': coordinates,
      'mode': mode,
      'timeTaken': timeTaken,
    });

    print('[TERRITORY_SERVICE] Create response - success: ${response.success}, status: ${response.statusCode}');

    if (response.success && response.data != null) {
      final territory = response.data!['territory'] as Map<String, dynamic>?;
      if (territory != null) {
        print('[TERRITORY_SERVICE] Territory created: ${territory['_id']}');
        return TerritoryResult(
          success: true,
          message: response.message ?? 'Territory captured',
          territory: TerritoryData.fromJson(territory),
        );
      }
    }

    print('[TERRITORY_SERVICE] Create failed: ${response.message}');
    return TerritoryResult(
      success: false,
      message: response.message ?? 'Failed to create territory',
    );
  }

  Future<TerritoriesResult> getUserTerritories() async {
    print('[TERRITORY_SERVICE] Getting user territories...');

    final response = await _apiService.get('/territory');

    print('[TERRITORY_SERVICE] Get territories response - success: ${response.success}');

    if (response.success && response.data != null) {
      final territoriesJson = response.data!['territories'] as List<dynamic>?;
      final territories = territoriesJson
              ?.map((t) => TerritoryData.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [];

      print('[TERRITORY_SERVICE] Retrieved ${territories.length} territories');
      return TerritoriesResult(
        success: true,
        territories: territories,
      );
    }

    print('[TERRITORY_SERVICE] Get territories failed: ${response.message}');
    return TerritoriesResult(
      success: false,
      message: response.message ?? 'Failed to get territories',
      territories: [],
    );
  }

  Future<TerritoriesResult> getAllTerritories({int page = 1, int limit = 20}) async {
    print('[TERRITORY_SERVICE] Getting all territories...');

    final response = await _apiService.get('/territory?page=$page&limit=$limit');

    if (response.success && response.data != null) {
      final territoriesJson = response.data!['territories'] as List<dynamic>?;
      final territories = territoriesJson
              ?.map((t) => TerritoryData.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [];

      return TerritoriesResult(
        success: true,
        territories: territories,
      );
    }

    return TerritoriesResult(
      success: false,
      message: response.message ?? 'Failed to get territories',
      territories: [],
    );
  }

  Future<TerritoriesResult> getNearbyTerritories({
    required double latitude,
    required double longitude,
    int maxDistance = 5000,
  }) async {
    print('[TERRITORY_SERVICE] Getting nearby territories...');

    final response = await _apiService.get(
        '/territory/nearby?latitude=$latitude&longitude=$longitude&maxDistance=$maxDistance');

    if (response.success && response.data != null) {
      final territoriesJson = response.data!['territories'] as List<dynamic>?;
      final territories = territoriesJson
              ?.map((t) => TerritoryData.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [];

      return TerritoriesResult(
        success: true,
        territories: territories,
      );
    }

    return TerritoriesResult(
      success: false,
      message: response.message ?? 'Failed to get nearby territories',
      territories: [],
    );
  }

  Future<TerritoryResult> deleteTerritory(String territoryId) async {
    print('[TERRITORY_SERVICE] Deleting territory: $territoryId');

    final response = await _apiService.delete('/territory/$territoryId');

    if (response.success) {
      print('[TERRITORY_SERVICE] Territory deleted');
      return TerritoryResult(
        success: true,
        message: response.message ?? 'Territory deleted',
      );
    }

    print('[TERRITORY_SERVICE] Delete failed: ${response.message}');
    return TerritoryResult(
      success: false,
      message: response.message ?? 'Failed to delete territory',
    );
  }
}

class TerritoryResult {
  final bool success;
  final String message;
  final TerritoryData? territory;

  TerritoryResult({
    required this.success,
    required this.message,
    this.territory,
  });
}

class TerritoriesResult {
  final bool success;
  final String? message;
  final List<TerritoryData> territories;

  TerritoriesResult({
    required this.success,
    this.message,
    required this.territories,
  });
}

class TerritoryData {
  final String id;
  final String userId;
  final String? username;
  final String mode;
  final int timeTaken;
  final double area;
  final DateTime capturedAt;
  final List<List<double>> coordinates;

  TerritoryData({
    required this.id,
    required this.userId,
    this.username,
    required this.mode,
    required this.timeTaken,
    required this.area,
    required this.capturedAt,
    required this.coordinates,
  });

  factory TerritoryData.fromJson(Map<String, dynamic> json) {
    // Parse coordinates from GeoJSON polygon format
    List<List<double>> coords = [];
    if (json['Polygon'] != null && json['Polygon']['coordinates'] != null) {
      final polygonCoords = json['Polygon']['coordinates'] as List<dynamic>;
      if (polygonCoords.isNotEmpty) {
        final ring = polygonCoords[0] as List<dynamic>;
        coords = ring.map((c) {
          final coord = c as List<dynamic>;
          return [coord[0] as double, coord[1] as double];
        }).toList();
      }
    }

    // Handle userId - can be string or populated object
    String parsedUserId = '';
    String? parsedUsername;
    if (json['userId'] is String) {
      parsedUserId = json['userId'] as String;
    } else if (json['userId'] is Map) {
      parsedUserId = json['userId']['_id'] as String;
      parsedUsername = json['userId']['username'] as String?;
    }

    return TerritoryData(
      id: json['_id'] as String,
      userId: parsedUserId,
      username: parsedUsername,
      mode: json['mode'] as String? ?? 'running',
      timeTaken: json['timeTaken'] as int? ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0,
      capturedAt: DateTime.parse(json['capturedAt'] as String? ?? DateTime.now().toIso8601String()),
      coordinates: coords,
    );
  }

  String get formattedArea {
    if (area >= 1000000) {
      return '${(area / 1000000).toStringAsFixed(2)} km²';
    } else if (area >= 10000) {
      return '${(area / 10000).toStringAsFixed(2)} ha';
    } else {
      return '${area.toStringAsFixed(0)} m²';
    }
  }

  String get formattedTime {
    final minutes = timeTaken ~/ 60;
    final seconds = timeTaken % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
