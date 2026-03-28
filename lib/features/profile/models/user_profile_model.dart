class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String fullName;
  final String avatarUrl;

  String get displayName => fullName.trim().isNotEmpty ? fullName : username;

  factory UserProfileModel.fromJson(
    Map<String, dynamic> json, {
    required String avatarUrl,
  }) {
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'writer',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: avatarUrl,
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
