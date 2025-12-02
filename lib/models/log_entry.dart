import 'package:cloud_firestore/cloud_firestore.dart';
import 'media_item.dart';
import 'package:flutter/material.dart';
import '../screens/logs/edit_log_screen.dart'; // <-- Add this line
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';

class LogEntry {
  final String logId; // doc id
  final String userId;
  final String mediaId;
  final MediaType mediaType;
  final double? rating; // 0-5 or null
  final String? review;
  final List<String> tags;
  final DateTime consumedAt; // when user consumed the media
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Rich consumption data based on media type
  final Map<String, dynamic> consumptionData;

  LogEntry({
    required this.logId,
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    this.rating,
    this.review,
    this.tags = const [],
    required this.consumedAt,
    required this.createdAt,
    required this.updatedAt,
    this.consumptionData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaId': mediaId,
      'mediaType': mediaType.name,
      'rating': rating,
      'review': review,
      'tags': tags,
      'consumedAt': Timestamp.fromDate(consumedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'consumptionData': consumptionData,
    };
  }

  factory LogEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LogEntry(
      logId: doc.id,
      userId: (data['userId'] ?? '') as String,
      mediaId: (data['mediaId'] ?? '') as String,
      mediaType: _parseMediaType(data['mediaType'] as String?),
      rating: (data['rating'] as num?)?.toDouble(),
      review: data['review'] as String?,
      tags: (data['tags'] as List<dynamic>? ?? []).cast<String>(),
      consumedAt: (data['consumedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      consumptionData: (data['consumptionData'] as Map<String, dynamic>? ?? {}),
    );
  }

  static MediaType _parseMediaType(String? value) {
    switch (value) {
      case 'film':
        return MediaType.movie;
      case 'book':
        return MediaType.book;
      case 'music':
        return MediaType.music;
      default:
        return MediaType.movie;
    }
  }

  Future<void> showMediaDialog(BuildContext context, LogEntry log, MediaItem? item) {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cover image
                  if (item != null && item.coverUrl != null && item.coverUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.coverUrl!,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(item.type.icon, size: 80, color: item.type.color),
                      ),
                    )
                  else
                    Icon(log.mediaType.icon, size: 80, color: log.mediaType.color),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    item?.title ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Creator (author, director, artist)
                  if (item?.creator != null && item!.creator!.isNotEmpty)
                    Text(
                      item.creator!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  // Rating as stars
                  if (log.rating != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final filled = log.rating! >= index + 1;
                        final half = !filled && log.rating! > index && log.rating! < index + 1;
                        return Icon(
                          filled
                              ? Icons.star
                              : half
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        );
                      }),
                    ),
                  const SizedBox(height: 8),
                  // Review
                  if (log.review != null && log.review!.isNotEmpty)
                    Text(
                      log.review!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  // Tags
                  if (log.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: log.tags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.blue[50],
                      )).toList(),
                    ),
                  const SizedBox(height: 8),
                  // Consumed at date
                  Text(
                    'Consumed at: ${_formatDate(log.consumedAt)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Edit, Delete, and Close buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditLogScreen(
                                media: item!,
                                log: log,
                              ),
                            ),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Log'),
                              content: const Text('Are you sure you want to delete this log? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true && context.mounted) {
                            try {
                              // Import FirestoreService and Provider at the top
                              final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                              await firestoreService.deleteLog(log.logId);
                              
                              if (context.mounted) {
                                Navigator.of(context).pop(); // Close the media dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Log deleted successfully')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete log: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class BookConsumptionData {
  final int? pages;
  final int? isbn;
  final int? isbn13;
  final String? publisher;
  final int? readCount;

  BookConsumptionData({
    this.pages,
    this.isbn,
    this.isbn13,
    this.publisher,
    this.readCount
  });

  Map<String, dynamic> toMap() {
    return {
      'pages': pages,
      'isbn': isbn,
      'isbn13': isbn13,
      'publisher': publisher,
      'readCount': readCount
    };
  }

    factory BookConsumptionData.fromMap(Map<String, dynamic> data) {
    return BookConsumptionData(
      pages: data['pages'] as int?,
      isbn: data['isbn'] as int?,
      isbn13: data['isbn13'] as int?,
      publisher: data['publisher'] as String?,
      readCount: data['readcCOunt'] as int?
    );
  }
}

// Music-specific consumption data
class MusicConsumptionData {
  final int? durationSeconds; // Song duration in seconds
  final int? playCount; // How many times user listened
  final String? album;
  final String? artist;
  final List<String> genres;
  final int? year;
  final String? mbid; // MusicBrainz ID
  final String? coverUrl;

  MusicConsumptionData({
    this.durationSeconds,
    this.playCount,
    this.album,
    this.artist,
    this.genres = const [],
    this.year,
    this.mbid,
    this.coverUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'durationSeconds': durationSeconds,
      'playCount': playCount,
      'album': album,
      'artist': artist,
      'genres': genres,
      'year': year,
      'mbid': mbid,
      'coverUrl': coverUrl,
    };
  }

  factory MusicConsumptionData.fromMap(Map<String, dynamic> data) {
    return MusicConsumptionData(
      durationSeconds: data['durationSeconds'] as int?,
      playCount: data['playCount'] as int?,
      album: data['album'] as String?,
      artist: data['artist'] as String?,
      genres: (data['genres'] as List<dynamic>? ?? []).cast<String>(),
      year: data['year'] as int?,
      mbid: data['mbid'] as String?,
      coverUrl: data['coverUrl'] as String?,
    );
  }

  // Helper methods for stats calculation
  Duration? get duration => durationSeconds != null ? Duration(seconds: durationSeconds!) : null;
  
  String get formattedDuration {
    if (durationSeconds == null) return 'Unknown';
    final d = Duration(seconds: durationSeconds!);
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }
}


