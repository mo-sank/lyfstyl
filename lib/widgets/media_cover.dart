import 'package:flutter/material.dart';

import '../models/media_item.dart';

class MediaCover extends StatelessWidget {
  final MediaItem? media;
  final MediaType fallbackType;
  final double size;

  const MediaCover({
    super.key,
    required this.media,
    required this.fallbackType,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = media?.coverUrl;
    final type = media?.type ?? fallbackType;

    if (coverUrl != null && coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          coverUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(type),
        ),
      );
    }

    return _placeholder(type);
  }

  Widget _placeholder(MediaType type) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        type.icon,
        color: type.color,
        size: size * 0.5,
      ),
    );
  }
}

