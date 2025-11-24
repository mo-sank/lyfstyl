import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/bookmark_item.dart';
import '../../models/media_item.dart';
import '../../services/firestore_service.dart';
import '../../theme/media_type_theme.dart';
import '../logs/add_log_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<BookmarkItem>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = _loadBookmarks();
  }

  Future<List<BookmarkItem>> _loadBookmarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final svc = context.read<FirestoreService>();
    return svc.getUserBookmarks(user.uid);
  }

  Future<void> _refresh() async {
    setState(() {
      _bookmarksFuture = _loadBookmarks();
    });
  }

  Map<MediaType, List<BookmarkItem>> _groupByType(List<BookmarkItem> items) {
    final map = <MediaType, List<BookmarkItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.mediaType, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<BookmarkItem>>(
          future: _bookmarksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final bookmarks = snapshot.data ?? [];
            if (bookmarks.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'You have no bookmarks yet.\nLook for the bookmark icon on movies, books, and music to save them here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              );
            }

            final grouped = _groupByType(bookmarks);
            final ordering = [
              MediaType.movie,

              MediaType.book,

              MediaType.music,
            ];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: ordering
                  .where((type) => grouped[type]?.isNotEmpty ?? false)
                  .map((type) => _buildSection(type, grouped[type]!))
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(MediaType type, List<BookmarkItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(type.icon, color: type.color),
            const SizedBox(width: 8),
            Text(
              _sectionTitle(type),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildBookmarkTile(item)),
        const SizedBox(height: 24),
      ],
    );
  }

  String _sectionTitle(MediaType type) {
    if (type == MediaType.movie ) {
      return 'Movies & Shows';
    }
    if (type == MediaType.book) {
      return 'Books';
    }
    if (
        type == MediaType.music) {
      return 'Music';
    }
    return type.name;
  }

  Widget _buildBookmarkTile(BookmarkItem bookmark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildCover(bookmark),
        title: Text(
          bookmark.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bookmark.creator != null && bookmark.creator!.isNotEmpty)
              Text(
                bookmark.creator!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (bookmark.subtitle != null && bookmark.subtitle!.isNotEmpty)
              Text(
                bookmark.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.playlist_add),
              tooltip: 'Log this item',
              onPressed: () => _logBookmark(bookmark),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Remove bookmark',
              onPressed: () => _removeBookmark(bookmark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BookmarkItem bookmark) {
    if (bookmark.coverUrl == null) {
      return _placeholderIcon(bookmark.mediaType);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        bookmark.coverUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderIcon(bookmark.mediaType),
      ),
    );
  }

  Widget _placeholderIcon(MediaType type) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(type.icon, color: type.color),
    );
  }

  Future<void> _logBookmark(BookmarkItem bookmark) async {
    final prefill = <String, dynamic>{
      'title': bookmark.title,
      'type': bookmark.mediaType.name,
      if (bookmark.creator != null) 'creator': bookmark.creator,
      if (bookmark.subtitle != null) 'subtitle': bookmark.subtitle,
    };
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddLogScreen(preFilledData: prefill)),
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _removeBookmark(BookmarkItem bookmark) async {
    final svc = context.read<FirestoreService>();
    try {
      await svc.removeBookmark(bookmark.bookmarkId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove bookmark')),
      );
    } finally {
      if (mounted) {
        await _refresh();
      }
    }
  }
}
