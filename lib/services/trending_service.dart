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
      final response = await http.get(
        Uri.parse('$_lastfmBaseUrl?method=chart.gettoptracks&api_key=$_lastfmApiKey&format=json&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['track'] as List;
        
        return tracks.map((track) => TrendingItem(
          id: track['mbid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'music',
          title: track['name'] ?? '',
          artist: track['artist']['name'] ?? '',
          coverUrl: _getImageUrl(track['image']),
          previewUrl: null,
          sources: ['lastfm'],
          score: (int.tryParse(track['playcount'] ?? '0') ?? 0).toDouble(),
        )).toList();
      }
    } catch (e) {
      // Error fetching trending music: $e
    }
    
    return [];
  }

  String? _getImageUrl(List<dynamic>? images) {
    if (images == null || images.isEmpty) return null;
    
    // Get the largest image (usually the last one)
    for (int i = images.length - 1; i >= 0; i--) {
      final url = images[i]['#text'] as String?;
      if (url != null && url.isNotEmpty) return url;
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