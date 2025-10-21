// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/models/trending_aggregate.dart';

void main() {
  group('TrendingAggregate', () {
    test('should create trending aggregate with required fields', () {
      final now = DateTime.now();
      final periodStart = DateTime(2023, 12, 1);
      
      final aggregate = TrendingAggregate(
        aggregateId: 'trending-id',
        window: TrendingWindow.day,
        periodStart: periodStart,
        type: 'film',
        generatedAt: now,
      );

      expect(aggregate.aggregateId, 'trending-id');
      expect(aggregate.window, TrendingWindow.day);
      expect(aggregate.periodStart, periodStart);
      expect(aggregate.type, 'film');
      expect(aggregate.genre, isNull);
      expect(aggregate.topMediaIds, isEmpty);
      expect(aggregate.generatedAt, now);
    });

    test('should create trending aggregate with all fields', () {
      final now = DateTime.now();
      final periodStart = DateTime(2023, 12, 1);
      
      final aggregate = TrendingAggregate(
        aggregateId: 'trending-id',
        window: TrendingWindow.week,
        periodStart: periodStart,
        type: 'music',
        genre: 'rock',
        topMediaIds: ['song1', 'song2', 'song3'],
        generatedAt: now,
      );

      expect(aggregate.window, TrendingWindow.week);
      expect(aggregate.type, 'music');
      expect(aggregate.genre, 'rock');
      expect(aggregate.topMediaIds, ['song1', 'song2', 'song3']);
      expect(aggregate.topMediaIds.length, 3);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final periodStart = DateTime(2023, 12, 1);
      
      final aggregate = TrendingAggregate(
        aggregateId: 'trending-id',
        window: TrendingWindow.week,
        periodStart: periodStart,
        type: 'book',
        genre: 'fiction',
        topMediaIds: ['book1', 'book2'],
        generatedAt: now,
      );

      final map = aggregate.toMap();
      expect(map['window'], 'week');
      expect(map['type'], 'book');
      expect(map['genre'], 'fiction');
      expect(map['topMediaIds'], ['book1', 'book2']);
      expect(map.containsKey('aggregateId'), false);
    });

    test('should handle different trending windows', () {
      final now = DateTime.now();
      final periodStart = DateTime(2023, 12, 1);
      
      final dayAggregate = TrendingAggregate(
        aggregateId: 'day-id',
        window: TrendingWindow.day,
        periodStart: periodStart,
        type: 'film',
        generatedAt: now,
      );

      final weekAggregate = TrendingAggregate(
        aggregateId: 'week-id',
        window: TrendingWindow.week,
        periodStart: periodStart,
        type: 'film',
        generatedAt: now,
      );

      expect(dayAggregate.toMap()['window'], 'day');
      expect(weekAggregate.toMap()['window'], 'week');
    });

    test('should handle empty top media IDs', () {
      final now = DateTime.now();
      final aggregate = TrendingAggregate(
        aggregateId: 'empty-trending',
        window: TrendingWindow.day,
        periodStart: now,
        type: 'film',
        generatedAt: now,
      );

      final map = aggregate.toMap();
      expect(map['topMediaIds'], isEmpty);
    });

    test('should handle different media types', () {
      final now = DateTime.now();
      
      final filmAggregate = TrendingAggregate(
        aggregateId: 'film-trending',
        window: TrendingWindow.day,
        periodStart: now,
        type: 'film',
        generatedAt: now,
      );

      final bookAggregate = TrendingAggregate(
        aggregateId: 'book-trending',
        window: TrendingWindow.week,
        periodStart: now,
        type: 'book',
        generatedAt: now,
      );

      final musicAggregate = TrendingAggregate(
        aggregateId: 'music-trending',
        window: TrendingWindow.day,
        periodStart: now,
        type: 'music',
        generatedAt: now,
      );

      expect(filmAggregate.type, 'film');
      expect(bookAggregate.type, 'book');
      expect(musicAggregate.type, 'music');
    });

    test('should handle optional genre field', () {
      final now = DateTime.now();
      
      final withGenre = TrendingAggregate(
        aggregateId: 'with-genre',
        window: TrendingWindow.day,
        periodStart: now,
        type: 'film',
        genre: 'action',
        generatedAt: now,
      );

      final withoutGenre = TrendingAggregate(
        aggregateId: 'without-genre',
        window: TrendingWindow.day,
        periodStart: now,
        type: 'film',
        generatedAt: now,
      );

      expect(withGenre.toMap()['genre'], 'action');
      expect(withoutGenre.toMap()['genre'], isNull);
    });
  });

  group('TrendingWindow enum', () {
    test('should have correct values', () {
      expect(TrendingWindow.day.name, 'day');
      expect(TrendingWindow.week.name, 'week');
    });
  });
}