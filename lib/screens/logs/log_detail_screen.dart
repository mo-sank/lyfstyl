import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/log_entry.dart';
import '../../models/media_item.dart';
import '../../models/collection.dart';
import '../../services/firestore_service.dart';
import 'edit_log_screen.dart';

class LogDetailScreen extends StatefulWidget {
  final MediaItem media;
  final LogEntry log;

  const LogDetailScreen({super.key, required this.media, required this.log});

  @override
  State<LogDetailScreen> createState() => _LogDetailScreenState();
}

class _LogDetailScreenState extends State<LogDetailScreen> {
  late LogEntry log;

  @override
  void initState() {
    super.initState();
    log = widget.log;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => _showAddToCollectionDialog(context, widget.media),
            tooltip: 'Add to Collection',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editLog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      color: Colors.grey[200],
                      child: widget.media.coverUrl != null
                          ? Image.network(widget.media.coverUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.media.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.media.type.name.toUpperCase(), style: const TextStyle(color: Colors.grey)),
                          if (widget.media.creator != null && widget.media.creator!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(widget.media.creator!),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (log.rating != null)
                  Text('Rating: ${log.rating!.toStringAsFixed(1)}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Consumed: ${log.consumedAt.toLocal().toString().split(' ').first}'),
                const SizedBox(height: 12),
                if (log.tags.isNotEmpty) ...[
                  const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: log.tags.map((t) => Chip(label: Text(t))).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (log.review != null && log.review!.isNotEmpty) ...[
                  const Text('Review', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(log.review!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editLog() async {
    final updatedLog = await Navigator.of(context).push<LogEntry>(
      MaterialPageRoute(builder: (_) => EditLogScreen(media: widget.media, log: log)),
    );

    if (updatedLog != null && context.mounted) {
      setState(() {
        log = updatedLog;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log updated!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddToCollectionDialog(BuildContext context, MediaItem media) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final svc = context.read<FirestoreService>();

    try {
      final collections = await svc.getUserCollections(uid);

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add to Collection'),
            content: collections.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.collections_bookmark_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No collections yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first collection to organize your media!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: collections.length,
                      itemBuilder: (context, index) {
                        final collection = collections[index];
                        final isInCollection = collection.itemIds.contains(media.mediaId);

                        return ListTile(
                          leading: Icon(
                            isInCollection ? Icons.bookmark : Icons.bookmark_border,
                            color: isInCollection ? Colors.blue : Colors.grey,
                          ),
                          title: Text(
                            collection.name,
                            style: TextStyle(
                              fontWeight: isInCollection ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('${collection.itemIds.length} items'),
                          trailing: isInCollection
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                          onTap: () async {
                            try {
                              if (isInCollection) {
                                await svc.removeMediaFromCollection(
                                  collection.collectionId,
                                  media.mediaId,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Removed from ${collection.name}'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } else {
                                await svc.addMediaToCollection(
                                  collection.collectionId,
                                  media.mediaId,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added to ${collection.name}'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }

                              final updatedCollections = await svc.getUserCollections(uid);
                              setState(() {
                                collections.clear();
                                collections.addAll(updatedCollections);
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
            actions: [
              if (collections.isEmpty)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showCreateCollectionDialog(context, media);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Collection'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading collections: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateCollectionDialog(BuildContext context, MediaItem media) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Collection Name',
            hintText: 'e.g., Favorites, Watch Later',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => _createCollection(context, dialogContext, controller, media),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _createCollection(context, dialogContext, controller, media),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCollection(
      BuildContext context,
      BuildContext dialogContext,
      TextEditingController controller,
      MediaItem media) async {
    if (controller.text.trim().isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final svc = context.read<FirestoreService>();

    try {
      final collectionId = await svc.createCollectionByName(uid, controller.text.trim());

      await svc.addMediaToCollection(collectionId, media.mediaId);

      if (context.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collection "${controller.text.trim()}" created and media added!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating collection: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
