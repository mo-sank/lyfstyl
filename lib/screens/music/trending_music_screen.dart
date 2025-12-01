// Mohamed Sankari - 4 hours

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/music_trending_service.dart';
import '../../services/firestore_service.dart';
import '../../models/media_item.dart';
import '../logs/add_log_screen.dart';
import '../../widgets/fun_loading_widget.dart';

class TrendingMusicScreen extends StatefulWidget {
  const TrendingMusicScreen({super.key});

  @override
  State<TrendingMusicScreen> createState() => _TrendingMusicScreenState();
}

class _TrendingMusicScreenState extends State<TrendingMusicScreen> {
  final TextEditingController _keywordsCtrl = TextEditingController();
  late MusicTrendingService _service;
  Future<List<MusicTrendingItem>>? _future;
  List<MusicTrendingItem> _items = [];
  List<MusicTrendingItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _service = MusicTrendingService();
    _future = _load();
    _keywordsCtrl.addListener(_applyFilter);
  }

  Future<List<MusicTrendingItem>> _load() async {
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

  void _logTrendingItem(BuildContext context, MusicTrendingItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddLogScreen(
          preFilledData: {
            'title': item.title,
            'type': 'music',
            'creator': item.artist,
            'musicData': item.musicData,
            'coverUrl': item.coverUrl,
          },
        ),
      ),
    );
  }

  Future<void> _bookmarkTrendingItem(
    BuildContext context,
    MusicTrendingItem item,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save bookmarks')),
      );
      return;
    }

    final firestore = context.read<FirestoreService>();

    try {
      await firestore.bookmarkMedia(
        userId: user.uid,
        mediaType: MediaType.music,
        title: item.title,
        creator: item.artist,
        coverUrl: item.coverUrl,
        metadata: {'source': 'lastfm', 'musicData': item.musicData},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to bookmarks')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to bookmark track')));
    }
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(MediaType.music.icon, color: Colors.grey, size: 48),
          const SizedBox(height: 8),
          const Text(
            'No Cover',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
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
              child: FutureBuilder<List<MusicTrendingItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return FunLoadingWidget(
                      messages: FunLoadingWidget.musicMessages,
                      color: MediaType.music.color,
                    );
                  }
                  if (_filtered.isEmpty) {
                    return const Center(
                      child: Text('No results. Try different keywords.'),
                    );
                  }
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      return _buildMusicCard(context, item);
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

  Widget _buildMusicCard(BuildContext context, MusicTrendingItem item) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMusicDetails(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            Expanded(
              flex: 3,
              child: item.coverUrl != null
                  ? Image.network(
                      item.coverUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderCover();
                      },
                    )
                  : _buildPlaceholderCover(),
            ),
            // Track Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (item.musicData['album'] != null)
                      Text(
                        item.musicData['album'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    const Spacer(),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark_border,
                            size: 20,
                          ),
                          color: Colors.orangeAccent,
                          onPressed: () => _bookmarkTrendingItem(context, item),
                          tooltip: 'Save bookmark',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 20,
                          ),
                          color: Colors.blue,
                          onPressed: () => _logTrendingItem(context, item),
                          tooltip: 'Log this track',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMusicDetails(BuildContext context, MusicTrendingItem item) {
    final data = item.musicData;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.coverUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.coverUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: Icon(
                            MediaType.music.icon,
                            color: Colors.grey,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Text('Artist: ${item.artist}'),
              if (data['album'] != null && data['album'].toString().isNotEmpty)
                Text('Album: ${data['album']}'),
              if (data['year'] != null)
                Text('Year: ${data['year']}'),
              if (data['durationSeconds'] != null)
                Text(
                  'Duration: ${_formatDuration(data['durationSeconds'] as int)}',
                ),
              if (data['genres'] != null && (data['genres'] as List).isNotEmpty)
                Text('Genres: ${(data['genres'] as List).join(', ')}'),
              if (item.sources.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Sources: ${item.sources.join(', ')}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logTrendingItem(context, item);
            },
            child: const Text('Add Log'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${duration.inSeconds}s';
  }
}