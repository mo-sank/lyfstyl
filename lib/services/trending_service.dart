import 'package:http/http.dart' as http;
import 'dart:convert';

class TrendingItem {
  final String id;
  final String type; // music
  final String title;
  final String artist;
  final String? coverUrl;
  final String? previewUrl;
  final List<dynamic> sources;
  final double score;

  TrendingItem({
    required this.id,
    required this.type,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.previewUrl,
    required this.sources,
    required this.score,
  });
}

class TrendingService {
  // Last.fm API key - direct API approach (FREE!)
  static const String _lastfmApiKey = 'a56da6ca8f0fcd0d15dc18e43be048c9';
  static const String _lastfmBaseUrl = 'https://ws.audioscrobbler.com/2.0/';

  // Get trending music directly from Last.fm (FREE!)
  Future<List<TrendingItem>> getLatestMusic({int limit = 20}) async {
    try {
      // Use chart.getTopTracks with extended info for better cover art
      final response = await http.get(
        Uri.parse('$_lastfmBaseUrl?method=chart.gettoptracks&api_key=$_lastfmApiKey&format=json&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['track'] as List;
        
        // Fetch additional track info for better cover art
        final List<TrendingItem> items = [];
        for (final track in tracks) {
          final trackInfo = await _getTrackInfo(track['name'], track['artist']['name']);
          items.add(TrendingItem(
            id: track['mbid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'music',
            title: track['name'] ?? '',
            artist: track['artist']['name'] ?? '',
            coverUrl: trackInfo['coverUrl'],
            previewUrl: null,
            sources: ['lastfm'],
            score: (int.tryParse(track['playcount'] ?? '0') ?? 0).toDouble(),
          ));
        }
        
        return items;
      }
    } catch (e) {
      print('Error fetching trending music: $e');
    }
    
    return [];
  }

  // Get additional track info including better cover art
  Future<Map<String, dynamic>> _getTrackInfo(String trackName, String artistName) async {
    try {
      final response = await http.get(
        Uri.parse('$_lastfmBaseUrl?method=track.getInfo&api_key=$_lastfmApiKey&artist=${Uri.encodeComponent(artistName)}&track=${Uri.encodeComponent(trackName)}&format=json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final track = data['track'];
        if (track != null) {
          final album = track['album'];
          if (album != null && album['image'] != null) {
            final images = album['image'] as List;
            return {'coverUrl': _getImageUrl(images)};
          }
        }
      }
    } catch (e) {
      print('Error fetching track info: $e');
    }
    
    return {'coverUrl': null};
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
  List<TrendingItem> filterByKeywords(List<TrendingItem> items, List<String> keywords) {
    if (keywords.isEmpty) return items;
    final ks = keywords.map((k) => k.toLowerCase().trim()).where((k) => k.isNotEmpty).toList();
    return items.where((i) {
      final hay = '${i.title} ${i.artist}'.toLowerCase();
      return ks.any((k) => hay.contains(k));
    }).toList();
  }
}