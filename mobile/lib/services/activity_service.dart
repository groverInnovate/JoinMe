import '../models/activity_model.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

/// Activity service for managing activities
class ActivityService {
  final ApiService _apiService = ApiService();

  /// Get all activities
  Future<List<Activity>> getActivities() async {
    final response = await _apiService.get(ApiConstants.activities);
    final List<dynamic> data = response['activities'] ?? [];
    return data.map((json) => Activity.fromJson(json)).toList();
  }

  /// Get activity by ID
  Future<Activity> getActivityById(String id) async {
    final response = await _apiService.get('${ApiConstants.activities}/$id');
    return Activity.fromJson(response['activity']);
  }

  /// Get nearby activities
  Future<List<Activity>> getNearbyActivities({
    required double latitude,
    required double longitude,
    double radius = 10.0, // km
  }) async {
    final response = await _apiService.get(
      '${ApiConstants.nearbyActivities}?lat=$latitude&lng=$longitude&radius=$radius',
    );
    final List<dynamic> data = response['activities'] ?? [];
    return data.map((json) => Activity.fromJson(json)).toList();
  }

  /// Create new activity
  Future<Activity> createActivity(Activity activity) async {
    final response = await _apiService.post(
      ApiConstants.createActivity,
      body: activity.toJson(),
    );
    return Activity.fromJson(response['activity']);
  }

  /// Join an activity
  Future<Activity> joinActivity(String activityId) async {
    final response = await _apiService.post(
      '${ApiConstants.joinActivity}/$activityId',
    );
    return Activity.fromJson(response['activity']);
  }

  /// Leave an activity
  Future<void> leaveActivity(String activityId) async {
    await _apiService.post('${ApiConstants.leaveActivity}/$activityId');
  }

  /// Delete an activity
  Future<void> deleteActivity(String activityId) async {
    await _apiService.delete('${ApiConstants.activities}/$activityId');
  }

  /// Update an activity
  Future<Activity> updateActivity(String id, Map<String, dynamic> data) async {
    final response = await _apiService.put(
      '${ApiConstants.activities}/$id',
      body: data,
    );
    return Activity.fromJson(response['activity']);
  }
}
