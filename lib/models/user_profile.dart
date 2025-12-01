import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String email;
  final String? displayName;
  final String? username;
  final String? bio;
  final List<String> interests; // freeform tags/genres
  final List<String> favoriteIds; // mediaIds the user favorited
  final bool isPublic; // profile visibility
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  


  UserProfile({
    required this.userId,
    required this.email,
    this.displayName,
    this.username,
    this.bio,
    this.interests = const [],
    this.favoriteIds = const [],
    this.isPublic = true,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'interests': interests,
      'favoriteIds': favoriteIds,
      'isPublic': isPublic,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      userId: doc.id,
      email: (data['email'] ?? '') as String,
      displayName: data['displayName'] as String?,
      username: data['username'] as String?,
      bio: data['bio'] as String?,
      interests: (data['interests'] as List<dynamic>? ?? []).cast<String>(),
      favoriteIds: (data['favoriteIds'] as List<dynamic>? ?? []).cast<String>(),
      isPublic: (data['isPublic'] as bool?) ?? true,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
