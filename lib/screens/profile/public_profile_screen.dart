//Contributions
//Julia: (2 hours) Public profile class
import 'package:flutter/material.dart';
import 'package:lyfstyl/theme/media_type_theme.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../../models/log_entry.dart';
import '../../models/media_item.dart';
import 'package:go_router/go_router.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<UserProfile?> _profileFuture;
  late Future<List<(LogEntry, MediaItem?)>> _logsFuture;
  late Future<List<UserProfile>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future once in initState
    _loadProfileData();
  }

  void _loadProfileData() {

    // Load profile using the passed userId
    _profileFuture = _loadProfile();
    
    // Load user's logs
    _logsFuture = _loadLogsWithMedia();
    
    // Load user's friends
    _friendsFuture = _loadFriends();
  }

  Future<List<(LogEntry, MediaItem?)>> _loadLogsWithMedia() async {
    final svc = context.read<FirestoreService>();
    final logs = await svc.getUserLogs(widget.userId);
    
    final logsWithMedia = <(LogEntry, MediaItem?)>[];
    for (final log in logs) {
      final media = await svc.getMediaItem(log.mediaId);
      logsWithMedia.add((log, media));
    }
    
    return logsWithMedia;
  }

  Future<List<UserProfile>> _loadFriends() async {
    final svc = context.read<FirestoreService>();
    print('loading friends');
    return await svc.getFriends(widget.userId);
  }

  Future<UserProfile?> _loadProfile() async {
    final svc = context.read<FirestoreService>();
    
    print('DEBUG PROFILE: Loading profile for userId: ${widget.userId}');
    
    UserProfile? profile = await svc.getUserProfile(widget.userId);
    
    print('DEBUG PROFILE: Profile by userId: ${profile?.email ?? "not found"}');
    
    // Check if profile is public
    if (profile != null && profile.isPublic) {
      print('DEBUG PROFILE: Profile found - isPublic: true');
      return profile;
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
          // Error and loading handling remains the same as in previous version
          
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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header (existing code)
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
                  
                  // Bio and Interests (existing code)
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

                  // Friends Section
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Friends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FutureBuilder<List<UserProfile>>(
                    future: _friendsFuture,
                    builder: (context, friendsSnapshot) {
                      if (friendsSnapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final friends = friendsSnapshot.data ?? [];
                      if (friends.isEmpty) {
                        return const Center(child: Text('No friends yet'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: friend.avatarUrl != null 
                                ? NetworkImage(friend.avatarUrl!) 
                                : null,
                              child: friend.avatarUrl == null 
                                ? const Icon(Icons.person) 
                                : null,
                            ),
                            title: Text(friend.displayName ?? friend.email),
                            subtitle: Text('@${friend.username ?? friend.email}'),
                            onTap: () {
                              context.push('/profile/${friend.userId}');
                            },
                          );
                        },
                      );
                    },
                  ),

                  // Logged Items Section
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Logged Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FutureBuilder<List<(LogEntry, MediaItem?)>>(
                    future: _logsFuture,
                    builder: (context, logsSnapshot) {
                      if (logsSnapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final logsWithMedia = logsSnapshot.data ?? [];
                      if (logsWithMedia.isEmpty) {
                        return const Center(child: Text('No logged items'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: logsWithMedia.length,
                        itemBuilder: (context, index) {
                          final (log, media) = logsWithMedia[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(log.mediaType.icon),
                            ),
                            title: Text(media?.title ?? 'Unknown ${log.mediaType.name}'),
                            subtitle: Text(
                              '${log.consumedAt.day}/${log.consumedAt.month}/${log.consumedAt.year}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}