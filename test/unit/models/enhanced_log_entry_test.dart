// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/models/enhanced_log_entry.dart';

void main() {
  group('Enhanced MusicConsumptionData', () {
    test('should create with audio features', () {
      final data = MusicConsumptionData(
        durationSeconds: 180,
        artist: 'Test Artist',
        energy: 0.8,
        danceability: 0.7,
        valence: 0.6,
        tempo: 120.5,
        instruments: ['guitar', 'drums'],
        language: 'en',
      );

      expect(data.energy, 0.8);
      expect(data.danceability, 0.7);
      expect(data.valence, 0.6);
      expect(data.tempo, 120.5);
      expect(data.instruments, ['guitar', 'drums']);
      expect(data.language, 'en');
    });

    test('should serialize enhanced fields to map', () {
      final data = MusicConsumptionData(
        energy: 0.9,
        danceability: 0.5,
        valence: 0.3,
        tempo: 140.0,
        instruments: ['piano'],
      );

      final map = data.toMap();
      expect(map['energy'], 0.9);
      expect(map['danceability'], 0.5);
      expect(map['valence'], 0.3);
      expect(map['tempo'], 140.0);
      expect(map['instruments'], ['piano']);
    });

    test('should restore from map with enhanced fields', () {
      final map = {
        'durationSeconds': 200,
        'artist': 'Artist',
        'energy': 0.7,
        'danceability': 0.8,
        'valence': 0.4,
        'tempo': 130.0,
        'instruments': ['bass', 'synth'],
        'language': 'es',
      };

      final data = MusicConsumptionData.fromMap(map);
      expect(data.energy, 0.7);
      expect(data.danceability, 0.8);
      expect(data.valence, 0.4);
      expect(data.tempo, 130.0);
      expect(data.instruments, ['bass', 'synth']);
      expect(data.language, 'es');
    });
  });

  group('FilmConsumptionData', () {
    test('should create with film-specific data', () {
      final data = FilmConsumptionData(
        durationMinutes: 120,
        director: 'Test Director',
        cast: ['Actor 1', 'Actor 2'],
        genres: ['Action', 'Drama'],
        year: 2023,
        imdbId: 'tt1234567',
        language: 'en',
        country: 'US',
        imdbRating: 8.5,
        mpaaRating: 'PG-13',
        awards: ['Oscar', 'Golden Globe'],
      );

      expect(data.durationMinutes, 120);
      expect(data.director, 'Test Director');
      expect(data.cast, ['Actor 1', 'Actor 2']);
      expect(data.genres, ['Action', 'Drama']);
      expect(data.imdbRating, 8.5);
      expect(data.awards, ['Oscar', 'Golden Globe']);
    });

    test('should format duration correctly', () {
      final shortFilm = FilmConsumptionData(durationMinutes: 45);
      expect(shortFilm.formattedDuration, '45m');

      final longFilm = FilmConsumptionData(durationMinutes: 150);
      expect(longFilm.formattedDuration, '2h 30m');

      final exactHour = FilmConsumptionData(durationMinutes: 120);
      expect(exactHour.formattedDuration, '2h 0m');

      final nullDuration = FilmConsumptionData();
      expect(nullDuration.formattedDuration, 'Unknown');
    });

    test('should convert to/from map', () {
      final data = FilmConsumptionData(
        durationMinutes: 90,
        director: 'Director',
        cast: ['Lead Actor'],
        imdbRating: 7.5,
      );

      final map = data.toMap();
      final restored = FilmConsumptionData.fromMap(map);

      expect(restored.durationMinutes, 90);
      expect(restored.director, 'Director');
      expect(restored.cast, ['Lead Actor']);
      expect(restored.imdbRating, 7.5);
    });

    test('should get duration as Duration object', () {
      final data = FilmConsumptionData(durationMinutes: 105);
      expect(data.duration, Duration(minutes: 105));

      final nullData = FilmConsumptionData();
      expect(nullData.duration, isNull);
    });
  });

  group('BookConsumptionData', () {
    test('should create with book-specific data', () {
      final data = BookConsumptionData(
        pages: 350,
        author: 'Test Author',
        isbn: '978-0123456789',
        genres: ['Fiction', 'Mystery'],
        year: 2022,
        language: 'en',
        publisher: 'Test Publisher',
        averageRating: 4.2,
        ratingsCount: 1500,
        awards: ['Hugo Award'],
        series: 'Test Series',
        seriesOrder: 2,
      );

      expect(data.pages, 350);
      expect(data.author, 'Test Author');
      expect(data.isbn, '978-0123456789');
      expect(data.genres, ['Fiction', 'Mystery']);
      expect(data.averageRating, 4.2);
      expect(data.ratingsCount, 1500);
      expect(data.series, 'Test Series');
      expect(data.seriesOrder, 2);
    });

    test('should convert to/from map', () {
      final data = BookConsumptionData(
        pages: 200,
        author: 'Author Name',
        genres: ['Non-fiction'],
        averageRating: 3.8,
        series: 'Book Series',
      );

      final map = data.toMap();
      final restored = BookConsumptionData.fromMap(map);

      expect(restored.pages, 200);
      expect(restored.author, 'Author Name');
      expect(restored.genres, ['Non-fiction']);
      expect(restored.averageRating, 3.8);
      expect(restored.series, 'Book Series');
    });

    test('should handle null values', () {
      final data = BookConsumptionData();
      final map = data.toMap();

      expect(map['pages'], isNull);
      expect(map['author'], isNull);
      expect(map['isbn'], isNull);
      expect(map['genres'], isEmpty);
      expect(map['awards'], isEmpty);
    });
  });
}