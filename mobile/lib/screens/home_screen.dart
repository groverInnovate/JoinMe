import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../services/socket_service.dart';
import '../services/location_service.dart';
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
  final SocketService _socketService = SocketService();
  final LocationService _locationService = LocationService();
  
  List<Activity> _activities = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String? _error;
  bool _isNearbyMode = false;
  Position? _currentPosition;

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
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _removeSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    // Listen for new activities
    _socketService.onActivityCreated(_handleNewActivity);
    
    // Listen for participant updates
    _socketService.onParticipantJoined(_handleParticipantUpdate);
    _socketService.onParticipantLeft(_handleParticipantUpdate);
  }

  void _removeSocketListeners() {
    _socketService.removeActivityCreatedListener(_handleNewActivity);
    _socketService.removeParticipantJoinedListener(_handleParticipantUpdate);
    _socketService.removeParticipantLeftListener(_handleParticipantUpdate);
  }

  void _handleNewActivity(dynamic data) {
    if (!mounted) return;
    
    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New activity: ${data['activity']?['title'] ?? 'Unknown'}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: _loadActivities,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Refresh the list
    _loadActivities();
  }

  void _handleParticipantUpdate(dynamic data) {
    if (!mounted) return;
    
    // Update the activity in the list
    final activityId = data['activityId'];
    if (activityId != null) {
      final index = _activities.indexWhere((a) => a.id == activityId);
      if (index != -1 && data['activity'] != null) {
        setState(() {
          _activities[index] = Activity.fromJson(data['activity']);
        });
      }
    }
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Activity> activities;
      
      if (_isNearbyMode && _currentPosition != null) {
        // Fetch nearby activities
        activities = await _activityService.getNearbyActivities(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          category: _selectedCategory,
        );
      } else {
        // Fetch all activities
        activities = await _activityService.getActivities(
          category: _selectedCategory,
        );
      }
      
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

  Future<void> _toggleNearbyMode() async {
    if (!_isNearbyMode) {
      // Turning ON nearby mode - get location
      setState(() => _isLoading = true);
      
      final position = await _locationService.getCurrentPosition();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isNearbyMode = true;
        });
        _loadActivities();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not get location'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => _locationService.openAppSettings(),
              ),
            ),
          );
        }
      }
    } else {
      // Turning OFF nearby mode
      setState(() {
        _isNearbyMode = false;
        _currentPosition = null;
      });
      _loadActivities();
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
        itemCount: _categories.length + 1, // +1 for Nearby chip
        itemBuilder: (context, index) {
          // First item is Nearby chip
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                selected: _isNearbyMode,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me,
                      size: 16,
                      color: _isNearbyMode ? Colors.white : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(_isNearbyMode ? 'Nearby ✓' : 'Nearby'),
                  ],
                ),
                labelStyle: TextStyle(
                  color: _isNearbyMode ? Colors.white : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.orange.shade50,
                selectedColor: Colors.orange,
                onSelected: (_) => _toggleNearbyMode(),
                showCheckmark: false,
              ),
            );
          }
          
          // Category chips
          final category = _categories[index - 1];
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
