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
  
  // Rich music data for logging
  final Map<String, dynamic> musicData;

  TrendingItem({
    required this.id,
    required this.type,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.previewUrl,
    required this.sources,
    required this.score,
    this.musicData = const {},
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
        
        // Fetch additional track info for rich data
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
            musicData: trackInfo,
          ));
        }
        
        return items;
      }
    } catch (e) {
      print('Error fetching trending music: $e');
    }
    
    return [];
  }

  // Get additional track info including better cover art and rich data
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
          String? coverUrl;
          String? albumName;
          
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

          return {
            'coverUrl': coverUrl,
            'album': albumName,
            'genres': genres,
            'durationSeconds': durationSeconds,
            'year': year,
            'playCount': playCount,
            'mbid': mbid,
          };
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

  // Search for music using Last.fm API
  Future<List<TrendingItem>> searchMusic(String query, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_lastfmBaseUrl?method=track.search&api_key=$_lastfmApiKey&track=${Uri.encodeComponent(query)}&format=json&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final searchResults = data['results']['trackmatches']['track'];
        
        if (searchResults == null) return [];
        
        final tracks = searchResults is List ? searchResults : [searchResults];
        
        // Fetch additional track info for rich data
        final List<TrendingItem> items = [];
        for (final track in tracks) {
          final trackInfo = await _getTrackInfo(track['name'], track['artist']);
          items.add(TrendingItem(
            id: track['mbid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'music',
            title: track['name'] ?? '',
            artist: track['artist'] ?? '',
            coverUrl: trackInfo['coverUrl'],
            previewUrl: null,
            sources: ['lastfm'],
            score: 0.0, // Search results don't have play counts
            musicData: trackInfo,
          ));
        }
        
        return items;
      }
    } catch (e) {
      print('Error searching music: $e');
    }
    
    return [];
  }

  // Get music by genre - both trending and popular
  Future<List<TrendingItem>> getMusicByGenre(String genre, {int limit = 30}) async {
    try {
      final List<TrendingItem> allResults = [];
      
      // Get trending tracks in this genre
      final trendingResults = await _getTrendingByGenre(genre, limit: limit ~/ 2);
      allResults.addAll(trendingResults);
      
      // Get popular tracks in this genre
      final popularResults = await _getPopularByGenre(genre, limit: limit ~/ 2);
      allResults.addAll(popularResults);
      
      // Remove duplicates based on track name and artist
      final uniqueResults = <String, TrendingItem>{};
      for (final item in allResults) {
        final key = '${item.title.toLowerCase()}_${item.artist.toLowerCase()}';
        if (!uniqueResults.containsKey(key)) {
          uniqueResults[key] = item;
        }
      }
      
      return uniqueResults.values.take(limit).toList();
    } catch (e) {
      print('Error fetching music by genre: $e');
      return [];
    }
  }

  // Get trending tracks in a specific genre
  Future<List<TrendingItem>> _getTrendingByGenre(String genre, {int limit = 15}) async {
    try {
      // Use chart.getTopTracks and filter by genre
      final response = await http.get(
        Uri.parse('$_lastfmBaseUrl?method=chart.gettoptracks&api_key=$_lastfmApiKey&format=json&limit=50'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['track'] as List;
        
        final List<TrendingItem> genreItems = [];
        for (final track in tracks) {
          final trackInfo = await _getTrackInfo(track['name'], track['artist']['name']);
          final genres = trackInfo['genres'] as List? ?? [];
          
          // Check if this track matches the genre
          if (genres.any((g) => g.toString().toLowerCase().contains(genre.toLowerCase()))) {
            genreItems.add(TrendingItem(
              id: track['mbid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: 'music',
              title: track['name'] ?? '',
              artist: track['artist']['name'] ?? '',
              coverUrl: trackInfo['coverUrl'],
              previewUrl: null,
              sources: ['lastfm'],
              score: (int.tryParse(track['playcount'] ?? '0') ?? 0).toDouble(),
              musicData: trackInfo,
            ));
            
            if (genreItems.length >= limit) break;
          }
        }
        
        return genreItems;
      }
    } catch (e) {
      print('Error fetching trending by genre: $e');
    }
    
    return [];
  }

  // Get popular tracks in a specific genre using tag.getTopTracks
  Future<List<TrendingItem>> _getPopularByGenre(String genre, {int limit = 15}) async {
    try {
      final response = await http.get(
        Uri.parse('$_lastfmBaseUrl?method=tag.gettoptracks&api_key=$_lastfmApiKey&tag=${Uri.encodeComponent(genre)}&format=json&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['track'] as List;
        
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
            musicData: trackInfo,
          ));
        }
        
        return items;
      }
    } catch (e) {
      print('Error fetching popular by genre: $e');
    }
    
    return [];
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