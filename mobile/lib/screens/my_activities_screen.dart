import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../widgets/activity_card.dart';

/// My Activities Screen with tabs for Created and Joined activities
class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ActivityService _activityService = ActivityService();

  List<Activity> _createdActivities = [];
  List<Activity> _joinedActivities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _activityService.getMyActivities();
      setState(() {
        _createdActivities = result['created'] ?? [];
        _joinedActivities = result['joined'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load activities: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activities'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Created (${_createdActivities.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Joined (${_joinedActivities.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActivityList(_createdActivities, isCreated: true),
                    _buildActivityList(_joinedActivities, isCreated: false),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
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

  Widget _buildActivityList(List<Activity> activities, {required bool isCreated}) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCreated ? Icons.add_circle_outline : Icons.event_busy,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isCreated
                  ? "You haven't created any activities yet"
                  : "You haven't joined any activities yet",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isCreated
                  ? 'Tap the + button to create one!'
                  : 'Explore activities and join one!',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            if (isCreated)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/create-activity');
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/home');
                },
                icon: const Icon(Icons.explore),
                label: const Text('Explore Activities'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ActivityCard(
            activity: activity,
            onTap: () {
              Navigator.pushNamed(context, '/activity/${activity.id}');
            },
          );
        },
      ),
    );
  }
}
