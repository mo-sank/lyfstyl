import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/log_entry.dart';
import '../../models/media_item.dart';
import '../../widgets/media_cover.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  late Future<_LogsWithMedia> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LogsWithMedia> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final svc = context.read<FirestoreService>();
    final logs = await svc.getUserLogs(uid);
    final mediaIds = logs.map((l) => l.mediaId).toSet().toList();
    final mediaMap = await svc.getMediaByIds(mediaIds);
    return _LogsWithMedia(logs: logs, mediaById: mediaMap);
  }

  Future<void> _delete(String id) async {
    await context.read<FirestoreService>().deleteLog(id);
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Activity')),
      body: FutureBuilder<_LogsWithMedia>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final logs = data.logs;
          if (logs.isEmpty) {
            return const Center(child: Text('No logs yet'));
          }
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              final media = data.mediaById[log.mediaId];
              final title = media?.title ?? log.mediaId;
              final type = media?.type.name.toUpperCase();
              return ListTile(
                leading: MediaCover(
                  media: media,
                  fallbackType: media?.type ?? log.mediaType,
                ),
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (type != null)
                      Text(
                        type,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    if (log.rating != null)
                      Text('Rating: ${log.rating!.toStringAsFixed(1)}'),
                    if (log.review != null && log.review!.isNotEmpty)
                      Text(
                        log.review!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      'Consumed: ${log.consumedAt.toLocal().toString().split(' ').first}',
                    )
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(log.logId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LogsWithMedia {
  final List<LogEntry> logs;
  final Map<String, MediaItem> mediaById;
  _LogsWithMedia({required this.logs, required this.mediaById});
}
