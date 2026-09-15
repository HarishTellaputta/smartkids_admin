class AvailableTeacherUser {
  final int id;
  final String username;
  final String email;
  final String? role;

  AvailableTeacherUser({
    required this.id,
    required this.username,
    required this.email,
    this.role,
  });

  factory AvailableTeacherUser.fromJson(
    Map<String, dynamic> json,
  ) {
    return AvailableTeacherUser(
      id: (json['id'] as num).toInt(),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString(),
    );
  }
}