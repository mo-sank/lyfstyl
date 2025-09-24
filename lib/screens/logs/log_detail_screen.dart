import 'package:flutter/material.dart';
import '../../models/log_entry.dart';
import '../../models/media_item.dart';
import 'edit_log_screen.dart';

class LogDetailScreen extends StatelessWidget {
  final MediaItem media;
  final LogEntry log;
  const LogDetailScreen({super.key, required this.media, required this.log});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditLogScreen(media: media, log: log)),
              );
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          )
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
                      child: media.coverUrl != null
                          ? Image.network(media.coverUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(media.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(media.type.name.toUpperCase(), style: const TextStyle(color: Colors.grey)),
                          if (media.creator != null && media.creator!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(media.creator!),
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
}
