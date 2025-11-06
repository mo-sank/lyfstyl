import 'package:flutter/material.dart';
import '../models/media_item.dart';

extension MediaTypeTheme on MediaType {
  Color get color {
    switch (this) {
      case MediaType.film:
        return const Color(0xFFFF6F61);
      case MediaType.show:
        return const Color(0xFFFF6F61);
      case MediaType.book:
        return const Color(0xFFFFC857);
      case MediaType.album:
        return Color(0xFF00C2A8);
      case MediaType.song:
        return Color(0xFF00C2A8);
      case MediaType.music:
        return Color(0xFF00C2A8);
      default:
        return const Color(0xFF3B82F6); // blue fallback
    }
  }

  IconData get icon {
    switch (this) {
      case MediaType.film:
        return Icons.movie;
      case MediaType.show:
        return Icons.movie;
      case MediaType.book:
        return Icons.menu_book;
      case MediaType.album:
        return Icons.music_note;
      case MediaType.song:
        return Icons.music_note;
      case MediaType.music:
        return Icons.music_note;
      default:
        return Icons.device_unknown;
    }
  }
}