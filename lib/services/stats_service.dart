import '../models/log_entry.dart';
import '../models/media_item.dart';

class UserStats {
  final int totalItemsLogged;
  final int totalMusicMinutes;
  final int totalFilmMinutes;
  final int totalBookPages;
  final Map<String, int> genreCounts;
  final Map<String, int> artistCounts;
  final Map<String, int> yearCounts;
  final double averageRating;
  final List<String> topGenres;
  final List<String> topArtists;
  final Map<MediaType, int> mediaTypeCounts;

  UserStats({
    required this.totalItemsLogged,
    required this.totalMusicMinutes,
    required this.totalFilmMinutes,
    required this.totalBookPages,
    required this.genreCounts,
    required this.artistCounts,
    required this.yearCounts,
    required this.averageRating,
    required this.topGenres,
    required this.topArtists,
    required this.mediaTypeCounts,
  });
}

class StatsService {
  // Calculate comprehensive user stats from logs
  UserStats calculateUserStats(List<LogEntry> logs) {
    if (logs.isEmpty) {
      return UserStats(
        totalItemsLogged: 0,
        totalMusicMinutes: 0,
        totalFilmMinutes: 0,
        totalBookPages: 0,
        genreCounts: {},
        artistCounts: {},
        yearCounts: {},
        averageRating: 0.0,
        topGenres: [],
        topArtists: [],
        mediaTypeCounts: {},
      );
    }

    // Initialize counters
    int totalMusicMinutes = 0;
    int totalFilmMinutes = 0;
    int totalBookPages = 0;
    Map<String, int> genreCounts = {};
    Map<String, int> artistCounts = {};
    Map<String, int> yearCounts = {};
    Map<MediaType, int> mediaTypeCounts = {};
    double totalRating = 0.0;
    int ratedItems = 0;

    // Process each log
    for (final log in logs) {
      // Count media types
      mediaTypeCounts[log.mediaType] = (mediaTypeCounts[log.mediaType] ?? 0) + 1;

      // Process consumption data based on media type
      if (log.mediaType == MediaType.music && log.consumptionData.isNotEmpty) {
        final musicData = MusicConsumptionData.fromMap(log.consumptionData);
        if (musicData.durationSeconds != null) {
          totalMusicMinutes += (musicData.durationSeconds! / 60).round();
        }
        if (musicData.artist != null) {
          artistCounts[musicData.artist!] = (artistCounts[musicData.artist!] ?? 0) + 1;
        }
        if (musicData.year != null) {
          yearCounts[musicData.year.toString()] = (yearCounts[musicData.year.toString()] ?? 0) + 1;
        }
        for (final genre in musicData.genres) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }

      // Calculate average rating
      if (log.rating != null) {
        totalRating += log.rating!;
        ratedItems++;
      }
    }

    // Sort and get top items
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGenres = sortedGenres.take(5).map((e) => e.key).toList();

    final sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topArtists = sortedArtists.take(5).map((e) => e.key).toList();

    return UserStats(
      totalItemsLogged: logs.length,
      totalMusicMinutes: totalMusicMinutes,
      totalFilmMinutes: totalFilmMinutes,
      totalBookPages: totalBookPages,
      genreCounts: genreCounts,
      artistCounts: artistCounts,
      yearCounts: yearCounts,
      averageRating: ratedItems > 0 ? totalRating / ratedItems : 0.0,
      topGenres: topGenres,
      topArtists: topArtists,
      mediaTypeCounts: mediaTypeCounts,
    );
  }

  // Format duration for display
  String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes < 1440) { // Less than 24 hours
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
    } else {
      final days = minutes ~/ 1440;
      final remainingHours = (minutes % 1440) ~/ 60;
      return remainingHours > 0 ? '${days}d ${remainingHours}h' : '${days}d';
    }
  }
}