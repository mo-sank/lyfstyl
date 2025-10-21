import 'package:cloud_firestore/cloud_firestore.dart';
import 'media_item.dart';

class LogEntry {
  final String logId; // doc id
  final String userId;
  final String mediaId;
  final MediaType mediaType;
  final double? rating; // 0-5 or null
  final String? review;
  final List<String> tags;
  final DateTime consumedAt; // when user consumed the media
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Rich consumption data based on media type
  final Map<String, dynamic> consumptionData;

  LogEntry({
    required this.logId,
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    this.rating,
    this.review,
    this.tags = const [],
    required this.consumedAt,
    required this.createdAt,
    required this.updatedAt,
    this.consumptionData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaId': mediaId,
      'mediaType': mediaType.name,
      'rating': rating,
      'review': review,
      'tags': tags,
      'consumedAt': Timestamp.fromDate(consumedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'consumptionData': consumptionData,
    };
  }

  factory LogEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LogEntry(
      logId: doc.id,
      userId: (data['userId'] ?? '') as String,
      mediaId: (data['mediaId'] ?? '') as String,
      mediaType: _parseMediaType(data['mediaType'] as String?),
      rating: (data['rating'] as num?)?.toDouble(),
      review: data['review'] as String?,
      tags: (data['tags'] as List<dynamic>? ?? []).cast<String>(),
      consumedAt: (data['consumedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      consumptionData: (data['consumptionData'] as Map<String, dynamic>? ?? {}),
    );
  }

  static MediaType _parseMediaType(String? value) {
    switch (value) {
      case 'film':
        return MediaType.film;
      case 'book':
        return MediaType.book;
      case 'music':
        return MediaType.music;
      default:
        return MediaType.film;
    }
  }
}

// Music-specific consumption data
class MusicConsumptionData {
  final int? durationSeconds; // Song duration in seconds
  final int? playCount; // How many times user listened
  final String? album;
  final String? artist;
  final List<String> genres;
  final int? year;
  final String? mbid; // MusicBrainz ID
  final String? coverUrl;

  MusicConsumptionData({
    this.durationSeconds,
    this.playCount,
    this.album,
    this.artist,
    this.genres = const [],
    this.year,
    this.mbid,
    this.coverUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'durationSeconds': durationSeconds,
      'playCount': playCount,
      'album': album,
      'artist': artist,
      'genres': genres,
      'year': year,
      'mbid': mbid,
      'coverUrl': coverUrl,
    };
  }

  factory MusicConsumptionData.fromMap(Map<String, dynamic> data) {
    return MusicConsumptionData(
      durationSeconds: data['durationSeconds'] as int?,
      playCount: data['playCount'] as int?,
      album: data['album'] as String?,
      artist: data['artist'] as String?,
      genres: (data['genres'] as List<dynamic>? ?? []).cast<String>(),
      year: data['year'] as int?,
      mbid: data['mbid'] as String?,
      coverUrl: data['coverUrl'] as String?,
    );
  }

  // Helper methods for stats calculation
  Duration? get duration => durationSeconds != null ? Duration(seconds: durationSeconds!) : null;
  
  String get formattedDuration {
    if (durationSeconds == null) return 'Unknown';
    final d = Duration(seconds: durationSeconds!);
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }
}


