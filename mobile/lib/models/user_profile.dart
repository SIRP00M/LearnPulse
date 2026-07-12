class UserProfile {
  final String id;
  final String fullName;
  final String role;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
  });

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
