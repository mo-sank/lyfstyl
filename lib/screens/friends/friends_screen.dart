import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import 'search_friends_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late String currentUserId;
  late Future<List<UserProfile>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    currentUserId = user.uid;
    _loadFriends();
  }

  void _loadFriends() {
    final svc = context.read<FirestoreService>();
    _friendsFuture = svc.getFriends(currentUserId);
  }

  Future<void> _removeFriend(String friendId) async {
    final svc = context.read<FirestoreService>();
    await svc.removeFriend(currentUserId, friendId);
    setState(() {
      _loadFriends(); // Refresh the list
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend removed'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToSearchFriends() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
    );
    setState(() {
      _loadFriends(); // Refresh after returning
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Friends',
            onPressed: _navigateToSearchFriends,
          ),
        ],
      ),
      body: FutureBuilder<List<UserProfile>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data ?? [];
          if (friends.isEmpty) {
            return const Center(
              child: Text(
                'You have no friends yet. Tap the "+" to add some!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
                    child: friend.avatarUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(friend.displayName ?? friend.username ?? friend.email),
                  subtitle: friend.username != null ? Text('@${friend.username}') : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                    onPressed: () => _removeFriend(friend.userId),
                  ),
                  onTap: () {
                    // Optionally, navigate to the friend's profile
                    // Navigator.of(context).push(MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: friend)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
