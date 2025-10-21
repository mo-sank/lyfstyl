// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('should create UserProfile with required fields', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user-id',
        email: 'test@example.com',
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.userId, 'user-id');
      expect(profile.email, 'test@example.com');
      expect(profile.displayName, isNull);
      expect(profile.interests, isEmpty);
      expect(profile.favoriteIds, isEmpty);
      expect(profile.isPublic, isTrue);
    });

    test('should create UserProfile with all fields', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        username: 'testuser',
        bio: 'Test bio',
        interests: ['movies', 'books'],
        favoriteIds: ['media1', 'media2'],
        isPublic: false,
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.displayName, 'Test User');
      expect(profile.username, 'testuser');
      expect(profile.bio, 'Test bio');
      expect(profile.interests, ['movies', 'books']);
      expect(profile.favoriteIds, ['media1', 'media2']);
      expect(profile.isPublic, isFalse);
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        interests: ['music', 'films'],
        favoriteIds: ['fav1'],
        isPublic: false,
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['email'], 'test@example.com');
      expect(map['displayName'], 'Test User');
      expect(map['interests'], ['music', 'films']);
      expect(map['favoriteIds'], ['fav1']);
      expect(map['isPublic'], false);
      expect(map.containsKey('userId'), false);
    });

    test('should handle empty lists and null values', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user-id',
        email: 'test@example.com',
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['displayName'], isNull);
      expect(map['username'], isNull);
      expect(map['bio'], isNull);
      expect(map['avatarUrl'], isNull);
      expect(map['interests'], isEmpty);
      expect(map['favoriteIds'], isEmpty);
      expect(map['isPublic'], true);
    });
  });
}