import 'package:flutter/material.dart';
import '../../services/trending_service.dart';
import '../logs/add_log_screen.dart';

class TrendingMusicScreen extends StatefulWidget {
  const TrendingMusicScreen({super.key});

  @override
  State<TrendingMusicScreen> createState() => _TrendingMusicScreenState();
}

class _TrendingMusicScreenState extends State<TrendingMusicScreen> {
  final TextEditingController _keywordsCtrl = TextEditingController();
  late TrendingService _service;
  Future<List<TrendingItem>>? _future;
  List<TrendingItem> _items = [];
  List<TrendingItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _service = TrendingService();
    _future = _load();
    _keywordsCtrl.addListener(_applyFilter);
  }

  Future<List<TrendingItem>> _load() async {
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

  void _logTrendingItem(BuildContext context, TrendingItem item) {
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

  @override
  void dispose() {
    _keywordsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trending • Music')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _keywordsCtrl,
              decoration: const InputDecoration(
                labelText: 'Filter by keywords (comma separated)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<TrendingItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_filtered.isEmpty) {
                    return const Center(child: Text('No results. Try different keywords.'));
                  }
                  return ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      return ListTile(
                        leading: item.coverUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.coverUrl!, 
                                  width: 56, 
                                  height: 56, 
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.music_note, color: Colors.grey),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.music_note, color: Colors.grey),
                              ),
                        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (item.musicData.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _buildRichDataDisplay(item),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              spacing: 6,
                              children: item.sources
                                  .map((s) => Chip(
                                    label: Text('$s'),
                                    backgroundColor: Colors.blue[50],
                                    labelStyle: const TextStyle(fontSize: 10),
                                  ))
                                  .toList(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                              onPressed: () => _logTrendingItem(context, item),
                              tooltip: 'Log this track',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
