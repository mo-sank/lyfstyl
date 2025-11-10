import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> deleteUserData(String uid) async {
    await _deleteCollectionByUser('logs', uid);
    await _deleteCollectionByUser('bookmarks', uid);
    await _deleteCollectionByUser('collections', uid, ignorePermissionErrors: true);
    await _deleteCollectionByUser('mediaItems', uid, ignorePermissionErrors: true);
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> _deleteCollectionByUser(
    String collection,
    String uid, {
    bool ignorePermissionErrors = false,
  }) async {
    try {
      final snapshot = await _db
          .collection(collection)
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } on FirebaseException catch (e) {
      if (ignorePermissionErrors && e.code == 'permission-denied') {
        debugPrint(
            'Skipping $collection cleanup for $uid due to permission-denied.');
        return;
      }
      rethrow;
    }
  }
}

