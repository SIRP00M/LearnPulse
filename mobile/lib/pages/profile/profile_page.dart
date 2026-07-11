import 'package:flutter/material.dart';
import 'package:learn_pulse/widgets/profile_menu_item.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                'LP',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Learn Pulse User',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Student',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 28),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal information',
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  trailingText: 'English',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help and support',
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Learn Pulse',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
