import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';

/// Aadhaar verification response model
class AadhaarVerificationResult {
  final bool success;
  final bool verified;
  final String? referenceId;
  final AadhaarData? data;
  final String? error;
  final String timestamp;
  final String? verificationToken;

  AadhaarVerificationResult({
    required this.success,
    required this.verified,
    this.referenceId,
    this.data,
    this.error,
    required this.timestamp,
    this.verificationToken,
  });

  factory AadhaarVerificationResult.fromJson(Map<String, dynamic> json) {
    final responseData = json['data'];
    return AadhaarVerificationResult(
      success: json['success'] ?? false,
      verified: responseData?['verified'] ?? false,
      referenceId: responseData?['referenceId'],
      data: responseData?['data'] != null
          ? AadhaarData.fromJson(responseData['data'])
          : null,
      error: json['message'],
      timestamp: responseData?['timestamp'] ?? DateTime.now().toIso8601String(),
      verificationToken: json['verificationToken'],
    );
  }
}

/// Aadhaar data extracted from QR
class AadhaarData {
  final String? name;
  final String? uidLastFour;
  final String? gender;
  final String? dateOfBirth;
  final String? yearOfBirth;
  final AadhaarAddress? address;
  final bool hasPhoto;
  final String? photoBase64;

  AadhaarData({
    this.name,
    this.uidLastFour,
    this.gender,
    this.dateOfBirth,
    this.yearOfBirth,
    this.address,
    this.hasPhoto = false,
    this.photoBase64,
  });

  factory AadhaarData.fromJson(Map<String, dynamic> json) {
    return AadhaarData(
      name: json['name'],
      uidLastFour: json['uidLastFour'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'],
      yearOfBirth: json['yearOfBirth'],
      address: json['address'] != null
          ? AadhaarAddress.fromJson(json['address'])
          : null,
      hasPhoto: json['hasPhoto'] ?? false,
      photoBase64: json['photoBase64'],
    );
  }
}

/// Aadhaar address data
class AadhaarAddress {
  final String? careOf;
  final String? house;
  final String? street;
  final String? landmark;
  final String? locality;
  final String? village;
  final String? district;
  final String? subDistrict;
  final String? state;
  final String? postcode;

  AadhaarAddress({
    this.careOf,
    this.house,
    this.street,
    this.landmark,
    this.locality,
    this.village,
    this.district,
    this.subDistrict,
    this.state,
    this.postcode,
  });

  factory AadhaarAddress.fromJson(Map<String, dynamic> json) {
    return AadhaarAddress(
      careOf: json['careOf'],
      house: json['house'],
      street: json['street'],
      landmark: json['landmark'],
      locality: json['locality'],
      village: json['village'],
      district: json['district'],
      subDistrict: json['subDistrict'],
      state: json['state'],
      postcode: json['postcode'],
    );
  }

  String get formattedAddress {
    final parts = <String>[];
    if (house != null) parts.add(house!);
    if (street != null) parts.add(street!);
    if (locality != null) parts.add(locality!);
    if (village != null) parts.add(village!);
    if (district != null) parts.add(district!);
    if (state != null) parts.add(state!);
    if (postcode != null) parts.add(postcode!);
    return parts.join(', ');
  }
}

/// Aadhaar verification service
class AadhaarService {
  static final AadhaarService _instance = AadhaarService._internal();
  factory AadhaarService() => _instance;
  AadhaarService._internal();
  
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Verify Aadhaar QR code image
  Future<AadhaarVerificationResult> verifyQRImage(File imageFile) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.apiVersion}/aadhaar/verify-qr',
      );

      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header if available
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('qrImage', imageFile.path),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return AadhaarVerificationResult.fromJson(jsonResponse);
      } else {
        final errorJson = jsonDecode(response.body);
        return AadhaarVerificationResult(
          success: false,
          verified: false,
          error: errorJson['message'] ?? 'Verification failed',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return AadhaarVerificationResult(
        success: false,
        verified: false,
        error: 'Network error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Link Aadhaar to user account
  Future<Map<String, dynamic>> linkAadhaar({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.apiVersion}/aadhaar/link',
      );

      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header if available
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('qrImage', imageFile.path),
      );

      // Add user ID
      request.fields['userId'] = userId;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Check Aadhaar verification status
  Future<Map<String, dynamic>> getVerificationStatus(String userId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.apiVersion}/aadhaar/status/$userId',
      );

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      final response = await http.get(uri, headers: headers);

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
