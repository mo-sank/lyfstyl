import 'package:flutter/material.dart';
import 'package:lyfstyl/models/media_item.dart';
import '../../services/enhanced_trending_service.dart';
import '../logs/enhanced_add_log_screen.dart';
import '../../theme/media_type_theme.dart';

class EnhancedTrendingMusicScreen extends StatefulWidget {
  const EnhancedTrendingMusicScreen({super.key});

  @override
  State<EnhancedTrendingMusicScreen> createState() => _EnhancedTrendingMusicScreenState();
}

class _EnhancedTrendingMusicScreenState extends State<EnhancedTrendingMusicScreen> {
  final TextEditingController _keywordsCtrl = TextEditingController();
  late EnhancedTrendingService _service;
  Future<List<EnhancedTrendingItem>>? _future;
  List<EnhancedTrendingItem> _items = [];
  List<EnhancedTrendingItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _service = EnhancedTrendingService();
    _future = _load();
    _keywordsCtrl.addListener(_applyFilter);
  }

  Future<List<EnhancedTrendingItem>> _load() async {
    final items = await _service.getLatestMusic(limit: 20);
    _items = items;
    _filtered = items;
    return items;
  }

  void _applyFilter() {
    final ks = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() {
      _filtered = _service.filterByKeywords(_items, ks);
    });
  }

  void _logTrendingItem(BuildContext context, EnhancedTrendingItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedAddLogScreen(
          trendingItem: item,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keywordsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Music'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search/Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _keywordsCtrl,
                  decoration: InputDecoration(
                    hintText: 'Filter by keywords (comma separated)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Example: rock, pop, 2023, indie',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: FutureBuilder<List<EnhancedTrendingItem>>(
              future: _future,
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
                          onPressed: () {
                            setState(() {
                              _future = _load();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                final items = _filtered;
                
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.music_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _keywordsCtrl.text.isNotEmpty 
                            ? 'No results found for your search'
                            : 'No trending music available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_keywordsCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _keywordsCtrl.clear();
                              _applyFilter();
                            },
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildTrendingItemCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingItemCard(EnhancedTrendingItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _logTrendingItem(context, item),
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
                            return Icon(MediaType.music.icon, size: 40, color: Colors.grey);
                          },
                        ),
                      )
                    :  Icon(MediaType.music.icon, size: 40, color: Colors.grey),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichDataDisplay(EnhancedTrendingItem item) {
    final data = item.musicData;
    final List<Widget> infoWidgets = [];
    
    // Album
    if (data.album != null && data.album!.isNotEmpty) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.album, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              data.album!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Duration
    if (data.durationSeconds != null) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              data.formattedDuration,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Year
    if (data.year != null) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              data.year.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Genres
    if (data.genres.isNotEmpty) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              data.genres.take(2).join(', '),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (data.genres.length > 2)
              Text(
                ' +${data.genres.length - 2} more',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      );
    }
    
    if (infoWidgets.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: infoWidgets,
    );
  }
}
