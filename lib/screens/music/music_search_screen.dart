import 'package:flutter/material.dart';
import '../../services/trending_service.dart';
import '../logs/add_log_screen.dart';

class MusicSearchScreen extends StatefulWidget {
  const MusicSearchScreen({super.key});

  @override
  State<MusicSearchScreen> createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late TrendingService _service;
  Future<List<TrendingItem>>? _searchFuture;
  List<TrendingItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _service = TrendingService();
  }

  Future<void> _searchMusic() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _searchFuture = _performSearch();
    });
  }

  Future<List<TrendingItem>> _performSearch() async {
    try {
      final results = await _service.searchMusic(_searchCtrl.text.trim());
      _searchResults = results;
      return results;
    } catch (e) {
      print('Search error: $e');
      return [];
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _logSearchResult(BuildContext context, TrendingItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddLogScreen(
          preFilledData: {
            'title': item.title,
            'type': 'music',
            'creator': item.artist,
            'musicData': item.musicData,
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Music'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search for songs, artists, or albums...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _searchFuture = null;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _searchMusic(),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _searchMusic,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Search by song title, artist name, or album name',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_searchFuture == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for music',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a song, artist, or album name to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<TrendingItem>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _searchMusic,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }
        
        final results = snapshot.data ?? [];
        
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No results found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return _buildSearchResultCard(item);
          },
        );
      },
    );
  }

  Widget _buildSearchResultCard(TrendingItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _logSearchResult(context, item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Album Art
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: item.coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.music_note, size: 40, color: Colors.grey);
                          },
                        ),
                      )
                    : const Icon(Icons.music_note, size: 40, color: Colors.grey),
              ),
              
              const SizedBox(width: 16),
              
              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Artist
                    Text(
                      item.artist,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Rich Data Display
                    _buildRichDataDisplay(item),
                    
                    const SizedBox(height: 8),
                    
                    // Action Button
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Log This',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichDataDisplay(TrendingItem item) {
    final data = item.musicData;
    final List<Widget> infoWidgets = [];
    
    // Album
    if (data['album'] != null && data['album'].toString().isNotEmpty) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.album, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              data['album'].toString(),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Duration
    if (data['durationSeconds'] != null) {
      final duration = Duration(seconds: data['durationSeconds'] as int);
      final durationText = duration.inMinutes > 0 
          ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
          : '${duration.inSeconds}s';
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              durationText,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Year
    if (data['year'] != null) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              data['year'].toString(),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Genres
    if (data['genres'] != null && (data['genres'] as List).isNotEmpty) {
      final genres = (data['genres'] as List).take(2).join(', ');
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              genres,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (infoWidgets.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: infoWidgets,
    );
  }
}
