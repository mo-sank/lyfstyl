// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/services/music_trending_service.dart';

void main() {
  group('TrendingService', () {
    late MusicTrendingService service;

    setUp(() {
      service = MusicTrendingService();
    });

    group('filterByKeywords', () {
      late List<MusicTrendingItem> testItems;

      setUp(() {
        testItems = [
          MusicTrendingItem(
            id: '1',
            type: 'music',
            title: 'Bohemian Rhapsody',
            artist: 'Queen',
            sources: ['lastfm'],
            score: 100.0,
          ),
          MusicTrendingItem(
            id: '2',
            type: 'music',
            title: 'Billie Jean',
            artist: 'Michael Jackson',
            sources: ['lastfm'],
            score: 95.0,
          ),
          MusicTrendingItem(
            id: '3',
            type: 'music',
            title: 'Stairway to Heaven',
            artist: 'Led Zeppelin',
            sources: ['lastfm'],
            score: 90.0,
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

      test('should handle multiple keywords', () {
        final result = service.filterByKeywords(testItems, ['queen', 'jackson']);
        expect(result.length, 2);
        expect(result.map((i) => i.artist), containsAll(['Queen', 'Michael Jackson']));
      });

      test('should be case insensitive', () {
        final result = service.filterByKeywords(testItems, ['QUEEN']);
        expect(result.length, 1);
        expect(result.first.artist, 'Queen');
      });

      test('should handle empty and whitespace keywords', () {
        final result = service.filterByKeywords(testItems, ['', '  ', 'queen']);
        expect(result.length, 1);
        expect(result.first.artist, 'Queen');
      });

      test('should return empty list when no matches', () {
        final result = service.filterByKeywords(testItems, ['jazz']);
        expect(result, isEmpty);
      });

      test('should match partial words', () {
        final result = service.filterByKeywords(testItems, ['jean']);
        expect(result.length, 1);
        expect(result.first.title, 'Billie Jean');
      });
    });

    test('should handle TrendingItem creation with all fields', () {
      final item = MusicTrendingItem(
        id: 'test-id',
        type: 'music',
        title: 'Test Song',
        artist: 'Test Artist',
        coverUrl: 'https://example.com/cover.jpg',
        previewUrl: 'https://example.com/preview.mp3',
        sources: ['lastfm', 'spotify'],
        score: 85.5,
        musicData: {'genre': 'rock', 'year': 2023},
      );

      expect(item.id, 'test-id');
      expect(item.type, 'music');
      expect(item.title, 'Test Song');
      expect(item.artist, 'Test Artist');
      expect(item.coverUrl, 'https://example.com/cover.jpg');
      expect(item.previewUrl, 'https://example.com/preview.mp3');
      expect(item.sources, ['lastfm', 'spotify']);
      expect(item.score, 85.5);
      expect(item.musicData['genre'], 'rock');
      expect(item.musicData['year'], 2023);
    });

    test('should handle TrendingItem creation with minimal fields', () {
      final item = MusicTrendingItem(
        id: 'minimal-id',
        type: 'music',
        title: 'Minimal Song',
        artist: 'Minimal Artist',
        sources: ['lastfm'],
        score: 50.0,
      );

      expect(item.coverUrl, isNull);
      expect(item.previewUrl, isNull);
      expect(item.musicData, isEmpty);
    });
  });
}