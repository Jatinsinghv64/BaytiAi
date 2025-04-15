import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://randomuser.me/api/portraits/men/1.jpg'),
            ),
            const SizedBox(height: 16),
            const Text(
              'John Doe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'john.doe@example.com',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileButton(
              icon: Icons.favorite,
              text: 'Saved Properties',
              onPressed: () {},
            ),
            _buildProfileButton(
              icon: Icons.history,
              text: 'Viewing History',
              onPressed: () {},
            ),
            _buildProfileButton(
              icon: Icons.settings,
              text: 'Settings',
              onPressed: () {},
            ),
            _buildProfileButton(
              icon: Icons.logout,
              text: 'Log Out',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPressed,
    );
  }
}