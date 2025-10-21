// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/models/log_entry.dart';
import 'package:lyfstyl/models/media_item.dart';

void main() {
  group('LogEntry', () {
    test('should create LogEntry with required fields', () {
      final now = DateTime.now();
      final log = LogEntry(
        logId: 'log-id',
        userId: 'user-id',
        mediaId: 'media-id',
        mediaType: MediaType.film,
        consumedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(log.logId, 'log-id');
      expect(log.userId, 'user-id');
      expect(log.mediaType, MediaType.film);
      expect(log.rating, isNull);
      expect(log.tags, isEmpty);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final log = LogEntry(
        logId: 'log-id',
        userId: 'user-id',
        mediaId: 'media-id',
        mediaType: MediaType.book,
        rating: 4.5,
        review: 'Great book!',
        tags: ['fiction', 'drama'],
        consumedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final map = log.toMap();
      expect(map['userId'], 'user-id');
      expect(map['mediaType'], 'book');
      expect(map['rating'], 4.5);
      expect(map['review'], 'Great book!');
      expect(map['tags'], ['fiction', 'drama']);
    });


  });

  group('MusicConsumptionData', () {
    test('should create with all fields', () {
      final data = MusicConsumptionData(
        durationSeconds: 180,
        playCount: 5,
        album: 'Test Album',
        artist: 'Test Artist',
        genres: ['Rock', 'Pop'],
        year: 2023,
      );

      expect(data.durationSeconds, 180);
      expect(data.playCount, 5);
      expect(data.album, 'Test Album');
      expect(data.artist, 'Test Artist');
      expect(data.genres, ['Rock', 'Pop']);
      expect(data.year, 2023);
    });

    test('should format duration correctly', () {
      final shortData = MusicConsumptionData(durationSeconds: 90);
      expect(shortData.formattedDuration, '1:30');

      final longData = MusicConsumptionData(durationSeconds: 3665);
      expect(longData.formattedDuration, '1:01:05');

      final nullData = MusicConsumptionData();
      expect(nullData.formattedDuration, 'Unknown');
    });

    test('should convert to/from map', () {
      final data = MusicConsumptionData(
        durationSeconds: 240,
        artist: 'Test Artist',
        genres: ['Jazz'],
      );

      final map = data.toMap();
      final restored = MusicConsumptionData.fromMap(map);

      expect(restored.durationSeconds, 240);
      expect(restored.artist, 'Test Artist');
      expect(restored.genres, ['Jazz']);
    });

    test('should get duration as Duration object', () {
      final data = MusicConsumptionData(durationSeconds: 120);
      expect(data.duration, Duration(seconds: 120));

      final nullData = MusicConsumptionData();
      expect(nullData.duration, isNull);
    });
  });
}