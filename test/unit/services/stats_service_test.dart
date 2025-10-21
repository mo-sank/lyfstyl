// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/services/stats_service.dart';
import 'package:lyfstyl/models/log_entry.dart';
import 'package:lyfstyl/models/media_item.dart';

void main() {
  group('StatsService', () {
    late StatsService service;

    setUp(() {
      service = StatsService();
    });

    test('should return empty stats for empty logs', () {
      final stats = service.calculateUserStats([]);

      expect(stats.totalItemsLogged, 0);
      expect(stats.totalMusicMinutes, 0);
      expect(stats.averageRating, 0.0);
      expect(stats.topGenres, isEmpty);
      expect(stats.topArtists, isEmpty);
      expect(stats.mediaTypeCounts, isEmpty);
    });

    test('should calculate basic stats correctly', () {
      final now = DateTime.now();
      final logs = [
        LogEntry(
          logId: 'log1',
          userId: 'user1',
          mediaId: 'media1',
          mediaType: MediaType.film,
          rating: 4.0,
          consumedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        LogEntry(
          logId: 'log2',
          userId: 'user1',
          mediaId: 'media2',
          mediaType: MediaType.book,
          rating: 5.0,
          consumedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final stats = service.calculateUserStats(logs);

      expect(stats.totalItemsLogged, 2);
      expect(stats.averageRating, 4.5);
      expect(stats.mediaTypeCounts[MediaType.film], 1);
      expect(stats.mediaTypeCounts[MediaType.book], 1);
    });

    test('should calculate music stats from consumption data', () {
      final now = DateTime.now();
      final musicLog = LogEntry(
        logId: 'music1',
        userId: 'user1',
        mediaId: 'song1',
        mediaType: MediaType.music,
        rating: 4.0,
        consumedAt: now,
        createdAt: now,
        updatedAt: now,
        consumptionData: {
          'durationSeconds': 180, // 3 minutes
          'artist': 'Test Artist',
          'genres': ['Rock', 'Pop'],
          'year': 2023,
        },
      );

      final stats = service.calculateUserStats([musicLog]);

      expect(stats.totalMusicMinutes, 3);
      expect(stats.artistCounts['Test Artist'], 1);
      expect(stats.genreCounts['Rock'], 1);
      expect(stats.genreCounts['Pop'], 1);
      expect(stats.yearCounts['2023'], 1);
      expect(stats.topArtists, contains('Test Artist'));
      expect(stats.topGenres, containsAll(['Rock', 'Pop']));
    });

    test('should handle logs without ratings', () {
      final now = DateTime.now();
      final logs = [
        LogEntry(
          logId: 'log1',
          userId: 'user1',
          mediaId: 'media1',
          mediaType: MediaType.film,
          consumedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        LogEntry(
          logId: 'log2',
          userId: 'user1',
          mediaId: 'media2',
          mediaType: MediaType.book,
          rating: 3.0,
          consumedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final stats = service.calculateUserStats(logs);

      expect(stats.totalItemsLogged, 2);
      expect(stats.averageRating, 3.0);
    });

    test('should sort top genres and artists by count', () {
      final now = DateTime.now();
      final logs = [
        LogEntry(
          logId: 'music1',
          userId: 'user1',
          mediaId: 'song1',
          mediaType: MediaType.music,
          consumedAt: now,
          createdAt: now,
          updatedAt: now,
          consumptionData: {
            'artist': 'Artist A',
            'genres': ['Rock'],
          },
        ),
        LogEntry(
          logId: 'music2',
          userId: 'user1',
          mediaId: 'song2',
          mediaType: MediaType.music,
          consumedAt: now,
          createdAt: now,
          updatedAt: now,
          consumptionData: {
            'artist': 'Artist B',
            'genres': ['Pop'],
          },
        ),
        LogEntry(
          logId: 'music3',
          userId: 'user1',
          mediaId: 'song3',
          mediaType: MediaType.music,
          consumedAt: now,
          createdAt: now,
          updatedAt: now,
          consumptionData: {
            'artist': 'Artist A', // Artist A appears twice
            'genres': ['Rock'], // Rock appears twice
          },
        ),
      ];

      final stats = service.calculateUserStats(logs);

      expect(stats.topArtists.first, 'Artist A');
      expect(stats.topGenres.first, 'Rock');
      expect(stats.artistCounts['Artist A'], 2);
      expect(stats.artistCounts['Artist B'], 1);
    });

    group('formatDuration', () {
      test('should format minutes correctly', () {
        expect(service.formatDuration(30), '30 minutes');
        expect(service.formatDuration(59), '59 minutes');
      });

      test('should format hours correctly', () {
        expect(service.formatDuration(60), '1h');
        expect(service.formatDuration(90), '1h 30m');
        expect(service.formatDuration(120), '2h');
      });

      test('should format days correctly', () {
        expect(service.formatDuration(1440), '1d'); // 24 hours
        expect(service.formatDuration(1500), '1d 1h'); // 25 hours
        expect(service.formatDuration(2880), '2d'); // 48 hours
      });
    });
  });
}