/// API constants and endpoints for JoinMe
class ApiConstants {
  // Base URLs
  // Use your computer's IP for real device, or localhost for simulator
  static const String baseUrl = 'http://10.81.29.149:3001';
  static const String apiVersion = '/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User endpoints
  static const String users = '/users';
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile/update';

  // Activity endpoints
  static const String activities = '/activities';
  static const String createActivity = '/activities/create';
  static const String joinActivity = '/activities/join';
  static const String leaveActivity = '/activities/leave';
  static const String nearbyActivities = '/activities/nearby';

  // Other endpoints
  static const String notifications = '/notifications';
  static const String categories = '/categories';
  static const String healthCheck = '/health';

  // Aadhaar verification endpoints
  static const String aadhaarVerifyQR = '/aadhaar/verify-qr';
  static const String aadhaarLink = '/aadhaar/link';
  static const String aadhaarStatus = '/aadhaar/status';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
