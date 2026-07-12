import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final AuthService _authService = AuthService();

  late Future<UserProfile?> _profileFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = _authService.getMyProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _loadProfile();
    });

    await _profileFuture;
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await _authService.signOut();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to sign out: $error')));

      setState(() {
        _isSigningOut = false;
      });
    }
  }

  String _getInitials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'T';
    }

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}'
            '${parts.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _ProfileErrorView(
            message: snapshot.error.toString(),
            onRetry: () {
              setState(() {
                _loadProfile();
              });
            },
          );
        }

        final profile = snapshot.data;

        if (profile == null) {
          return _ProfileErrorView(
            message: 'Profile was not found.',
            onRetry: () {
              setState(() {
                _loadProfile();
              });
            },
          );
        }

        final displayName = profile.fullName.trim().isEmpty
            ? 'Teacher'
            : profile.fullName.trim();

        final roleLabel = profile.role == 'teacher'
            ? 'Teacher account'
            : '${profile.role} account';

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshProfile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              children: [
                Center(
                  child:
                      profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 44,
                          backgroundImage: NetworkImage(profile.avatarUrl!),
                        )
                      : CircleAvatar(
                          radius: 44,
                          child: Text(
                            _getInitials(displayName),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: const Text('Personal information'),
                        subtitle: Text(displayName),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(
                          _authService.currentUser?.email ?? 'No email',
                        ),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.notifications_none_rounded),
                        title: Text('Notifications'),
                        trailing: Icon(Icons.chevron_right_rounded),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.palette_outlined),
                        title: Text('Appearance'),
                        trailing: Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isSigningOut ? null : _signOut,
                  icon: _isSigningOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout_rounded),
                  label: Text(_isSigningOut ? 'Signing out...' : 'Sign out'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 54),
              const SizedBox(height: 14),
              const Text(
                'Unable to load profile',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
