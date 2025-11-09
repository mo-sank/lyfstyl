import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/media_item.dart';
import '../models/log_entry.dart';
import '../services/movie_service.dart';

abstract class ImportHandler {
  /// Create media/log entries for a single parsed CSV row.
  /// Implementations should throw on unrecoverable errors.
  Future<void> createFromMap(
    Map<String, dynamic> row,
    BuildContext context,
    FirestoreService svc,
    String userId,
    DateTime now,
  );
}

class GoodreadsImportHandler implements ImportHandler {
  // Parses date strings in yyyy/MM/dd only (keeps behavior from screen)
  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split('/');
    try {
      if (parts.length == 3 && parts[0].length == 4) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    var str = value.toString().trim();
    if (str.startsWith('="') && str.endsWith('"')) {
      str = str.substring(2, str.length - 1);
    }
    str = str.replaceAll('"', '');
    return int.tryParse(str);
  }

  @override
  Future<void> createFromMap(
    Map<String, dynamic> row,
    BuildContext context,
    FirestoreService svc,
    String userId,
    DateTime now,
  ) async {
    // Only import items marked as read
    final shelf = (row['Exclusive Shelf'] ?? row['Exclusive shelf'] ?? '').toString().toLowerCase();
    if (shelf != 'read') return;

    final title = (row['Title'] ?? '').toString();
    final author = (row['Author'] ?? '').toString();
    final media = await svc.getOrCreateMedia(
      title: title,
      type: MediaType.book,
      creator: author,
    );

    final dateRead = _parseDate(row['Date Read']?.toString());
    final log = LogEntry(
      logId: 'temp',
      userId: userId,
      mediaId: media.mediaId,
      mediaType: MediaType.book,
      rating: row['My Rating'],
      review: row['My Review']?.toString() ?? '',
      consumedAt: dateRead ?? now,
      createdAt: now,
      updatedAt: now,
      consumptionData: BookConsumptionData(
        pages: _parseInt(row['Number of Pages']),
        isbn: row['ISBN'],
        isbn13: row['ISBN13'],
        publisher: row['Publisher'],
        readCount: _parseInt(row['Read Count']),
      ).toMap(),
    );

    await svc.createLog(log);
  }
}

class LetterboxdImportHandler implements ImportHandler {
  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return DateTime.parse(value.trim());
      } catch (_) {}
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  @override
  Future<void> createFromMap(
    Map<String, dynamic> row,
    BuildContext context,
    FirestoreService svc,
    String userId,
    DateTime now,
  ) async {
    final title = (row['Name']).toString();
    final yearStr = (row['Year']);

    late MovieService service = MovieService();
    final movies = await service.searchMovies(title.replaceAll(' ', '-'));
    final yr = service.filterMovies(movies,minYear: yearStr, maxYear: yearStr);
    final movie = yr.first;
    
    final media = await svc.getOrCreateMedia(
      title: movie.title,
      type: MediaType.film,
      creator: movie.director,
    );

    final watchedAt = _parseDate(row.values.last);

    final log = LogEntry(
      logId: 'temp',
      userId: userId,
      mediaId: media.mediaId,
      mediaType: MediaType.film,
      rating: row['Rating'],
      consumedAt: watchedAt ?? now,
      createdAt: now,
      updatedAt: now,
      consumptionData: {},
    );

    await svc.createLog(log);
  }
}