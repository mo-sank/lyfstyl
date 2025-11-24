import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/log_entry.dart';
import '../../models/media_item.dart';
import '../../models/collection.dart';
import '../logs/log_detail_screen.dart';

class MyCollectionsScreen extends StatefulWidget {
  const MyCollectionsScreen({super.key});

  @override
  State<MyCollectionsScreen> createState() => _MyCollectionsScreenState();
}

class _MyCollectionsScreenState extends State<MyCollectionsScreen> {
  late Future<_CollectionsOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadOverview();
  }

  void _refresh() {
    setState(() {
      _future = _loadOverview();
    });
  }

  // OPTIMIZED: Only load counts and metadata, not full data
  Future<_CollectionsOverview> _loadOverview() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final svc = context.read<FirestoreService>();
    
    // Load only the most recent 50 logs for quick counts
    final recentLogs = await svc.getUserLogs(uid, limit: 50);
    
    // FIXED: Batch fetch all media at once instead of individual calls
    final mediaIds = recentLogs.map((l) => l.mediaId).toSet().toList();
    final mediaMap = await svc.getMediaByIds(mediaIds);
    
    // Count by type (fast, in-memory)
    int filmCount = 0, musicCount = 0, bookCount = 0;
    DateTime? lastFilm, lastMusic, lastBook;
    String? filmCover, musicCover, bookCover;
    
    final seenMedia = <String>{};
    
    for (final log in recentLogs) {
      if (seenMedia.contains(log.mediaId)) continue;
      seenMedia.add(log.mediaId);
      
      final media = mediaMap[log.mediaId];
      if (media == null) continue;
      
      switch (media.type) {
        case MediaType.movie:
          filmCount++;
          if (lastFilm == null || log.consumedAt.isAfter(lastFilm)) {
            lastFilm = log.consumedAt;
            filmCover = media.coverUrl;
          }
          break;
        case MediaType.music:
          musicCount++;
          if (lastMusic == null || log.consumedAt.isAfter(lastMusic)) {
            lastMusic = log.consumedAt;
            musicCover = media.coverUrl;
          }
          break;
        case MediaType.book:
          bookCount++;
          if (lastBook == null || log.consumedAt.isAfter(lastBook)) {
            lastBook = log.consumedAt;
            bookCover = media.coverUrl;
          }
          break;
        default:
          filmCount++;
          break;
      }
    }
    
    // Load custom collections (just metadata, no items yet)
    final customCollections = await svc.getUserCollections(uid);
    
    return _CollectionsOverview(
      filmCount: filmCount,
      musicCount: musicCount,
      bookCount: bookCount,
      lastFilm: lastFilm,
      lastMusic: lastMusic,
      lastBook: lastBook,
      filmCover: filmCover,
      musicCover: musicCover,
      bookCover: bookCover,
      customCollections: customCollections,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCollectionDialog(),
            tooltip: 'Create Collection',
          ),
        ],
      ),
      body: FutureBuilder<_CollectionsOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading collections...'),
                ],
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }
          
          final data = snapshot.data!;
          
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                
                final allCards = <Widget>[
                  // Default collections (with lazy loading)
                  _CollectionCard(
                    title: 'Film',
                    count: data.filmCount,
                    lastLogged: data.lastFilm,
                    onTap: () => _openDefaultList(context, 'Film', MediaType.movie),
                    imageUrl: data.filmCover,
                    isDefault: true,
                  ),
                  _CollectionCard(
                    title: 'Music',
                    count: data.musicCount,
                    lastLogged: data.lastMusic,
                    onTap: () => _openDefaultList(context, 'Music', MediaType.music),
                    imageUrl: data.musicCover,
                    isDefault: true,
                  ),
                  _CollectionCard(
                    title: 'Books',
                    count: data.bookCount,
                    lastLogged: data.lastBook,
                    onTap: () => _openDefaultList(context, 'Books', MediaType.book),
                    imageUrl: data.bookCover,
                    isDefault: true,
                  ),
                  // Custom collections
                  ...data.customCollections.map((collection) {
                    return _CollectionCard(
                      title: collection.name,
                      count: collection.itemIds.length,
                      lastLogged: collection.updatedAt,
                      onTap: () => _openCustomList(context, collection),
                      imageUrl: null, // Load lazily
                      isDefault: false,
                      onEdit: () => _showEditCollectionDialog(collection),
                      onDelete: () => _deleteCollection(collection),
                    );
                  }).toList(),
                ];

                return GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 1,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: isWide ? 0.9 : 2.0,
                  ),
                  children: allCards,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Load full data only when user clicks into a collection
  void _openDefaultList(BuildContext context, String title, MediaType type) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final svc = context.read<FirestoreService>();
      
      // NOW load all logs of this type
      final logs = await svc.getUserLogs(uid, limit: 500);
      final mediaIds = logs.map((l) => l.mediaId).toSet().toList();
      final mediaMap = await svc.getMediaByIds(mediaIds);
      
      final items = <_Item>[];
      for (final log in logs) {
        final media = mediaMap[log.mediaId];
        if (media != null && media.type == type) {
          items.add(_Item(media: media, log: log));
        }
      }
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _CollectionDetailScreen(title: title, items: items),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openCustomList(BuildContext context, CollectionModel collection) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final svc = context.read<FirestoreService>();
      
      // Load media for this collection
      final mediaMap = await svc.getMediaByIds(collection.itemIds);
      
      // Load logs for these media items
      final logs = await svc.getUserLogs(uid, limit: 500);
      final logMap = <String, LogEntry>{};
      for (final log in logs) {
        if (!logMap.containsKey(log.mediaId) ||
            log.consumedAt.isAfter(logMap[log.mediaId]!.consumedAt)) {
          logMap[log.mediaId] = log;
        }
      }
      
      final items = <_Item>[];
      for (final mediaId in collection.itemIds) {
        final media = mediaMap[mediaId];
        final log = logMap[mediaId];
        if (media != null && log != null) {
          items.add(_Item(media: media, log: log));
        }
      }
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _CollectionDetailScreen(
              title: collection.name,
              items: items,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreateCollectionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Collection Name',
            hintText: 'e.g., Favorites, Watch Later',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                final svc = context.read<FirestoreService>();
                await svc.createCollectionByName(uid, controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _refresh();
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditCollectionDialog(CollectionModel collection) {
    final controller = TextEditingController(text: collection.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Collection Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final svc = context.read<FirestoreService>();
                await svc.renameCollection(collection.collectionId, controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _refresh();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCollection(CollectionModel collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text('Are you sure you want to delete "${collection.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final svc = context.read<FirestoreService>();
              await svc.deleteCollection(collection.collectionId);
              if (mounted) {
                Navigator.pop(context);
                _refresh();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final String title;
  final int count;
  final DateTime? lastLogged;
  final VoidCallback onTap;
  final String? imageUrl;
  final bool isDefault;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CollectionCard({
    required this.title,
    required this.count,
    required this.lastLogged,
    required this.onTap,
    this.imageUrl,
    this.isDefault = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: imageUrl != null
                        ? Image.network(imageUrl!, fit: BoxFit.cover)
                        : Icon(Icons.collections_bookmark, size: 56, color: Colors.grey[500]),
                  ),
                ),
                if (!isDefault)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: onEdit,
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: onDelete,
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isDefault)
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('$count items', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  if (lastLogged != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last logged: ${lastLogged!.toLocal().toString().split(' ').first}',
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionDetailScreen extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _CollectionDetailScreen({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No items in this collection'),
                ],
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final it = items[index];
                return ListTile(
                  leading: it.media.coverUrl != null
                      ? Image.network(it.media.coverUrl!, width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                  title: Text(it.media.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Consumed: ${it.log.consumedAt.toLocal().toString().split(' ').first}'
                        '${it.log.rating != null ? ' · Rating: ${it.log.rating!.toStringAsFixed(1)}' : ''}',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LogDetailScreen(media: it.media, log: it.log),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _Item {
  final MediaItem media;
  final LogEntry log;
  _Item({required this.media, required this.log});
}

class _CollectionsOverview {
  final int filmCount;
  final int musicCount;
  final int bookCount;
  final DateTime? lastFilm;
  final DateTime? lastMusic;
  final DateTime? lastBook;
  final String? filmCover;
  final String? musicCover;
  final String? bookCover;
  final List<CollectionModel> customCollections;
  
  _CollectionsOverview({
    required this.filmCount,
    required this.musicCount,
    required this.bookCount,
    this.lastFilm,
    this.lastMusic,
    this.lastBook,
    this.filmCover,
    this.musicCover,
    this.bookCover,
    required this.customCollections,
  });
}