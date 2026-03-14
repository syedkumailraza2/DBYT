import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/territory_service.dart';
import 'map_capture_screen.dart';

class TerritoriesTab extends StatefulWidget {
  const TerritoriesTab({super.key});

  @override
  State<TerritoriesTab> createState() => _TerritoriesTabState();
}

class _TerritoriesTabState extends State<TerritoriesTab> {
  late TerritoryService _territoryService;
  List<TerritoryData> _territories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _territoryService = TerritoryService(ApiService());
    _loadTerritories();
  }

  Future<void> _loadTerritories() async {
    print('[TERRITORIES_TAB] Loading territories...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _territoryService.getUserTerritories();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _territories = result.territories;
          print('[TERRITORIES_TAB] Loaded ${_territories.length} territories');
        } else {
          _errorMessage = result.message;
          print('[TERRITORIES_TAB] Error: ${result.message}');
        }
      });
    }
  }

  Future<void> _navigateToCapture() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const MapCaptureScreen()),
    );

    if (result == true) {
      _loadTerritories();
    }
  }

  Future<void> _deleteTerritory(TerritoryData territory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Territory'),
        content: const Text('Are you sure you want to delete this territory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.ctaRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _territoryService.deleteTerritory(territory.id);

    if (mounted) {
      if (result.success) {
        _showSnackBar('Territory deleted', isError: false);
        _loadTerritories();
      } else {
        _showSnackBar(result.message, isError: true);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Territories'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTerritories,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCapture,
        backgroundColor: AppColors.primaryTeal,
        icon: Icon(Icons.add_location_alt, color: AppColors.white),
        label: Text(
          'Capture',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading territories',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTerritories,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_territories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Territories Yet',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start capturing your first territory!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTerritories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _territories.length,
        itemBuilder: (context, index) {
          final territory = _territories[index];
          return _buildTerritoryCard(territory);
        },
      ),
    );
  }

  Widget _buildTerritoryCard(TerritoryData territory) {
    IconData modeIcon;
    switch (territory.mode) {
      case 'walking':
        modeIcon = Icons.hiking;
        break;
      case 'jogging':
        modeIcon = Icons.directions_walk;
        break;
      case 'running':
        modeIcon = Icons.directions_run;
        break;
      case 'cycling':
        modeIcon = Icons.directions_bike;
        break;
      default:
        modeIcon = Icons.directions_run;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    modeIcon,
                    color: AppColors.primaryTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        territory.formattedArea,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${territory.mode.toUpperCase()} • ${territory.formattedTime}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.grey600),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteTerritory(territory);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.ctaRed, size: 20),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.ctaRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.grey500),
                const SizedBox(width: 6),
                Text(
                  _formatDate(territory.capturedAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.place, size: 14, color: AppColors.grey500),
                const SizedBox(width: 6),
                Text(
                  '${territory.coordinates.length} points',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
