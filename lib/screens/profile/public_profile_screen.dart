import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';

class PublicProfileScreen extends StatefulWidget {
  final String username;

  const PublicProfileScreen({super.key, required this.username});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future once in initState
    _profileFuture = _loadProfile();
  }

  Future<UserProfile?> _loadProfile() async {
    final svc = context.read<FirestoreService>();
    
    print('DEBUG PROFILE: Loading profile for username: ${widget.username}');
    
    // Try to get profile by username first
    UserProfile? profile = await svc.getUserProfileByUsername(widget.username);
    
    print('DEBUG PROFILE: Profile by username: ${profile?.email ?? "not found"}');
    
    // If not found, try by userId
    if (profile == null) {
      profile = await svc.getUserProfile(widget.username);
      print('DEBUG PROFILE: Profile by userId: ${profile?.email ?? "not found"}');
    }
    
    // Check if profile is public
    if (profile != null) {
      print('DEBUG PROFILE: Profile found - isPublic: ${profile.isPublic}');
      if (profile.isPublic) {
        return profile;
      }
    }
    
    print('DEBUG PROFILE: Returning null (not found or private)');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          print('DEBUG PROFILE: FutureBuilder state: ${snapshot.connectionState}');
          print('DEBUG PROFILE: Has data: ${snapshot.hasData}');
          print('DEBUG PROFILE: Has error: ${snapshot.hasError}');
          
          if (snapshot.hasError) {
            print('DEBUG PROFILE: Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _profileFuture = _loadProfile();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Profile not found or is private.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
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
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? const Icon(Icons.person, size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.displayName ?? profile.email,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          if (profile.username != null)
                            Text('@${profile.username}',
                                style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const Text('Bio',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(profile.bio!),
                  const SizedBox(height: 12),
                ],
                const Text('Interests',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.interests.isEmpty
                      ? [const Text('No interests yet')]
                      : profile.interests.map((t) => Chip(label: Text(t))).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}