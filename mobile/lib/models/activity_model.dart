import 'user_model.dart';

/// Activity status enum
enum ActivityStatus {
  open,
  closed,
  completed,
  cancelled;

  static ActivityStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'open':
        return ActivityStatus.open;
      case 'closed':
        return ActivityStatus.closed;
      case 'completed':
        return ActivityStatus.completed;
      case 'cancelled':
        return ActivityStatus.cancelled;
      default:
        return ActivityStatus.open;
    }
  }

  String get value => name;
}

/// Activity category enum
enum ActivityCategory {
  sports,
  study,
  food,
  travel,
  games,
  music,
  movies,
  fitness,
  hangout,
  other;

  static ActivityCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'sports':
        return ActivityCategory.sports;
      case 'study':
        return ActivityCategory.study;
      case 'food':
        return ActivityCategory.food;
      case 'travel':
        return ActivityCategory.travel;
      case 'games':
        return ActivityCategory.games;
      case 'music':
        return ActivityCategory.music;
      case 'movies':
        return ActivityCategory.movies;
      case 'fitness':
        return ActivityCategory.fitness;
      case 'hangout':
        return ActivityCategory.hangout;
      default:
        return ActivityCategory.other;
    }
  }

  String get value => name;

  String get displayName {
    switch (this) {
      case ActivityCategory.sports:
        return 'Sports';
      case ActivityCategory.study:
        return 'Study';
      case ActivityCategory.food:
        return 'Food';
      case ActivityCategory.travel:
        return 'Travel';
      case ActivityCategory.games:
        return 'Games';
      case ActivityCategory.music:
        return 'Music';
      case ActivityCategory.movies:
        return 'Movies';
      case ActivityCategory.fitness:
        return 'Fitness';
      case ActivityCategory.hangout:
        return 'Hangout';
      case ActivityCategory.other:
        return 'Other';
    }
  }
}

/// Activity model for JoinMe
class Activity {
  final String id;
  final String title;
  final String? description;
  final ActivityCategory category;
  final User creator;
  final List<User> participants;
  final int maxParticipants;
  final String location;
  final DateTime date;
  final String time;
  final ActivityStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Activity({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.creator,
    required this.participants,
    required this.maxParticipants,
    required this.location,
    required this.date,
    required this.time,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if activity is full
  bool get isFull => participants.length >= maxParticipants;

  /// Get available spots
  int get availableSpots => maxParticipants - participants.length;

  /// Check if a user is the creator
  bool isCreator(String userId) => creator.id == userId;

  /// Check if a user has joined
  bool hasJoined(String userId) => participants.any((p) => p.id == userId);

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: ActivityCategory.fromString(json['category']),
      creator: json['creator'] is Map
          ? User.fromJson(json['creator'])
          : User(id: json['creator']?.toString() ?? '', email: '', name: 'Unknown'),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => p is Map
                  ? User.fromJson(p as Map<String, dynamic>)
                  : User(id: p.toString(), email: '', name: 'Unknown'))
              .toList() ??
          [],
      maxParticipants: json['maxParticipants'] ?? 2,
      location: json['location'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      time: json['time'] ?? '',
      status: ActivityStatus.fromString(json['status']),
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
      'category': category.value,
      'maxParticipants': maxParticipants,
      'location': location,
      'date': date.toIso8601String(),
      'time': time,
    };
  }

  Activity copyWith({
    String? id,
    String? title,
    String? description,
    ActivityCategory? category,
    User? creator,
    List<User>? participants,
    int? maxParticipants,
    String? location,
    DateTime? date,
    String? time,
    ActivityStatus? status,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      creator: creator ?? this.creator,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
