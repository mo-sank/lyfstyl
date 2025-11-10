// Mohamed Sankari - 4 hours

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../models/user_profile.dart';
import '../models/media_item.dart';
import '../models/log_entry.dart';
import '../models/collection.dart';
import '../models/bookmark_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Collections
  CollectionReference<Map<String, dynamic>> get usersCol =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get mediaCol =>
      _db.collection('mediaItems');
  CollectionReference<Map<String, dynamic>> get logsCol =>
      _db.collection('logs');
  CollectionReference<Map<String, dynamic>> get collectionsCol =>
      _db.collection('collections');
  CollectionReference<Map<String, dynamic>> get trendingCol =>
      _db.collection('trending');
  CollectionReference<Map<String, dynamic>> get bookmarksCol =>
      _db.collection('bookmarks');

  // Ensure a profile exists for the signed-in user
  Future<void> ensureUserProfile(User user) async {
    final doc = await usersCol.doc(user.uid).get();
    if (!doc.exists) {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        username: null,
        bio: null,
        interests: const [],
        favoriteIds: const [],
        isPublic: true,
        avatarUrl: user.photoURL,
        createdAt: now,
        updatedAt: now,
      );
      await usersCol
          .doc(user.uid)
          .set(profile.toMap(), SetOptions(merge: true));
    }
  }

  // Users: create/update/get profile
  Future<void> upsertUserProfile(UserProfile profile) async {
    await usersCol
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  // ---------------------------
  // Friend Requests
  // ---------------------------


  Future<void> sendFriendRequest(String recipientUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }
    
    final currentUserId = currentUser.uid;
    
    try {
      final requestRef = usersCol
          .doc(recipientUserId)
          .collection('friendRequests')
          .doc(currentUserId);
      
      final requestData = {
        'senderId': currentUserId,
        'recipientId': recipientUserId,
        'senderEmail': currentUser.email,
        'senderDisplayName': currentUser.displayName,
        'status': 'pending',
        'sentAt': FieldValue.serverTimestamp(),
      };

      await requestRef.set(requestData, SetOptions(merge: true));

      // Verify the document was actually created
      final createdDoc = await requestRef.get();
      print('Created Friend Request Document:');
      print(createdDoc.data());
    } catch (e, stackTrace) {
      print('❌ Friend Request Error: $e');
      print('❌ Stack Trace: $stackTrace');
      rethrow;
    }
  }
      // In firestore_service.dart - simplified version
  Future<void> acceptFriendRequest(String currentUserId, String senderUserId) async {
    try {
      print('Step 1: Deleting friend request...');
      final requestDoc = usersCol
          .doc(currentUserId)
          .collection('friendRequests')
          .doc(senderUserId);
      await requestDoc.delete();
      print('✓ Friend request deleted');

      print('Step 2: Adding to current user friends...');
      final currentUserFriendDoc = usersCol
          .doc(currentUserId)
          .collection('friends')
          .doc(senderUserId);
      await currentUserFriendDoc.set({'addedAt': FieldValue.serverTimestamp()});
      print('✓ Added to current user friends');

      print('Step 3: Adding to sender friends...');
      final senderFriendDoc = usersCol
          .doc(senderUserId)
          .collection('friends')
          .doc(currentUserId);
      await senderFriendDoc.set({'addedAt': FieldValue.serverTimestamp()});
      print('✓ Added to sender friends');

      print('✓ All steps completed successfully');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  /// Decline a friend request from [senderUserId]
  Future<void> declineFriendRequest(String currentUserId, String senderUserId) async {
    final requestDoc = usersCol
        .doc(currentUserId)
        .collection('friendRequests')
        .doc(senderUserId);

    await requestDoc.delete();
  }

  // ---------------------------
  // Friends
  // ---------------------------

      /// Remove a friend
  Future<void> removeFriend(String currentUserId, String friendUserId) async {
    final currentUserFriendRef =
        usersCol.doc(currentUserId).collection('friends').doc(friendUserId);
    final friendUserFriendRef =
        usersCol.doc(friendUserId).collection('friends').doc(currentUserId);

    final batch = FirebaseFirestore.instance.batch();

      // Remove the friend relationship in both directions
    batch.delete(currentUserFriendRef);
    batch.delete(friendUserFriendRef);

    await batch.commit();
  }

  /// Get current user's friends
  Future<List<UserProfile>> getFriends(String userId) async {
    final friendsSnap = await usersCol.doc(userId).collection('friends').get();

    if (friendsSnap.docs.isEmpty) return [];

    final friendIds = friendsSnap.docs.map((d) => d.id).toList();

    final usersSnap = await usersCol
        .where(FieldPath.documentId, whereIn: friendIds)
        .get();

    return usersSnap.docs.map((doc) => UserProfile.fromDoc(doc)).toList();
  }

  Future<List<UserProfile>> getFriendRequests(String currentUserId) async {
    print('🔍 Attempting to fetch friend requests for user: $currentUserId');

    try {
      // Explicitly print the full path
      final fullPath = 'users/$currentUserId/friendRequests';
      print('🔍 Full collection path: $fullPath');

      final requestsSnapshot = await usersCol
          .doc(currentUserId)
          .collection('friendRequests')
          .get();

      print('🔍 Total friend requests found: ${requestsSnapshot.docs.length}');

      // If no requests, return empty list
      if (requestsSnapshot.docs.isEmpty) {
        print('🔍 No friend requests found');
        return [];
      }

      // Log details of each request
      for (var doc in requestsSnapshot.docs) {
        print('🔍 Request Document ID: ${doc.id}');
        print('🔍 Request Document Data: ${doc.data()}');
      }

      // Fetch sender profiles
      final senderIds = requestsSnapshot.docs.map((doc) => doc.id).toList();

      final senderProfiles = await Future.wait(
        senderIds.map((id) => usersCol.doc(id).get())
      );

      final profiles = senderProfiles.map((doc) => UserProfile.fromDoc(doc)).toList();
      
      print('🔍 Number of sender profiles: ${profiles.length}');

      return profiles;
    } catch (e) {
      print('❌ Error in getFriendRequests: $e');
      return [];
    }
  }

  // ---------------------------
  // Search for users (public only)
  // ---------------------------

  // Search for other users
  Future<List<UserProfile>> searchUsers(String query) async {
    // Get all public users
    final snapshot = await usersCol
        .where('isPublic', isEqualTo: true)
        .get();

    final lowerQuery = query.toLowerCase();

    // Filter users by displayName or email containing the query
    final results = snapshot.docs.map((doc) => UserProfile.fromDoc(doc)).where((profile) {
      final displayNameMatch = profile.displayName?.toLowerCase().contains(lowerQuery) ?? false;
      final emailMatch = profile.email.toLowerCase().contains(lowerQuery);
      return displayNameMatch || emailMatch;
    }).toList();

    return results;
  }

  /// Gets a user profile by their Firebase UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      // FIXED: Changed from 'userProfiles' to 'users' to match other methods
      final doc = await usersCol.doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    } catch (e) {
      print('Error fetching profile by UID: $e');
      return null;
    }
  }

  /// Gets a user profile by username
  Future<UserProfile?> getUserProfileByUsername(String username) async {
    try {
      // FIXED: Changed from 'userProfiles' to 'users' to match other methods
      final snapshot = await usersCol
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return UserProfile.fromDoc(snapshot.docs.first);
    } catch (e) {
      print('Error fetching profile by username: $e');
      return null;
    }
  }

  // Media: create/get/search
  Future<String> createMediaItem(MediaItem item) async {
    final ref = await mediaCol.add(item.toMap());
    return ref.id;
  }

  Future<MediaItem?> getMediaItem(String mediaId) async {
    final doc = await mediaCol.doc(mediaId).get();
    if (!doc.exists) return null;
    return MediaItem.fromDoc(doc);
  }

  Future<MediaItem?> findMediaByTitleAndType(
    String title,
    MediaType type,
  ) async {
    final snapshot = await mediaCol
        .where('title', isEqualTo: title)
        .where('type', isEqualTo: type.name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return MediaItem.fromDoc(snapshot.docs.first);
  }

  Future<MediaItem> getOrCreateMedia({
    required String title,
    required MediaType type,
    String? creator,
  }) async {
    final existing = await findMediaByTitleAndType(title, type);
    if (existing != null) return existing;
    final now = DateTime.now();
    final dynamic item;
    if (type == MediaType.book) {
      item = BookItem(
        mediaId: 'temp',
        source: MediaSource.manual,
        title: title,
        subtitle: null,
        creator: creator,
        releaseDate: null,
        genres: const [],
        coverUrl: null,
        externalIds: const {},
        createdAt: now,
        updatedAt: now,
      );
    } else {
      item = MediaItem(
        mediaId: 'temp',
        type: type,
        source: MediaSource.manual,
        title: title,
        subtitle: null,
        creator: creator,
        releaseDate: null,
        genres: const [],
        coverUrl: null,
        externalIds: const {},
        createdAt: now,
        updatedAt: now,
      );
    }
    final id = await createMediaItem(item);
    final created = await getMediaItem(id);
    return created!;
  }

  Future<Map<String, MediaItem>> getMediaByIds(List<String> ids) async {
    final result = <String, MediaItem>{};
    if (ids.isEmpty) return result;
    // Firestore whereIn limit is 10
    const int batchSize = 10;
    for (var i = 0; i < ids.length; i += batchSize) {
      final slice = ids.sublist(
        i,
        i + batchSize > ids.length ? ids.length : i + batchSize,
      );
      final snap = await mediaCol
          .where(FieldPath.documentId, whereIn: slice)
          .get();
      for (final doc in snap.docs) {
        final item = MediaItem.fromDoc(doc);
        result[item.mediaId] = item;
      }
    }
    return result;
  }

  // Logs: create/update/delete/query by user
  Future<String> createLog(LogEntry log) async {
    final ref = await logsCol.add(log.toMap());
    return ref.id;
  }

  Future<List<LogEntry>> getUserLogs(String userId, {int limit = 50}) async {
    final snapshot = await logsCol
        .where('userId', isEqualTo: userId)
        .orderBy('consumedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((d) => LogEntry.fromDoc(d)).toList();
  }

  Future<void> updateLog(String logId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await logsCol.doc(logId).update(data);
  }

  Future<void> deleteLog(String collectionId) async {
    await logsCol.doc(collectionId).delete();
  }

  // ============================================================================
  // Collections CRUD Operations
  // ============================================================================

  /// Creates a new collection with the given name for the user
  Future<String> createCollectionByName(String userId, String name) async {
    final now = DateTime.now();
    final collection = CollectionModel(
      collectionId: 'temp', // Will be replaced by Firestore doc ID
      userId: userId,
      name: name,
      itemIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    final ref = await collectionsCol.add(collection.toMap());
    print('Created collection with ID: ${ref.id}');
    return ref.id;
  }

  /// Creates a collection from a CollectionModel object
  Future<String> createCollection(CollectionModel c) async {
    final ref = await collectionsCol.add(c.toMap());
    return ref.id;
  }

  /// Gets all collections for a specific user
  Future<List<CollectionModel>> getUserCollections(String userId) async {
    final snapshot = await collectionsCol
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => CollectionModel.fromDoc(d)).toList();
  }

  /// Gets a single collection by ID
  Future<CollectionModel?> getCollection(String collectionId) async {
    final doc = await collectionsCol.doc(collectionId).get();
    if (!doc.exists) return null;
    return CollectionModel.fromDoc(doc);
  }

  /// Updates a collection with arbitrary data
  Future<void> updateCollection(
    String collectionId,
    Map<String, dynamic> data,
  ) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await collectionsCol.doc(collectionId).update(data);
  }

  /// Renames a collection
  Future<void> renameCollection(String collectionId, String newName) async {
    await updateCollection(collectionId, {'name': newName});
  }

  /// Adds a media item to a collection
  Future<void> addMediaToCollection(String collectionId, String mediaId) async {
    await collectionsCol.doc(collectionId).update({
      'itemIds': FieldValue.arrayUnion([mediaId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes a media item from a collection
  Future<void> removeMediaFromCollection(String collectionId, String mediaId) async {
    await collectionsCol.doc(collectionId).update({
      'itemIds': FieldValue.arrayRemove([mediaId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reorders items in a collection (replaces the entire itemIds array)
  Future<void> reorderCollectionItems(String collectionId, List<String> newOrder) async {
    await updateCollection(collectionId, {'itemIds': newOrder});
  }

  /// Deletes a collection
  Future<void> deleteCollection(String collectionId) async {
    await collectionsCol.doc(collectionId).delete();
  }

  /// Checks if a media item is in a specific collection
  Future<bool> isMediaInCollection(String collectionId, String mediaId) async {
    final collection = await getCollection(collectionId);
    return collection?.itemIds.contains(mediaId) ?? false;
  }

  /// Gets all collections that contain a specific media item
  Future<List<CollectionModel>> getCollectionsContainingMedia(
    String userId,
    String mediaId,
  ) async {
    final snapshot = await collectionsCol
        .where('userId', isEqualTo: userId)
        .where('itemIds', arrayContains: mediaId)
        .get();
    return snapshot.docs.map((d) => CollectionModel.fromDoc(d)).toList();
  }

  // Bookmarks
  Future<List<BookmarkItem>> getUserBookmarks(String userId) async {
    final snapshot = await bookmarksCol
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => BookmarkItem.fromDoc(doc)).toList();
  }

  Future<bool> isBookmarked(String userId, String mediaId) async {
    final snapshot = await bookmarksCol
        .where('userId', isEqualTo: userId)
        .where('mediaId', isEqualTo: mediaId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<BookmarkItem> bookmarkMedia({
    required String userId,
    required MediaType mediaType,
    required String title,
    String? creator,
    String? subtitle,
    String? coverUrl,
    Map<String, dynamic> metadata = const {},
  }) async {
    final media = await getOrCreateMedia(
      title: title,
      type: mediaType,
      creator: creator,
    );

    final existing = await bookmarksCol
        .where('userId', isEqualTo: userId)
        .where('mediaId', isEqualTo: media.mediaId)
        .limit(1)
        .get();

    final now = DateTime.now();
    final payload = {
      'userId': userId,
      'mediaId': media.mediaId,
      'mediaType': media.type.name,
      'title': media.title,
      'creator': creator ?? media.creator,
      'subtitle': subtitle ?? media.subtitle,
      'coverUrl': coverUrl ?? media.coverUrl,
      'metadata': metadata,
      'updatedAt': Timestamp.fromDate(now),
    };

    DocumentReference<Map<String, dynamic>> ref;
    if (existing.docs.isNotEmpty) {
      ref = existing.docs.first.reference;
      await ref.set(payload, SetOptions(merge: true));
    } else {
      ref = await bookmarksCol.add({
        ...payload,
        'createdAt': Timestamp.fromDate(now),
      });
    }

    final fresh = await ref.get();
    return BookmarkItem.fromDoc(fresh);
  }

  Future<void> removeBookmarkByMedia(String userId, String mediaId) async {
    final existing = await bookmarksCol
        .where('userId', isEqualTo: userId)
        .where('mediaId', isEqualTo: mediaId)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) return;
    await existing.docs.first.reference.delete();
  }

  Future<void> removeBookmark(String bookmarkId) async {
    await bookmarksCol.doc(bookmarkId).delete();
  }
}
