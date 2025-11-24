// Contributors
// Julia: (1 hour) Media type now includes albums, songs, and shows

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lyfstyl/screens/flutter/packages/flutter/lib/rendering.dart';
import 'package:flutter/material.dart';
import "package:lyfstyl/screens/trending/trending_books_screen.dart";
import "package:lyfstyl/screens/trending/trending_movies_screen.dart";
import "package:lyfstyl/screens/trending/trending_music_screen.dart";
import 'package:lyfstyl/screens/music/music_search_screen.dart';
import 'package:lyfstyl/screens/trending/search_filter_books_screen.dart';
import 'package:lyfstyl/screens/movies/movie_search_screen.dart';



enum MediaType { 
  movie("Movies & Shows",Icons.movie,Color(0xFFFF6F61),"movies",TrendingMoviesScreen(),MovieSearchScreen()), 
  book("Books",Icons.menu_book, Color(0xFFFFC857),"books", TrendingBooksScreen(),SearchBooksScreen()),
   music("Music",Icons.music_note,Color(0xFF00C2A8),"tracks",TrendingMusicScreen(),MusicSearchScreen());    

      final String title;
      final IconData icon;
      final Color color;
      final String unit;
      final dynamic trending;
      final dynamic search;

      const MediaType(this.title, this.icon, this.color, this.unit, this.trending, this.search);
  }


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
    final type= _parseMediaType(data['type'] as String?);
    switch (type) {
      case MediaType.book:
        return BookItem.fromDoc(doc);
      case MediaType.movie:
        return FilmItem.fromDoc(doc);
      default:
        return MediaItem(
          mediaId: doc.id,
          type: type,
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
// SUBCLASSES STARTED
class FilmItem extends MediaItem {
  final String? director;

  FilmItem({
    required super.mediaId,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required super.source,
    super.subtitle,
    super.creator,
    super.releaseDate,
    super.genres,
    super.coverUrl,
    super.externalIds,
    this.director,
  }) : super(
    type: MediaType.movie,
  );

   @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['director'] = director;
    return map;
}

factory FilmItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FilmItem(
      mediaId: doc.id,
      title: data['title'] ?? '',
      source: MediaItem._parseMediaSource(data['source'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subtitle: data['subtitle'] as String?,
      creator: data['creator'] as String?,
      releaseDate: (data['releaseDate'] as Timestamp?)?.toDate(),
      genres: (data['genres'] as List<dynamic>? ?? []).cast<String>(),
      coverUrl: data['coverUrl'] as String?,
      externalIds: (data['externalIds'] as Map<String, dynamic>? ?? {}),
      director: data['director'] as String?,
    );
  }
}

class BookItem extends MediaItem {
  final int? pages;

  BookItem({
    required super.mediaId,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required super.source,
    super.subtitle,
    super.creator,
    super.releaseDate,
    super.genres,
    super.coverUrl,
    super.externalIds,
    this.pages,
  }) : super(
    type: MediaType.book,
  );

   @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['pages'] = pages;
    return map;
}

factory BookItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BookItem(
      mediaId: doc.id,
      title: data['title'] ?? '',
      source: MediaItem._parseMediaSource(data['source'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subtitle: data['subtitle'] as String?,
      creator: data['creator'] as String?,
      releaseDate: (data['releaseDate'] as Timestamp?)?.toDate(),
      genres: (data['genres'] as List<dynamic>? ?? []).cast<String>(),
      coverUrl: data['coverUrl'] as String?,
      externalIds: (data['externalIds'] as Map<String, dynamic>? ?? {}),
      pages: data['pages'] as int?,
    );
  }
}
