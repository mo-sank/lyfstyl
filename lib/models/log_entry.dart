import 'package:cloud_firestore/cloud_firestore.dart';

class LogEntry {
  final String logId; // doc id
  final String userId;
  final String mediaId;
  final double? rating; // 0-5 or null
  final String? review;
  final List<String> tags;
  final DateTime consumedAt; // when user consumed the media
  final DateTime createdAt;
  final DateTime updatedAt;

  LogEntry({
    required this.logId,
    required this.userId,
    required this.mediaId,
    this.rating,
    this.review,
    this.tags = const [],
    required this.consumedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaId': mediaId,
      'rating': rating,
      'review': review,
      'tags': tags,
      'consumedAt': Timestamp.fromDate(consumedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LogEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LogEntry(
      logId: doc.id,
      userId: (data['userId'] ?? '') as String,
      mediaId: (data['mediaId'] ?? '') as String,
      rating: (data['rating'] as num?)?.toDouble(),
      review: data['review'] as String?,
      tags: (data['tags'] as List<dynamic>? ?? []).cast<String>(),
      consumedAt: (data['consumedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
