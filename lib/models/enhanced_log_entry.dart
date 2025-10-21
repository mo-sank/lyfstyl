import 'package:cloud_firestore/cloud_firestore.dart';
import 'media_item.dart';

// Base log entry with common fields
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
  
  // Media-specific consumption data
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
  final double? energy; // 0-1 energy level
  final double? danceability; // 0-1 danceability
  final double? valence; // 0-1 mood (positive/negative)
  final double? tempo; // BPM
  final List<String> instruments;
  final String? language;

  MusicConsumptionData({
    this.durationSeconds,
    this.playCount,
    this.album,
    this.artist,
    this.genres = const [],
    this.year,
    this.mbid,
    this.energy,
    this.danceability,
    this.valence,
    this.tempo,
    this.instruments = const [],
    this.language,
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
      'energy': energy,
      'danceability': danceability,
      'valence': valence,
      'tempo': tempo,
      'instruments': instruments,
      'language': language,
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
      energy: (data['energy'] as num?)?.toDouble(),
      danceability: (data['danceability'] as num?)?.toDouble(),
      valence: (data['valence'] as num?)?.toDouble(),
      tempo: (data['tempo'] as num?)?.toDouble(),
      instruments: (data['instruments'] as List<dynamic>? ?? []).cast<String>(),
      language: data['language'] as String?,
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

// Film-specific consumption data
class FilmConsumptionData {
  final int? durationMinutes; // Film duration in minutes
  final String? director;
  final List<String> cast;
  final List<String> genres;
  final int? year;
  final String? imdbId;
  final String? language;
  final String? country;
  final double? imdbRating;
  final String? mpaaRating;
  final List<String> awards;

  FilmConsumptionData({
    this.durationMinutes,
    this.director,
    this.cast = const [],
    this.genres = const [],
    this.year,
    this.imdbId,
    this.language,
    this.country,
    this.imdbRating,
    this.mpaaRating,
    this.awards = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'durationMinutes': durationMinutes,
      'director': director,
      'cast': cast,
      'genres': genres,
      'year': year,
      'imdbId': imdbId,
      'language': language,
      'country': country,
      'imdbRating': imdbRating,
      'mpaaRating': mpaaRating,
      'awards': awards,
    };
  }

  factory FilmConsumptionData.fromMap(Map<String, dynamic> data) {
    return FilmConsumptionData(
      durationMinutes: data['durationMinutes'] as int?,
      director: data['director'] as String?,
      cast: (data['cast'] as List<dynamic>? ?? []).cast<String>(),
      genres: (data['genres'] as List<dynamic>? ?? []).cast<String>(),
      year: data['year'] as int?,
      imdbId: data['imdbId'] as String?,
      language: data['language'] as String?,
      country: data['country'] as String?,
      imdbRating: (data['imdbRating'] as num?)?.toDouble(),
      mpaaRating: data['mpaaRating'] as String?,
      awards: (data['awards'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Duration? get duration => durationMinutes != null ? Duration(minutes: durationMinutes!) : null;
  
  String get formattedDuration {
    if (durationMinutes == null) return 'Unknown';
    final d = Duration(minutes: durationMinutes!);
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    } else {
      return '${d.inMinutes}m';
    }
  }
}

// Book-specific consumption data
class BookConsumptionData {
  final int? pages;
  final String? author;
  final String? isbn;
  final List<String> genres;
  final int? year;
  final String? language;
  final String? publisher;
  final double? averageRating;
  final int? ratingsCount;
  final List<String> awards;
  final String? series;
  final int? seriesOrder;

  BookConsumptionData({
    this.pages,
    this.author,
    this.isbn,
    this.genres = const [],
    this.year,
    this.language,
    this.publisher,
    this.averageRating,
    this.ratingsCount,
    this.awards = const [],
    this.series,
    this.seriesOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'pages': pages,
      'author': author,
      'isbn': isbn,
      'genres': genres,
      'year': year,
      'language': language,
      'publisher': publisher,
      'averageRating': averageRating,
      'ratingsCount': ratingsCount,
      'awards': awards,
      'series': series,
      'seriesOrder': seriesOrder,
    };
  }

  factory BookConsumptionData.fromMap(Map<String, dynamic> data) {
    return BookConsumptionData(
      pages: data['pages'] as int?,
      author: data['author'] as String?,
      isbn: data['isbn'] as String?,
      genres: (data['genres'] as List<dynamic>? ?? []).cast<String>(),
      year: data['year'] as int?,
      language: data['language'] as String?,
      publisher: data['publisher'] as String?,
      averageRating: (data['averageRating'] as num?)?.toDouble(),
      ratingsCount: data['ratingsCount'] as int?,
      awards: (data['awards'] as List<dynamic>? ?? []).cast<String>(),
      series: data['series'] as String?,
      seriesOrder: data['seriesOrder'] as int?,
    );
  }
}
