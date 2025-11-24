// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/models/media_item.dart';

void main() {
  group('MediaItem', () {
    test('should create MediaItem with required fields', () {
      final now = DateTime.now();
      final item = MediaItem(
        mediaId: 'test-id',
        type: MediaType.movie,
        source: MediaSource.manual,
        title: 'Test Movie',
        createdAt: now,
        updatedAt: now,
      );

      expect(item.mediaId, 'test-id');
      expect(item.type, MediaType.movie);
      expect(item.title, 'Test Movie');
      expect(item.genres, isEmpty);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final item = MediaItem(
        mediaId: 'test-id',
        type: MediaType.book,
        source: MediaSource.goodreads,
        title: 'Test Book',
        creator: 'Test Author',
        genres: ['Fiction', 'Drama'],
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toMap();
      expect(map['type'], 'book');
      expect(map['source'], 'goodreads');
      expect(map['title'], 'Test Book');
      expect(map['creator'], 'Test Author');
      expect(map['genres'], ['Fiction', 'Drama']);
    });


  });

  group('FilmItem', () {
    test('should create FilmItem with director', () {
      final now = DateTime.now();
      final film = FilmItem(
        mediaId: 'film-id',
        title: 'Test Film',
        source: MediaSource.letterboxd,
        director: 'Test Director',
        createdAt: now,
        updatedAt: now,
      );

      expect(film.type, MediaType.movie);
      expect(film.director, 'Test Director');
    });

    test('should include director in toMap', () {
      final now = DateTime.now();
      final film = FilmItem(
        mediaId: 'film-id',
        title: 'Test Film',
        source: MediaSource.manual,
        director: 'Test Director',
        createdAt: now,
        updatedAt: now,
      );

      final map = film.toMap();
      expect(map['director'], 'Test Director');
      expect(map['type'], 'film');
    });
  });

  group('BookItem', () {
    test('should create BookItem with pages', () {
      final now = DateTime.now();
      final book = BookItem(
        mediaId: 'book-id',
        title: 'Test Book',
        source: MediaSource.goodreads,
        pages: 300,
        createdAt: now,
        updatedAt: now,
      );

      expect(book.type, MediaType.book);
      expect(book.pages, 300);
    });

    test('should include pages in toMap', () {
      final now = DateTime.now();
      final book = BookItem(
        mediaId: 'book-id',
        title: 'Test Book',
        source: MediaSource.manual,
        pages: 250,
        createdAt: now,
        updatedAt: now,
      );

      final map = book.toMap();
      expect(map['pages'], 250);
      expect(map['type'], 'book');
    });
  });
}