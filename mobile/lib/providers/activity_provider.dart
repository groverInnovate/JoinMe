import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';

/// Activity state provider
class ActivityProvider with ChangeNotifier {
  final ActivityService _activityService = ActivityService();

  List<Activity> _activities = [];
  List<Activity> _nearbyActivities = [];
  Activity? _selectedActivity;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Activity> get activities => _activities;
  List<Activity> get nearbyActivities => _nearbyActivities;
  Activity? get selectedActivity => _selectedActivity;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all activities
  Future<void> fetchActivities() async {
    _setLoading(true);
    _clearError();

    try {
      _activities = await _activityService.getActivities();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Fetch nearby activities
  Future<void> fetchNearbyActivities({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _nearbyActivities = await _activityService.getNearbyActivities(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Get activity by ID
  Future<void> getActivityById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedActivity = await _activityService.getActivityById(id);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Create new activity
  Future<bool> createActivity(Activity activity) async {
    _setLoading(true);
    _clearError();

    try {
      final newActivity = await _activityService.createActivity(activity);
      _activities.insert(0, newActivity);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Join an activity
  Future<bool> joinActivity(String activityId) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedActivity = await _activityService.joinActivity(activityId);
      _updateActivityInList(updatedActivity);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Leave an activity
  Future<bool> leaveActivity(String activityId) async {
    _setLoading(true);
    _clearError();

    try {
      await _activityService.leaveActivity(activityId);
      await fetchActivities(); // Refresh list
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Delete an activity
  Future<bool> deleteActivity(String activityId) async {
    _setLoading(true);
    _clearError();

    try {
      await _activityService.deleteActivity(activityId);
      _activities.removeWhere((a) => a.id == activityId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Clear selected activity
  void clearSelectedActivity() {
    _selectedActivity = null;
    notifyListeners();
  }

  // Helper methods
  void _updateActivityInList(Activity activity) {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
    }
    if (_selectedActivity?.id == activity.id) {
      _selectedActivity = activity;
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
