import 'api_service.dart';

class StatsService {
  final ApiService _apiService;

  StatsService(this._apiService);

  Future<SummaryResult> getUserSummary() async {
    print('[STATS_SERVICE] Getting user summary...');

    final response = await _apiService.get('/stats/summary');

    print('[STATS_SERVICE] Summary response - success: ${response.success}');

    if (response.success && response.data != null) {
      return SummaryResult(
        success: true,
        summary: StatsSummary.fromJson(response.data!),
      );
    }

    print('[STATS_SERVICE] Get summary failed: ${response.message}');
    return SummaryResult(
      success: false,
      message: response.message ?? 'Failed to get summary',
    );
  }

  Future<RecentActivityResult> getRecentActivity({int days = 7}) async {
    print('[STATS_SERVICE] Getting recent activity...');

    final response = await _apiService.get('/stats/recent?days=$days');

    if (response.success && response.data != null) {
      final activitiesJson = response.data!['activities'] as List<dynamic>? ?? [];
      final dailyJson = response.data!['dailyBreakdown'] as List<dynamic>? ?? [];

      return RecentActivityResult(
        success: true,
        activities: activitiesJson
            .map((a) => ActivityData.fromJson(a as Map<String, dynamic>))
            .toList(),
        dailyBreakdown: dailyJson
            .map((d) => DailyStats.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
    }

    return RecentActivityResult(
      success: false,
      message: response.message ?? 'Failed to get recent activity',
      activities: [],
      dailyBreakdown: [],
    );
  }

  Future<LeaderboardResult> getLeaderboard({
    String metric = 'totalDistance',
    int limit = 10,
  }) async {
    print('[STATS_SERVICE] Getting leaderboard for $metric...');

    final response = await _apiService.get('/stats/leaderboard?metric=$metric&limit=$limit');

    if (response.success && response.data != null) {
      final leaderboardJson = response.data!['leaderboard'] as List<dynamic>? ?? [];

      return LeaderboardResult(
        success: true,
        metric: response.data!['metric'] as String? ?? metric,
        leaderboard: leaderboardJson
            .map((l) => LeaderboardEntry.fromJson(l as Map<String, dynamic>, metric))
            .toList(),
      );
    }

    return LeaderboardResult(
      success: false,
      message: response.message ?? 'Failed to get leaderboard',
      metric: metric,
      leaderboard: [],
    );
  }
}

class SummaryResult {
  final bool success;
  final String? message;
  final StatsSummary? summary;

  SummaryResult({
    required this.success,
    this.message,
    this.summary,
  });
}

class StatsSummary {
  final double totalDistance;
  final double totalCalories;
  final int totalTime;
  final double averageSpeed;
  final int totalActivities;
  final int territoriesCount;
  final List<ModeBreakdown> modeBreakdown;

  StatsSummary({
    required this.totalDistance,
    required this.totalCalories,
    required this.totalTime,
    required this.averageSpeed,
    required this.totalActivities,
    required this.territoriesCount,
    required this.modeBreakdown,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final modeJson = json['modeBreakdown'] as List<dynamic>? ?? [];

    return StatsSummary(
      totalDistance: (summaryJson['totalDistance'] as num?)?.toDouble() ?? 0,
      totalCalories: (summaryJson['totalCalories'] as num?)?.toDouble() ?? 0,
      totalTime: (summaryJson['totalTime'] as num?)?.toInt() ?? 0,
      averageSpeed: (summaryJson['averageSpeed'] as num?)?.toDouble() ?? 0,
      totalActivities: (summaryJson['totalActivities'] as num?)?.toInt() ?? 0,
      territoriesCount: (json['territoriesCount'] as num?)?.toInt() ?? 0,
      modeBreakdown: modeJson
          .map((m) => ModeBreakdown.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedDistance {
    if (totalDistance >= 1000) {
      return '${(totalDistance / 1000).toStringAsFixed(1)} km';
    }
    return '${totalDistance.toStringAsFixed(0)} m';
  }

  String get formattedTime {
    final hours = totalTime ~/ 3600;
    final minutes = (totalTime % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedCalories {
    if (totalCalories >= 1000) {
      return '${(totalCalories / 1000).toStringAsFixed(1)}k';
    }
    return totalCalories.toStringAsFixed(0);
  }

  String get formattedSpeed {
    return '${averageSpeed.toStringAsFixed(1)} km/h';
  }
}

class ModeBreakdown {
  final String mode;
  final int count;
  final double distance;
  final double calories;
  final int time;

  ModeBreakdown({
    required this.mode,
    required this.count,
    required this.distance,
    required this.calories,
    required this.time,
  });

  factory ModeBreakdown.fromJson(Map<String, dynamic> json) {
    return ModeBreakdown(
      mode: json['_id'] as String? ?? 'unknown',
      count: (json['count'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      time: (json['time'] as num?)?.toInt() ?? 0,
    );
  }

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }
}

class RecentActivityResult {
  final bool success;
  final String? message;
  final List<ActivityData> activities;
  final List<DailyStats> dailyBreakdown;

  RecentActivityResult({
    required this.success,
    this.message,
    required this.activities,
    required this.dailyBreakdown,
  });
}

class ActivityData {
  final String id;
  final double distanceCovered;
  final double caloriesBurned;
  final double averageSpeed;
  final int timeTaken;
  final DateTime capturedAt;

  ActivityData({
    required this.id,
    required this.distanceCovered,
    required this.caloriesBurned,
    required this.averageSpeed,
    required this.timeTaken,
    required this.capturedAt,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      id: json['_id'] as String,
      distanceCovered: (json['distanceCovered'] as num?)?.toDouble() ?? 0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0,
      averageSpeed: (json['averageSpeed'] as num?)?.toDouble() ?? 0,
      timeTaken: (json['timeTaken'] as num?)?.toInt() ?? 0,
      capturedAt: DateTime.parse(json['capturedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

class DailyStats {
  final String date;
  final double distance;
  final double calories;
  final int activities;

  DailyStats({
    required this.date,
    required this.distance,
    required this.calories,
    required this.activities,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['_id'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      activities: (json['activities'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardResult {
  final bool success;
  final String? message;
  final String metric;
  final List<LeaderboardEntry> leaderboard;

  LeaderboardResult({
    required this.success,
    this.message,
    required this.metric,
    required this.leaderboard,
  });
}

class LeaderboardEntry {
  final String odValue;
  final String username;
  final double value;

  LeaderboardEntry({
    required this.odValue,
    required this.username,
    required this.value,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, String metric) {
    return LeaderboardEntry(
      odValue: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown',
      value: (json[metric] as num?)?.toDouble() ?? (json['totalArea'] as num?)?.toDouble() ?? 0,
    );
  }

  String get formattedValue {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
