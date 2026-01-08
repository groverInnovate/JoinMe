/// User model for JoinMe
class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final String? college;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    this.college,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      college: json['college'],
      bio: json['bio'],
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
      'id': id,
      'email': email,
      'name': name,
      'profileImage': profileImage,
      'college': college,
      'bio': bio,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImage,
    String? college,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      college: college ?? this.college,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
