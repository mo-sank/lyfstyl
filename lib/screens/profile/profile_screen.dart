import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../../models/log_entry.dart';
import '../../models/media_item.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile?> _profileFuture;
  late Future<List<(LogEntry, MediaItem?)>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _logsFuture = _loadLogsWithMedia();
  }

  Future<UserProfile?> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    final svc = context.read<FirestoreService>();
    await svc.ensureUserProfile(user);
    return svc.getUserProfile(user.uid);
  }

  Future<List<(LogEntry, MediaItem?)>> _loadLogsWithMedia() async {
    final user = FirebaseAuth.instance.currentUser!;
    final svc = context.read<FirestoreService>();
    final logs = await svc.getUserLogs(user.uid);
    
    // Fetch media items for each log
    final logsWithMedia = <(LogEntry, MediaItem?)>[];
    for (final log in logs) {
      final media = await svc.getMediaItem(log.mediaId);
      logsWithMedia.add((log, media));
    }
    
    return logsWithMedia;
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = _loadLogsWithMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
              setState(() {
                _profileFuture = _loadProfile();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          if (profile == null) {
            return _EmptyProfile(onEdit: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
              setState(() {
                _profileFuture = _loadProfile();
              });
            });
          }

          return SingleChildScrollView(
            child: Padding(
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
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My Logged Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refreshLogs,
                        tooltip: 'Refresh logs',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<(LogEntry, MediaItem?)>>(
                    future: _logsFuture,
                    builder: (context, logsSnapshot) {
                      if (logsSnapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final logsWithMedia = logsSnapshot.data ?? [];
                      if (logsWithMedia.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('No logged items yet', style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: logsWithMedia.length,
                        itemBuilder: (context, index) {
                          final (log, media) = logsWithMedia[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(_getMediaIcon(log.mediaType)),
                              ),
                              title: Text(media?.title ?? 'Unknown ${log.mediaType.name}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (log.rating != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 16, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text('${log.rating!.toStringAsFixed(1)}/5'),
                                      ],
                                    ),
                                  ],
                                  if (log.review != null && log.review!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(log.review!, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${log.consumedAt.day}/${log.consumedAt.month}/${log.consumedAt.year}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
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

  IconData _getMediaIcon(MediaType type) {
    switch (type) {
      case MediaType.film:
        return Icons.movie;
      case MediaType.book:
        return Icons.book;
      case MediaType.album:
        return Icons.album;
      case MediaType.song:
        return Icons.music_note;
      case MediaType.show:
        return Icons.tv;
      case MediaType.music:
        return Icons.music_note;
    }
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