import 'package:flutter/material.dart';
import '../../services/trending_service.dart';

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
                            ? Image.network(item.coverUrl!, width: 56, height: 56, fit: BoxFit.cover)
                            : const Icon(Icons.music_note),
                        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Wrap(
                          spacing: 6,
                          children: item.sources
                              .map((s) => Chip(label: Text('$s')))
                              .toList(),
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
