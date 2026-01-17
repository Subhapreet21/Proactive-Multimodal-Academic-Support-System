class UserModel {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? role;
  final String? department;
  final String? year;
  final String? section;
  final bool isOnboarded;
  final bool isNewUser;

  UserModel({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.role,
    this.department,
    this.year,
    this.section,
    this.isOnboarded = false,
    this.isNewUser = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['clerk_id'] ?? '',
      email: json['email'],
      fullName: json['full_name'] ?? json['fullName'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      role: json['role'],
      department: json['department'],
      year: json['year']?.toString(),
      section: json['section'],
      isOnboarded: json['role'] != null,
      isNewUser: json['is_new_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'department': department,
      'year': year,
      'section': section,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? role,
    String? department,
    String? year,
    String? section,
    bool? isOnboarded,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      department: department ?? this.department,
      year: year ?? this.year,
      section: section ?? this.section,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }
}
