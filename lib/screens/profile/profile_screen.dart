// Contributions:
// Julia: (3 hours) Profile page sharing and logs showing up on profile
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lyfstyl/theme/media_type_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../models/log_entry.dart';
import '../../models/media_item.dart';
import 'profile_edit_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html show window;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile?> _profileFuture;
  late Future<List<(LogEntry, MediaItem?)>> _logsFuture;
  bool _isDeleting = false;
  late Future<List<UserProfile>> _friendsFuture;
  late Future<List<UserProfile>> _friendRequestsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _logsFuture = _loadLogsWithMedia();
    _friendsFuture = _loadFriends();
    _friendRequestsFuture = _loadFriendRequests();

  }

  Future<List<UserProfile>> _loadFriends() async {
    final user = FirebaseAuth.instance.currentUser!;
    final svc = context.read<FirestoreService>();
    return await svc.getFriends(user.uid);
  }

  Future<List<UserProfile>> _loadFriendRequests() async {
    final user = FirebaseAuth.instance.currentUser!;
    final svc = context.read<FirestoreService>();
    return await svc.getFriendRequests(user.uid);
  }

  Future<UserProfile?> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    final svc = context.read<FirestoreService>();
    await svc.ensureUserProfile(user);
    return svc.getUserProfile(user.uid);
  }

  String _getBaseUrl() {
    // For web platform, get the current URL
    if (kIsWeb) {
      final origin = html.window.location.origin;
      return origin; // e.g., http://localhost:8080 or https://lyfstyl.com
    }
    // For mobile/desktop, use production URL
    return 'https://lyfstyl.com';
  }

  void _shareProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    final svc = context.read<FirestoreService>();
    final profile = await svc.getUserProfile(user.uid);

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You don't have a profile to share yet!")),
      );
      return;
    }

    // Generate profile link
    String? profileUrl;
    if (profile.isPublic && profile.username != null) {
      final baseUrl = _getBaseUrl();
      profileUrl = "$baseUrl/profile/${profile.username}";
    } else if (profile.isPublic) {
      // Fallback to user ID if no username is set
      final baseUrl = _getBaseUrl();
      profileUrl = "$baseUrl/profile/${user.uid}";
    }

    // Debug: Print the generated URL
    print('DEBUG SHARE: Generated profile URL: $profileUrl');

    final shareText = StringBuffer()
    ..writeln("${profile.displayName ?? 'A user'}'s profile on Lyfstyl:")
    ..writeln(profile.bio?.isNotEmpty == true ? '"${profile.bio}"' : '')
    ..writeln()
    ..writeln('Interests: ${profile.interests.isEmpty ? "None" : profile.interests.join(", ")}')
    ..writeln();
    
    if (profileUrl != null) {
      shareText.writeln('View profile: $profileUrl');
    } else {
      shareText.writeln('(Profile is currently private)');
    }

    await Share.share(shareText.toString());
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

  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All of your profile information, logs, collections, and bookmarks will be permanently deleted.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm your password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    final password = passwordController.text.trim();
    passwordController.dispose();

    if (confirmed == true && !_isDeleting) {
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password to proceed.')),
        );
        return;
      }
      await _deleteAccount(password);
    }
  }

  Future<void> _deleteAccount(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isDeleting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting account… please wait')),
    );

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      final svc = context.read<UserService>();
      await svc.deleteUserData(user.uid);
      await user.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted. Goodbye!')),
      );
      context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message =
          'Failed to delete account. Please try again after re-authenticating.';
      if (e.code == 'requires-recent-login') {
        message = 'Please re-enter your password and try again.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Account delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProfile,
          ),
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
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Delete account',
            onPressed: _isDeleting ? null : _confirmDeleteAccount,
          ),
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
                      const Text('Friends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        tooltip: 'Search users to add',
                        onPressed: () {
                          context.push('/search_users'); // We'll create this route next
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<UserProfile>>(
                    future: _friendsFuture,
                    builder: (context, friendsSnapshot) {
                      if (friendsSnapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final friends = friendsSnapshot.data ?? [];
                      if (friends.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('No friends yet', style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
                              child: friend.avatarUrl == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(friend.displayName ?? friend.username ?? friend.email),
                            subtitle: Text('@${friend.username ?? friend.email}'),
                            onTap: () {
                              context.push('/profile/${friend.userId}');
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Friend Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<UserProfile>>(
                    future: _friendRequestsFuture,
                    builder: (context, requestsSnapshot) {
                      if (requestsSnapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final requests = requestsSnapshot.data ?? [];
                      if (requests.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('No friend requests', style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final requester = requests[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: requester.avatarUrl != null 
                                ? NetworkImage(requester.avatarUrl!) 
                                : null,
                              child: requester.avatarUrl == null 
                                ? const Icon(Icons.person) 
                                : null,
                            ),
                            title: Text(requester.displayName ?? requester.username ?? requester.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    final svc = context.read<FirestoreService>();
                                    await svc.acceptFriendRequest(
                                      FirebaseAuth.instance.currentUser!.uid, 
                                      requester.userId
                                    );
                                    // Refresh friend requests and friends
                                    setState(() {
                                      _friendRequestsFuture = _loadFriendRequests();
                                      _friendsFuture = _loadFriends();
                                    });
                                    print('Futures reloaded');
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () async {
                                    final svc = context.read<FirestoreService>();
                                    await svc.declineFriendRequest(
                                      FirebaseAuth.instance.currentUser!.uid, 
                                      requester.userId
                                    );
                                    // Refresh friend requests
                                    setState(() {
                                      _friendRequestsFuture = _loadFriendRequests();
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
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
                                child: Icon(log.mediaType.icon),
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