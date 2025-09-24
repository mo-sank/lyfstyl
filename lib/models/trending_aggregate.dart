import 'package:cloud_firestore/cloud_firestore.dart';

enum TrendingWindow { day, week }

class TrendingAggregate {
  final String aggregateId; // doc id
  final TrendingWindow window; // day/week
  final DateTime periodStart; // start of period
  final String type; // film/book/music
  final String? genre; // optional
  final List<String> topMediaIds; // ordered top items
  final DateTime generatedAt; // when this aggregate was generated

  TrendingAggregate({
    required this.aggregateId,
    required this.window,
    required this.periodStart,
    required this.type,
    this.genre,
    this.topMediaIds = const [],
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'window': window.name,
      'periodStart': Timestamp.fromDate(periodStart),
      'type': type,
      'genre': genre,
      'topMediaIds': topMediaIds,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }

  factory TrendingAggregate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TrendingAggregate(
      aggregateId: doc.id,
      window: (data['window'] == 'week') ? TrendingWindow.week : TrendingWindow.day,
      periodStart: (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: (data['type'] ?? 'film') as String,
      genre: data['genre'] as String?,
      topMediaIds: (data['topMediaIds'] as List<dynamic>? ?? []).cast<String>(),
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
