import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/activity_model.dart';
import 'package:intl/intl.dart';

/// Activity card widget for displaying activity in list
class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category & Status
              Row(
                children: [
                  _buildCategoryChip(),
                  const Spacer(),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (activity.description != null && activity.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  activity.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Date, Time, Location
              Row(
                children: [
                  _buildInfoChip(
                    Icons.calendar_today,
                    _formatDate(activity.date),
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.access_time,
                    activity.time,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoChip(
                Icons.location_on,
                activity.location,
              ),
              
              const Divider(height: 24),
              
              // Footer: Creator & Participants
              Row(
                children: [
                  // Creator
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: activity.creator.profileImage != null
                        ? NetworkImage(activity.creator.profileImage!)
                        : null,
                    child: activity.creator.profileImage == null
                        ? Text(
                            activity.creator.name.isNotEmpty
                                ? activity.creator.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.creator.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Organizer',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Participants count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: activity.isFull
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: activity.isFull
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.participants.length}/${activity.maxParticipants}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: activity.isFull
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        activity.category.displayName,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;

    switch (activity.status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    if (activityDate == today) {
      return 'Today';
    } else if (activityDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
