// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/models/collection.dart';

void main() {
  group('CollectionModel', () {
    test('should create collection with required fields', () {
      final now = DateTime.now();
      final collection = CollectionModel(
        collectionId: 'collection-id',
        userId: 'user-id',
        name: 'My Favorites',
        createdAt: now,
        updatedAt: now,
      );

      expect(collection.collectionId, 'collection-id');
      expect(collection.userId, 'user-id');
      expect(collection.name, 'My Favorites');
      expect(collection.itemIds, isEmpty);
    });

    test('should create collection with item IDs', () {
      final now = DateTime.now();
      final collection = CollectionModel(
        collectionId: 'collection-id',
        userId: 'user-id',
        name: 'Watchlist',
        itemIds: ['movie1', 'movie2', 'book1'],
        createdAt: now,
        updatedAt: now,
      );

      expect(collection.itemIds, ['movie1', 'movie2', 'book1']);
      expect(collection.itemIds.length, 3);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final collection = CollectionModel(
        collectionId: 'collection-id',
        userId: 'user-id',
        name: 'Test Collection',
        itemIds: ['item1', 'item2'],
        createdAt: now,
        updatedAt: now,
      );

      final map = collection.toMap();
      expect(map['userId'], 'user-id');
      expect(map['name'], 'Test Collection');
      expect(map['itemIds'], ['item1', 'item2']);
      expect(map.containsKey('collectionId'), false);
    });

    test('should handle empty item list', () {
      final now = DateTime.now();
      final collection = CollectionModel(
        collectionId: 'empty-collection',
        userId: 'user-id',
        name: 'Empty Collection',
        createdAt: now,
        updatedAt: now,
      );

      final map = collection.toMap();
      expect(map['itemIds'], isEmpty);
    });
  });
}