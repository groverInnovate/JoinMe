/// Activity model for JoinMe
class Activity {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final String creatorId;
  final String? creatorName;
  final DateTime dateTime;
  final String location;
  final double? latitude;
  final double? longitude;
  final int maxParticipants;
  final List<String> participants;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.creatorId,
    this.creatorName,
    required this.dateTime,
    required this.location,
    this.latitude,
    this.longitude,
    required this.maxParticipants,
    required this.participants,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Number of available spots
  int get availableSpots => maxParticipants - participants.length;

  /// Check if activity is full
  bool get isFull => participants.length >= maxParticipants;

  /// Check if a user has joined
  bool hasJoined(String userId) => participants.contains(userId);

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'],
      creatorId: json['creatorId'] ?? '',
      creatorName: json['creatorName'],
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : DateTime.now(),
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      maxParticipants: json['maxParticipants'] ?? 10,
      participants: List<String>.from(json['participants'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'maxParticipants': maxParticipants,
    };
  }

  Activity copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    String? creatorId,
    String? creatorName,
    DateTime? dateTime,
    String? location,
    double? latitude,
    double? longitude,
    int? maxParticipants,
    List<String>? participants,
    bool? isActive,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
