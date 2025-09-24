import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionModel {
  final String collectionId; // doc id
  final String userId;
  final String name;
  final List<String> itemIds; // ordered list of mediaIds
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectionModel({
    required this.collectionId,
    required this.userId,
    required this.name,
    this.itemIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'itemIds': itemIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CollectionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CollectionModel(
      collectionId: doc.id,
      userId: (data['userId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      itemIds: (data['itemIds'] as List<dynamic>? ?? []).cast<String>(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
