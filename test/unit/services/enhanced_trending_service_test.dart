// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/services/enhanced_trending_service.dart';
import 'package:lyfstyl/models/enhanced_log_entry.dart';
import 'package:lyfstyl/models/media_item.dart';

void main() {
  group('EnhancedTrendingService', () {
    late EnhancedTrendingService service;

    setUp(() {
      service = EnhancedTrendingService();
    });

    group('filterByKeywords', () {
      late List<EnhancedTrendingItem> testItems;

      setUp(() {
        testItems = [
          EnhancedTrendingItem(
            id: '1',
            type: 'music',
            title: 'Bohemian Rhapsody',
            artist: 'Queen',
            sources: ['lastfm'],
            score: 100.0,
            musicData: MusicConsumptionData(
              artist: 'Queen',
              genres: ['Rock', 'Classic Rock'],
            ),
          ),
          EnhancedTrendingItem(
            id: '2',
            type: 'music',
            title: 'Billie Jean',
            artist: 'Michael Jackson',
            sources: ['lastfm'],
            score: 95.0,
            musicData: MusicConsumptionData(
              artist: 'Michael Jackson',
              genres: ['Pop', 'Dance'],
            ),
          ),
          EnhancedTrendingItem(
            id: '3',
            type: 'music',
            title: 'Stairway to Heaven',
            artist: 'Led Zeppelin',
            sources: ['lastfm'],
            score: 90.0,
            musicData: MusicConsumptionData(
              artist: 'Led Zeppelin',
              genres: ['Rock', 'Hard Rock'],
            ),
          ),
        ];
      });

      test('should return all items when no keywords provided', () {
        final result = service.filterByKeywords(testItems, []);
        expect(result.length, 3);
      });

      test('should filter by title', () {
        final result = service.filterByKeywords(testItems, ['bohemian']);
        expect(result.length, 1);
        expect(result.first.title, 'Bohemian Rhapsody');
      });

      test('should filter by artist', () {
        final result = service.filterByKeywords(testItems, ['queen']);
        expect(result.length, 1);
        expect(result.first.artist, 'Queen');
      });

      test('should filter by genre', () {
        final result = service.filterByKeywords(testItems, ['rock']);
        expect(result.length, 2);
        expect(result.map((i) => i.artist), containsAll(['Queen', 'Led Zeppelin']));
      });

      test('should handle multiple keywords', () {
        final result = service.filterByKeywords(testItems, ['rock', 'pop']);
        expect(result.length, 3);
      });

      test('should be case insensitive', () {
        final result = service.filterByKeywords(testItems, ['QUEEN']);
        expect(result.length, 1);
        expect(result.first.artist, 'Queen');
      });

      test('should handle empty keywords', () {
        final result = service.filterByKeywords(testItems, ['', '  ', 'queen']);
        expect(result.length, 1);
        expect(result.first.artist, 'Queen');
      });

      test('should return empty list when no matches', () {
        final result = service.filterByKeywords(testItems, ['jazz']);
        expect(result, isEmpty);
      });
    });

    group('createLogFromTrendingItem', () {
      late EnhancedTrendingItem testItem;

      setUp(() {
        testItem = EnhancedTrendingItem(
          id: 'song-123',
          type: 'music',
          title: 'Test Song',
          artist: 'Test Artist',
          coverUrl: 'https://example.com/cover.jpg',
          sources: ['lastfm'],
          score: 85.0,
          musicData: MusicConsumptionData(
            durationSeconds: 180,
            artist: 'Test Artist',
            album: 'Test Album',
            genres: ['Rock'],
            year: 2023,
          ),
        );
      });

      test('should create log entry with required fields', () {
        final log = service.createLogFromTrendingItem(
          userId: 'user-123',
          item: testItem,
        );

        expect(log.userId, 'user-123');
        expect(log.mediaId, 'song-123');
        expect(log.mediaType, MediaType.music);
        expect(log.rating, isNull);
        expect(log.review, isNull);
        expect(log.tags, isEmpty);
      });

      test('should create log entry with optional fields', () {
        final consumedAt = DateTime(2023, 12, 1);
        final log = service.createLogFromTrendingItem(
          userId: 'user-123',
          item: testItem,
          rating: 4.5,
          review: 'Great song!',
          tags: ['favorite', 'rock'],
          consumedAt: consumedAt,
        );

        expect(log.rating, 4.5);
        expect(log.review, 'Great song!');
        expect(log.tags, ['favorite', 'rock']);
        expect(log.consumedAt, consumedAt);
      });

      test('should include music consumption data', () {
        final log = service.createLogFromTrendingItem(
          userId: 'user-123',
          item: testItem,
        );

        expect(log.consumptionData['durationSeconds'], 180);
        expect(log.consumptionData['artist'], 'Test Artist');
        expect(log.consumptionData['album'], 'Test Album');
        expect(log.consumptionData['genres'], ['Rock']);
        expect(log.consumptionData['year'], 2023);
      });

      test('should set timestamps correctly', () {
        final beforeCreation = DateTime.now();
        final log = service.createLogFromTrendingItem(
          userId: 'user-123',
          item: testItem,
        );
        final afterCreation = DateTime.now();

        expect(log.createdAt.isAfter(beforeCreation) || log.createdAt.isAtSameMomentAs(beforeCreation), isTrue);
        expect(log.createdAt.isBefore(afterCreation) || log.createdAt.isAtSameMomentAs(afterCreation), isTrue);
        expect(log.updatedAt, log.createdAt);
      });

      test('should use current time as default consumedAt', () {
        final beforeCreation = DateTime.now();
        final log = service.createLogFromTrendingItem(
          userId: 'user-123',
          item: testItem,
        );
        final afterCreation = DateTime.now();

        expect(log.consumedAt.isAfter(beforeCreation) || log.consumedAt.isAtSameMomentAs(beforeCreation), isTrue);
        expect(log.consumedAt.isBefore(afterCreation) || log.consumedAt.isAtSameMomentAs(afterCreation), isTrue);
      });
    });
  });

  group('EnhancedTrendingItem', () {
    test('should create with all fields', () {
      final musicData = MusicConsumptionData(
        durationSeconds: 240,
        artist: 'Artist',
        genres: ['Pop'],
      );

      final item = EnhancedTrendingItem(
        id: 'item-1',
        type: 'music',
        title: 'Song Title',
        artist: 'Artist Name',
        coverUrl: 'https://example.com/cover.jpg',
        previewUrl: 'https://example.com/preview.mp3',
        sources: ['lastfm', 'spotify'],
        score: 92.5,
        musicData: musicData,
      );

      expect(item.id, 'item-1');
      expect(item.type, 'music');
      expect(item.title, 'Song Title');
      expect(item.artist, 'Artist Name');
      expect(item.coverUrl, 'https://example.com/cover.jpg');
      expect(item.previewUrl, 'https://example.com/preview.mp3');
      expect(item.sources, ['lastfm', 'spotify']);
      expect(item.score, 92.5);
      expect(item.musicData, musicData);
    });

    test('should handle optional fields', () {
      final musicData = MusicConsumptionData();
      
      final item = EnhancedTrendingItem(
        id: 'item-2',
        type: 'music',
        title: 'Another Song',
        artist: 'Another Artist',
        sources: ['lastfm'],
        score: 75.0,
        musicData: musicData,
      );

      expect(item.coverUrl, isNull);
      expect(item.previewUrl, isNull);
    });
  });
}