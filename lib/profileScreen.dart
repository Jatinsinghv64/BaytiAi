import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Color(0xff1150ab))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile picture from Firestore
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 50,
                    child: CircularProgressIndicator(),
                  );
                }

                final photoUrl = snapshot.hasData && snapshot.data!.exists
                    ? (snapshot.data!.data() as Map<String, dynamic>)['photoURL']
                    : null;

                return CircleAvatar(
                  radius: 50,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // User name and email
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                String displayName = user.displayName ?? 'No name';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  displayName = userData['name'] ?? displayName;
                }

                return Column(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1150ab),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email ?? 'No email',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Profile buttons
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
              onPressed: () => _signOut(context),
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
      leading: Icon(icon, color: const Color(0xff1150ab)),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPressed,
    );
  }
}