import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/stats_service.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> with SingleTickerProviderStateMixin {
  late StatsService _statsService;
  late TabController _tabController;

  StatsSummary? _summary;
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedMetric = 'totalDistance';

  final List<Map<String, dynamic>> _metrics = [
    {'id': 'totalDistance', 'label': 'Distance'},
    {'id': 'totalCalories', 'label': 'Calories'},
    {'id': 'totalArea', 'label': 'Area'},
    {'id': 'totalActivities', 'label': 'Activities'},
  ];

  @override
  void initState() {
    super.initState();
    _statsService = StatsService(ApiService());
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final results = await Future.wait([
      _statsService.getUserSummary(),
      _statsService.getLeaderboard(metric: _selectedMetric),
    ]);

    final summaryResult = results[0] as SummaryResult;
    final leaderboardResult = results[1] as LeaderboardResult;

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (summaryResult.success) {
          _summary = summaryResult.summary;
        } else {
          _errorMessage = summaryResult.message;
        }
        if (leaderboardResult.success) {
          _leaderboard = leaderboardResult.leaderboard;
        }
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    final result = await _statsService.getLeaderboard(metric: _selectedMetric);
    if (mounted && result.success) {
      setState(() {
        _leaderboard = result.leaderboard;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Statistics'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.grey600,
          indicatorColor: AppColors.primaryTeal,
          tabs: const [
            Tab(text: 'My Stats'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyStats(),
                    _buildLeaderboard(),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'Error loading stats',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStats() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            if (_summary != null && _summary!.modeBreakdown.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildModeBreakdown(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem(
                'Distance',
                _summary?.formattedDistance ?? '0 m',
              ),
              _buildOverviewItem(
                'Calories',
                _summary?.formattedCalories ?? '0',
              ),
              _buildOverviewItem(
                'Time',
                _summary?.formattedTime ?? '0m',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Stats',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Territories',
              '${_summary?.territoriesCount ?? 0}',
              Icons.map,
              AppColors.ctaGreen,
            ),
            _buildStatCard(
              'Activities',
              '${_summary?.totalActivities ?? 0}',
              Icons.fitness_center,
              AppColors.ctaOrange,
            ),
            _buildStatCard(
              'Avg Speed',
              _summary?.formattedSpeed ?? '0 km/h',
              Icons.speed,
              AppColors.ctaBlue,
            ),
            _buildStatCard(
              'Total Time',
              _summary?.formattedTime ?? '0m',
              Icons.timer,
              AppColors.ctaRed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'By Activity Type',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        ...(_summary?.modeBreakdown ?? []).map((mode) => _buildModeCard(mode)),
      ],
    );
  }

  Widget _buildModeCard(ModeBreakdown mode) {
    IconData icon;
    Color color;
    switch (mode.mode) {
      case 'walking':
        icon = Icons.hiking;
        color = AppColors.ctaGreen;
        break;
      case 'jogging':
        icon = Icons.directions_walk;
        color = AppColors.ctaOrange;
        break;
      case 'running':
        icon = Icons.directions_run;
        color = AppColors.ctaRed;
        break;
      case 'cycling':
        icon = Icons.directions_bike;
        color = AppColors.ctaBlue;
        break;
      default:
        icon = Icons.directions_run;
        color = AppColors.ctaOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.mode[0].toUpperCase() + mode.mode.substring(1),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mode.count} activities',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            mode.formattedDistance,
            style: AppTextStyles.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      children: [
        _buildMetricSelector(),
        Expanded(
          child: _leaderboard.isEmpty
              ? _buildEmptyLeaderboard()
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaderboard.length,
                    itemBuilder: (context, index) {
                      return _buildLeaderboardItem(_leaderboard[index], index + 1);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        border: Border(bottom: BorderSide(color: AppColors.grey200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _metrics.map((metric) {
            final isSelected = _selectedMetric == metric['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(metric['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMetric = metric['id'] as String;
                    });
                    _loadLeaderboard();
                  }
                },
                selectedColor: AppColors.primaryTeal,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.grey700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 60, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No Data Yet',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Start capturing territories to see the leaderboard!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int rank) {
    Color rankColor;
    IconData? rankIcon;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = AppColors.grey600;
        rankIcon = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rank <= 3 ? rankColor.withValues(alpha: 0.1) : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3 ? rankColor.withValues(alpha: 0.3) : AppColors.grey200,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 28)
                : Text(
                    '#$rank',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: rankColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.username[0].toUpperCase(),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.username,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            entry.formattedValue,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
