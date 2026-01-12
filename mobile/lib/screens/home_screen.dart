import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../widgets/activity_card.dart';
import '../providers/auth_provider.dart';

/// Home screen - main activity feed
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ActivityService _activityService = ActivityService();
  
  List<Activity> _activities = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String? _error;

  final List<Map<String, dynamic>> _categories = [
    {'value': null, 'label': 'All', 'icon': Icons.apps},
    {'value': 'sports', 'label': 'Sports', 'icon': Icons.sports_basketball},
    {'value': 'study', 'label': 'Study', 'icon': Icons.school},
    {'value': 'food', 'label': 'Food', 'icon': Icons.restaurant},
    {'value': 'travel', 'label': 'Travel', 'icon': Icons.flight},
    {'value': 'games', 'label': 'Games', 'icon': Icons.videogame_asset},
    {'value': 'music', 'label': 'Music', 'icon': Icons.music_note},
    {'value': 'movies', 'label': 'Movies', 'icon': Icons.movie},
    {'value': 'fitness', 'label': 'Fitness', 'icon': Icons.fitness_center},
    {'value': 'hangout', 'label': 'Hangout', 'icon': Icons.people},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activities = await _activityService.getActivities(
        category: _selectedCategory,
      );
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load activities: $e';
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JoinMe'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/my-activities');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true && mounted) {
                  // Import provider at top
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.logout();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          _buildCategoryFilter(),
          
          // Activity list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadActivities,
              color: AppColors.primary,
              child: _buildActivityList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-activity');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['value'];
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(category['label'] as String),
                ],
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppColors.primary,
              onSelected: (_) => _onCategorySelected(category['value'] as String?),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadActivities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != null
                  ? 'No ${_selectedCategory} activities yet'
                  : 'No activities yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create one!',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return ActivityCard(
          activity: activity,
          onTap: () {
            Navigator.pushNamed(context, '/activity/${activity.id}');
          },
        );
      },
    );
  }
}
