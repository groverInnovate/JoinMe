import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../providers/auth_provider.dart';

/// Activity Detail Screen
class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ActivityService _activityService = ActivityService();

  Activity? _activity;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activity = await _activityService.getActivityById(widget.activityId);
      setState(() {
        _activity = activity;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load activity: $e';
        _isLoading = false;
      });
    }
  }

  String? get _currentUserId {
    return context.read<AuthProvider>().user?.id;
  }

  bool get _isCreator {
    if (_activity == null || _currentUserId == null) return false;
    return _activity!.isCreator(_currentUserId!);
  }

  bool get _isParticipant {
    if (_activity == null || _currentUserId == null) return false;
    return _activity!.hasJoined(_currentUserId!);
  }

  Future<void> _handleJoin() async {
    if (_activity == null) return;

    setState(() => _isActionLoading = true);

    try {
      final updatedActivity = await _activityService.joinActivity(_activity!.id);
      setState(() {
        _activity = updatedActivity;
        _isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined the activity!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLeave() async {
    if (_activity == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Activity?'),
        content: const Text('Are you sure you want to leave this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    try {
      await _activityService.leaveActivity(_activity!.id);
      await _loadActivity(); // Reload to get updated data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have left the activity'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadActivity,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_activity == null) return const SizedBox();

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _activity!.title,
              style: const TextStyle(fontSize: 16),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status & Category Row
              Row(
                children: [
                  _buildChip(_activity!.category.displayName, AppColors.primary),
                  const SizedBox(width: 8),
                  _buildStatusChip(),
                  const Spacer(),
                  if (_isCreator)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'You created this',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              if (_activity!.description != null && _activity!.description!.isNotEmpty) ...[
                Text(
                  _activity!.description!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Info Cards
              _buildInfoCard(
                Icons.calendar_today,
                'Date & Time',
                '${DateFormat('EEEE, MMMM d, y').format(_activity!.date)} at ${_activity!.time}',
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                Icons.location_on,
                'Location',
                _activity!.location,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                Icons.people,
                'Participants',
                '${_activity!.participants.length} / ${_activity!.maxParticipants} joined',
              ),
              const SizedBox(height: 24),

              // Participants Section
              const Text(
                'Participants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildParticipantsList(),
              const SizedBox(height: 100), // Space for button
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color bgColor;
    Color textColor;
    String label;

    switch (_activity!.status) {
      case ActivityStatus.open:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Open';
        break;
      case ActivityStatus.closed:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Closed';
        break;
      case ActivityStatus.completed:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Completed';
        break;
      case ActivityStatus.cancelled:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList() {
    return Column(
      children: _activity!.participants.map((user) {
        final isCreator = user.id == _activity!.creator.id;
        final isCurrentUser = user.id == _currentUserId;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentUser ? AppColors.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentUser ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: user.profileImage != null
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: user.profileImage == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isCurrentUser ? 'You' : user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isCreator) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Organizer',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (user.email.isNotEmpty)
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorView()
              : _buildContent(),
      bottomNavigationBar: !_isLoading && _error == null && _activity != null
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildBottomBar() {
    // Creator can't join/leave
    if (_isCreator) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to edit
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // Already joined - show leave button
    if (_isParticipant) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isActionLoading ? null : _handleLeave,
            icon: _isActionLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.exit_to_app),
            label: const Text('Leave Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // Not joined - show join button
    final canJoin = _activity!.status == ActivityStatus.open && !_activity!.isFull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: canJoin && !_isActionLoading ? _handleJoin : null,
          icon: _isActionLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.add),
          label: Text(
            _activity!.isFull
                ? 'Activity Full'
                : _activity!.status != ActivityStatus.open
                    ? 'Not Available'
                    : 'Join Activity',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canJoin ? AppColors.primary : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
