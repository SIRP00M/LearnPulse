enum AppRole { student, teacher }

/// The server-authoritative account profile (`public.profiles`).
class Profile {
  const Profile({required this.role, required this.fullName, this.avatarPath});

  final AppRole role;
  final String fullName;

  /// Storage path of the current profile photo (`avatars` bucket), or null for the initials fallback.
  final String? avatarPath;

  /// Strict parse: an unknown role is an error, never a default.
  static Profile? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    final role = switch (row['role']) {
      'student' => AppRole.student,
      'teacher' => AppRole.teacher,
      _ => null,
    };
    if (role == null) return null;
    return Profile(
      role: role,
      fullName: (row['full_name'] as String?) ?? '',
      avatarPath: row['avatar_path'] as String?,
    );
  }
}
