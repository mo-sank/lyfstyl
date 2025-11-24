import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  
  bool _showRequests = false;

  late Future<List<UserProfile>> _friendsFuture;
  late Future<List<UserProfile>> _requestsFuture;

  @override
  void initState() {
    print('🔍 FriendsScreen initState called');
    super.initState();
    print('🚀 Calling _loadData()');
    _loadData();
  }

  void _loadData() {
    print('🔍 _loadData method called');
    final svc = context.read<FirestoreService>();
    
    print('🔍 Attempting to get friends');
    _friendsFuture = svc.getFriends(_currentUserId);
    
    print('🔍 Attempting to get friend requests');
    _requestsFuture = svc.getFriendRequests(_currentUserId);
  }

  void _refresh() {
    setState(_loadData);
  }

  Widget _buildContent() {
    return _showRequests 
      ? _buildFriendRequests() 
      : _buildFriendsList();
  }

  Widget _buildFriendRequests() {
    return FutureBuilder<List<UserProfile>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text("No incoming friend requests"));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return _buildRequestTile(req);
          },
        );
      },
    );
  }

  Widget _buildRequestTile(UserProfile req) {
    final svc = context.read<FirestoreService>();
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: req.avatarUrl != null 
            ? NetworkImage(req.avatarUrl!) 
            : null,
          child: req.avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(req.displayName ?? req.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                await svc.acceptFriendRequest(_currentUserId, req.userId);
                setState(() {
                  _friendsFuture = svc.getFriends(_currentUserId);
                  _requestsFuture = svc.getFriendRequests(_currentUserId);
                }); 
              },
              tooltip: "Accept",
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () async {
                await svc.declineFriendRequest(_currentUserId, req.userId);
                _refresh();
              },
              tooltip: "Decline",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return FutureBuilder<List<UserProfile>>(
      future: _friendsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(child: Text("You have no friends yet"));
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendTile(friend);
          },
        );
      },
    );
  }

  Widget _buildFriendTile(UserProfile friend) {
    final svc = context.read<FirestoreService>();
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: friend.avatarUrl != null 
            ? NetworkImage(friend.avatarUrl!) 
            : null,
          child: friend.avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(friend.displayName ?? friend.email),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () async {
            await svc.removeFriend(_currentUserId, friend.userId);
            _refresh();
          },
          tooltip: "Remove friend",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showRequests ? "Friend Requests" : "My Friends"),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showRequests = !_showRequests),
            child: Text(_showRequests ? "Friends" : "Requests"),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }
}