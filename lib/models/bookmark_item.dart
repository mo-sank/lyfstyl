import 'package:cloud_firestore/cloud_firestore.dart';
import 'media_item.dart';

class BookmarkItem {
  final String bookmarkId;
  final String userId;
  final String mediaId;
  final MediaType mediaType;
  final String title;
  final String? creator;
  final String? subtitle;
  final String? coverUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookmarkItem({
    required this.bookmarkId,
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    required this.title,
    this.creator,
    this.subtitle,
    this.coverUrl,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaId': mediaId,
      'mediaType': mediaType.name,
      'title': title,
      'creator': creator,
      'subtitle': subtitle,
      'coverUrl': coverUrl,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BookmarkItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BookmarkItem(
      bookmarkId: doc.id,
      userId: (data['userId'] ?? '') as String,
      mediaId: (data['mediaId'] ?? '') as String,
      mediaType: _parseMediaType(data['mediaType'] as String?),
      title: (data['title'] ?? '') as String,
      creator: data['creator'] as String?,
      subtitle: data['subtitle'] as String?,
      coverUrl: data['coverUrl'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static MediaType _parseMediaType(String? value) {
    switch (value) {
      case 'movie':
        return MediaType.movie;
      case 'book':
        return MediaType.book;
      case 'music':
        return MediaType.music;
      default:
        return MediaType.movie;
    }
  }
}
