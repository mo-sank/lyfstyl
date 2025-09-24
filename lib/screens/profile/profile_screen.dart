import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UserProfile?> _load() async {
    final user = FirebaseAuth.instance.currentUser!;
    final svc = context.read<FirestoreService>();
    await svc.ensureUserProfile(user);
    return svc.getUserProfile(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<UserProfile?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          if (profile == null) {
            return _EmptyProfile(onEdit: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                      child: profile.avatarUrl == null ? const Icon(Icons.person, size: 32) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.displayName ?? profile.email, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (profile.username != null) Text('@${profile.username}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const Text('Bio', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(profile.bio!),
                  const SizedBox(height: 12),
                ],
                const Text('Interests', style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.interests.isEmpty
                      ? [const Text('No interests yet')]
                      : profile.interests.map((t) => Chip(label: Text(t))).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Profile visibility:'),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(profile.isPublic ? 'Public' : 'Private'),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  final VoidCallback onEdit;
  const _EmptyProfile({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No profile details yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Add your name, bio, and interests to personalize your page.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            )
          ],
        ),
      ),
    );
  }
}
