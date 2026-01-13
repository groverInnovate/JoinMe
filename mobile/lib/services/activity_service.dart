import '../models/activity_model.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

/// Activity service for managing activities
class ActivityService {
  final ApiService _apiService = ApiService();

  /// Get all activities with optional filters
  Future<List<Activity>> getActivities({
    String? category,
    String? status,
    String? date,
    int page = 1,
    int limit = 20,
  }) async {
    String endpoint = '${ApiConstants.activities}?page=$page&limit=$limit';
    if (category != null) endpoint += '&category=$category';
    if (status != null) endpoint += '&status=$status';
    if (date != null) endpoint += '&date=$date';

    final response = await _apiService.get(endpoint);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Activity.fromJson(json)).toList();
  }

  /// Get activity by ID
  Future<Activity> getActivityById(String id) async {
    final response = await _apiService.get('${ApiConstants.activities}/$id');
    return Activity.fromJson(response['data']);
  }

  /// Create new activity
  Future<Activity> createActivity({
    required String title,
    String? description,
    required String category,
    required int maxParticipants,
    required String location,
    required DateTime date,
    required String time,
    double? latitude,
    double? longitude,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'category': category,
      'maxParticipants': maxParticipants,
      'location': location,
      'date': date.toIso8601String(),
      'time': time,
    };
    
    // Add coordinates if provided
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }
    
    final response = await _apiService.post(
      ApiConstants.activities,
      body: body,
    );
    return Activity.fromJson(response['data']);
  }

  /// Join an activity
  Future<Activity> joinActivity(String activityId) async {
    final response = await _apiService.post(
      '${ApiConstants.activities}/$activityId/join',
    );
    return Activity.fromJson(response['data']);
  }

  /// Leave an activity
  Future<void> leaveActivity(String activityId) async {
    await _apiService.post('${ApiConstants.activities}/$activityId/leave');
  }

  /// Get user's activities (created + joined)
  Future<Map<String, List<Activity>>> getMyActivities() async {
    final response = await _apiService.get('${ApiConstants.activities}/my-activities');
    final data = response['data'];

    final List<dynamic> createdData = data['created'] ?? [];
    final List<dynamic> joinedData = data['joined'] ?? [];

    return {
      'created': createdData.map((json) => Activity.fromJson(json)).toList(),
      'joined': joinedData.map((json) => Activity.fromJson(json)).toList(),
    };
  }

  /// Get activities created by user
  Future<List<Activity>> getCreatedActivities() async {
    final response = await _apiService.get('${ApiConstants.activities}/user/my');
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Activity.fromJson(json)).toList();
  }

  /// Get activities user has joined
  Future<List<Activity>> getJoinedActivities() async {
    final response = await _apiService.get('${ApiConstants.activities}/user/joined');
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Activity.fromJson(json)).toList();
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
    return Activity.fromJson(response['data']);
  }

  /// Get nearby activities based on coordinates
  Future<List<Activity>> getNearbyActivities({
    required double latitude,
    required double longitude,
    double radius = 10, // in km
    String? category,
    int limit = 20,
  }) async {
    String endpoint = '${ApiConstants.activities}/nearby?lat=$latitude&lng=$longitude&radius=$radius&limit=$limit';
    if (category != null) endpoint += '&category=$category';

    final response = await _apiService.get(endpoint);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Activity.fromJson(json)).toList();
  }
}
