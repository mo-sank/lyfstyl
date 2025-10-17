import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/enhanced_log_entry.dart';

class EnhancedTrendingItem {
  final String id;
  final String type; // music
  final String title;
  final String artist;
  final String? coverUrl;
  final String? previewUrl;
  final List<dynamic> sources;
  final double score;
  
  // Rich music data for logging
  final MusicConsumptionData musicData;

  EnhancedTrendingItem({
    required this.id,
    required this.type,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.previewUrl,
    required this.sources,
    required this.score,
    required this.musicData,
  });
}

class EnhancedTrendingService {
  // Last.fm API key - direct API approach (FREE!)
  static const String _lastfmApiKey = 'a56da6ca8f0fcd0d15dc18e43be048c9';
  static const String _lastfmBaseUrl = 'https://ws.audioscrobbler.com/2.0/';

  // Get trending music with rich data for logging
  Future<List<EnhancedTrendingItem>> getLatestMusic({int limit = 20}) async {
    try {
      // Use chart.getTopTracks with extended info for better cover art
      final response = await http.get(
        Uri.parse('$_lastfmBaseUrl?method=chart.gettoptracks&api_key=$_lastfmApiKey&format=json&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['track'] as List;
        
        // Fetch additional track info for rich data
        final List<EnhancedTrendingItem> items = [];
        for (final track in tracks) {
          final musicData = await _getRichTrackData(track['name'], track['artist']['name']);
          items.add(EnhancedTrendingItem(
            id: track['mbid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'music',
            title: track['name'] ?? '',
            artist: track['artist']['name'] ?? '',
            coverUrl: musicData.coverUrl,
            previewUrl: null,
            sources: ['lastfm'],
            score: (int.tryParse(track['playcount'] ?? '0') ?? 0).toDouble(),
            musicData: musicData,
          ));
        }
        
        return items;
      }
    } catch (e) {
      print('Error fetching trending music: $e');
    }
    
    return [];
  }

  // Get rich track data including duration, genres, and other metadata
  Future<MusicConsumptionData> _getRichTrackData(String trackName, String artistName) async {
    try {
      final response = await http.get(
        Uri.parse('$_lastfmBaseUrl?method=track.getInfo&api_key=$_lastfmApiKey&artist=${Uri.encodeComponent(artistName)}&track=${Uri.encodeComponent(trackName)}&format=json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final track = data['track'];
        
        if (track != null) {
          // Extract album info
          final album = track['album'];
          String? albumName;
          String? coverUrl;
          
          if (album != null) {
            albumName = album['title'] as String?;
            if (album['image'] != null) {
              final images = album['image'] as List;
              coverUrl = _getImageUrl(images);
            }
          }

          // Extract genres from tags
          final List<String> genres = [];
          if (track['toptags'] != null && track['toptags']['tag'] != null) {
            final tags = track['toptags']['tag'] as List;
            for (final tag in tags) {
              if (tag is Map<String, dynamic> && tag['name'] != null) {
                genres.add(tag['name'] as String);
              }
            }
          }

          // Extract duration
          int? durationSeconds;
          if (track['duration'] != null) {
            final duration = int.tryParse(track['duration'].toString());
            if (duration != null && duration > 0) {
              durationSeconds = (duration / 1000).round(); // Convert from milliseconds
            }
          }

          // Extract year from album or track
          int? year;
          if (album != null && album['@attr'] != null && album['@attr']['from'] != null) {
            year = int.tryParse(album['@attr']['from'].toString());
          } else if (track['wiki'] != null && track['wiki']['published'] != null) {
            final published = track['wiki']['published'] as String;
            final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(published);
            if (yearMatch != null) {
              year = int.tryParse(yearMatch.group(0)!);
            }
          }

          // Extract play count
          int? playCount;
          if (track['playcount'] != null) {
            playCount = int.tryParse(track['playcount'].toString());
          }

          // Extract MBID
          String? mbid = track['mbid'] as String?;

          return MusicConsumptionData(
            durationSeconds: durationSeconds,
            playCount: playCount,
            album: albumName,
            artist: artistName,
            genres: genres,
            year: year,
            mbid: mbid,
            // Note: Last.fm doesn't provide audio features like energy, danceability, etc.
            // These would need to be fetched from Spotify API or similar
          );
        }
      }
    } catch (e) {
      print('Error fetching rich track data: $e');
    }
    
    return MusicConsumptionData(
      artist: artistName,
      genres: [],
    );
  }

  String? _getImageUrl(List<dynamic>? images) {
    if (images == null || images.isEmpty) return null;
    
    // Get the largest image (usually the last one)
    for (int i = images.length - 1; i >= 0; i--) {
      final imageData = images[i];
      
      if (imageData is Map<String, dynamic>) {
        final url = imageData['#text'] as String?;
        
        if (url != null && url.isNotEmpty && !url.contains('2a96cbd8b46e442fc41c2b86b821562f')) {
          // Convert HTTP URLs to HTTPS to avoid mixed content issues
          return url.replaceFirst('http://', 'https://');
        }
      }
    }
    return null;
  }

  // Filter trending items by keywords
  List<EnhancedTrendingItem> filterByKeywords(List<EnhancedTrendingItem> items, List<String> keywords) {
    if (keywords.isEmpty) return items;
    final ks = keywords.map((k) => k.toLowerCase().trim()).where((k) => k.isNotEmpty).toList();
    return items.where((i) {
      final hay = '${i.title} ${i.artist} ${i.musicData.genres.join(' ')}'.toLowerCase();
      return ks.any((k) => hay.contains(k));
    }).toList();
  }

  // Helper method to create a log entry from trending item
  LogEntry createLogFromTrendingItem({
    required String userId,
    required EnhancedTrendingItem item,
    double? rating,
    String? review,
    List<String> tags = const [],
    DateTime? consumedAt,
  }) {
    final now = DateTime.now();
    return LogEntry(
      logId: 'temp', // Will be set by Firestore
      userId: userId,
      mediaId: item.id,
      mediaType: MediaType.music,
      rating: rating,
      review: review,
      tags: tags,
      consumedAt: consumedAt ?? now,
      createdAt: now,
      updatedAt: now,
      consumptionData: item.musicData.toMap(),
    );
  }
}
