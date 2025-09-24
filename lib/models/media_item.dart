import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType { film, book, music }

enum MediaSource { manual, letterboxd, goodreads, spotify, other }

class MediaItem {
  final String mediaId; // doc id
  final MediaType type;
  final MediaSource source;
  final String title;
  final String? subtitle; // e.g., album, series
  final String? creator; // director/author/artist
  final DateTime? releaseDate;
  final List<String> genres;
  final String? coverUrl;
  final Map<String, dynamic> externalIds; // e.g., imdbId, goodreadsId, spotifyId
  final DateTime createdAt;
  final DateTime updatedAt;

  MediaItem({
    required this.mediaId,
    required this.type,
    required this.source,
    required this.title,
    this.subtitle,
    this.creator,
    this.releaseDate,
    this.genres = const [],
    this.coverUrl,
    this.externalIds = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'source': source.name,
      'title': title,
      'subtitle': subtitle,
      'creator': creator,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'genres': genres,
      'coverUrl': coverUrl,
      'externalIds': externalIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MediaItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MediaItem(
      mediaId: doc.id,
      type: _parseMediaType(data['type'] as String?),
      source: _parseMediaSource(data['source'] as String?),
      title: (data['title'] ?? '') as String,
      subtitle: data['subtitle'] as String?,
      creator: data['creator'] as String?,
      releaseDate: (data['releaseDate'] as Timestamp?)?.toDate(),
      genres: (data['genres'] as List<dynamic>? ?? []).cast<String>(),
      coverUrl: data['coverUrl'] as String?,
      externalIds: (data['externalIds'] as Map<String, dynamic>? ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

  static MediaSource _parseMediaSource(String? value) {
    switch (value) {
      case 'manual':
        return MediaSource.manual;
      case 'letterboxd':
        return MediaSource.letterboxd;
      case 'goodreads':
        return MediaSource.goodreads;
      case 'spotify':
        return MediaSource.spotify;
      default:
        return MediaSource.other;
    }
  }
}
