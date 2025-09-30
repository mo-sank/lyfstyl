import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/log_entry.dart';
import '../../models/media_item.dart';
import '../logs/log_detail_screen.dart';

class MyCollectionsScreen extends StatefulWidget {
  const MyCollectionsScreen({super.key});

  @override
  State<MyCollectionsScreen> createState() => _MyCollectionsScreenState();
}

class _MyCollectionsScreenState extends State<MyCollectionsScreen> {
  late Future<_GroupedCollections> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GroupedCollections> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final svc = context.read<FirestoreService>();
    final logs = await svc.getUserLogs(uid, limit: 500);
    final mediaIds = logs.map((l) => l.mediaId).toSet().toList();
    final mediaMap = await svc.getMediaByIds(mediaIds);

    final film = <_Item>[];
    final music = <_Item>[];
    final written = <_Item>[];

    for (final log in logs) {
      final m = mediaMap[log.mediaId];
      if (m == null) continue;
      final item = _Item(media: m, log: log);
      switch (m.type) {
        case MediaType.film:
          film.add(item);
          break;
        case MediaType.music:
          music.add(item);
          break;
        case MediaType.book:
          written.add(item);
          break;
        default:
          film.add(item);
          break;
      }
    }

    DateTime? last(List<_Item> items) => items.isEmpty
        ? null
        : items.map((e) => e.log.consumedAt).reduce((a, b) => a.isAfter(b) ? a : b);

    return _GroupedCollections(
      film: film,
      music: music,
      written: written,
      lastFilm: last(film),
      lastMusic: last(music),
      lastWritten: last(written),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Collections')),
      body: FutureBuilder<_GroupedCollections>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final g = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 1,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: isWide ? 0.9 : 2.0,
                  ),
                  children: [
                    _CollectionCard(
                      title: 'Film',
                      count: g.film.length,
                      lastLogged: g.lastFilm,
                      onTap: () => _openList(context, 'Film', g.film),
                      imageUrl: g.film.isNotEmpty ? g.film.first.media.coverUrl : null,
                    ),
                    _CollectionCard(
                      title: 'Music',
                      count: g.music.length,
                      lastLogged: g.lastMusic,
                      onTap: () => _openList(context, 'Music', g.music),
                      imageUrl: g.music.isNotEmpty ? g.music.first.media.coverUrl : null,
                    ),
                    _CollectionCard(
                      title: 'Written',
                      count: g.written.length,
                      lastLogged: g.lastWritten,
                      onTap: () => _openList(context, 'Written', g.written),
                      imageUrl: g.written.isNotEmpty ? g.written.first.media.coverUrl : null,
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openList(BuildContext context, String title, List<_Item> items) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CollectionDetailScreen(title: title, items: items),
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

  const _CollectionCard({
    required this.title,
    required this.count,
    required this.lastLogged,
    required this.onTap,
    this.imageUrl,
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
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey[200],
                child: imageUrl != null
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Icon(Icons.collections_bookmark, size: 56, color: Colors.grey[500]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('$count items', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  if (lastLogged != null) ...[
                    const SizedBox(height: 4),
                    Text('Last logged: ${lastLogged!.toLocal().toString().split(' ').first}',
                        style: const TextStyle(fontSize: 12, color: Colors.black45)),
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
      body: ListView.separated(
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

class _GroupedCollections {
  final List<_Item> film;
  final List<_Item> music;
  final List<_Item> written;
  final DateTime? lastFilm;
  final DateTime? lastMusic;
  final DateTime? lastWritten;
  _GroupedCollections({
    required this.film,
    required this.music,
    required this.written,
    required this.lastFilm,
    required this.lastMusic,
    required this.lastWritten,
  });
}
