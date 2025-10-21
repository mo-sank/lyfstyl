// maya poghosyan

import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/models/nyt_book.dart';
import 'package:lyfstyl/models/book.dart';

void main() {
  group('NYTBook', () {
    test('should create NYTBook with required fields', () {
      final book = NYTBook(
        title: 'Test Book',
        author: 'Test Author',
        description: 'A test book description',
        rank: 1,
      );

      expect(book.title, 'Test Book');
      expect(book.author, 'Test Author');
      expect(book.description, 'A test book description');
      expect(book.rank, 1);
      expect(book.isbn, isNull);
    });

    test('should create NYTBook with ISBN', () {
      final book = NYTBook(
        title: 'Test Book',
        author: 'Test Author',
        description: 'Description',
        rank: 2,
        isbn: '9781234567890',
      );

      expect(book.isbn, '9781234567890');
    });

    test('should create from JSON correctly', () {
      final json = {
        'title': 'JSON Book',
        'author': 'JSON Author',
        'description': 'JSON Description',
        'rank': 3,
        'primary_isbn13': '9780987654321',
      };

      final book = NYTBook.fromJson(json);
      expect(book.title, 'JSON Book');
      expect(book.author, 'JSON Author');
      expect(book.description, 'JSON Description');
      expect(book.rank, 3);
      expect(book.isbn, '9780987654321');
    });

    test('should prefer ISBN13 over ISBN10', () {
      final json = {
        'title': 'Book',
        'author': 'Author',
        'description': 'Description',
        'rank': 1,
        'primary_isbn13': '9781111111111',
        'primary_isbn10': '1111111111',
      };

      final book = NYTBook.fromJson(json);
      expect(book.isbn, '9781111111111');
    });

    test('should fallback to ISBN10 when ISBN13 not available', () {
      final json = {
        'title': 'Book',
        'author': 'Author',
        'description': 'Description',
        'rank': 1,
        'primary_isbn10': '1111111111',
      };

      final book = NYTBook.fromJson(json);
      expect(book.isbn, '1111111111');
    });

    test('should serialize to JSON correctly', () {
      final book = NYTBook(
        title: 'Serialize Book',
        author: 'Serialize Author',
        description: 'Serialize Description',
        rank: 5,
        isbn: '9785555555555',
      );

      final json = book.toJson();
      expect(json['title'], 'Serialize Book');
      expect(json['author'], 'Serialize Author');
      expect(json['description'], 'Serialize Description');
      expect(json['rank'], 5);
      expect(json['isbn'], '9785555555555');
    });
  });

  group('Book', () {
    test('should create from search JSON', () {
      final json = {
        'title': 'Search Book',
        'author_name': ['Author One', 'Author Two'],
        'cover_edition_key': 'OL123456M',
        'publisher': ['Publisher One', 'Publisher Two'],
        'isbn_10': ['1234567890'],
        'isbn_13': ['9781234567890'],
        'first_publish_year': 2020,
        'subject': ['Fiction', 'Drama'],
      };

      final book = Book.fromSearchJson(json);
      expect(book.title, 'Search Book');
      expect(book.authors, ['Author One', 'Author Two']);
      expect(book.id, 'OL123456M');
      expect(book.publishers, ['Publisher One', 'Publisher Two']);
      expect(book.isbn10, ['1234567890']);
      expect(book.isbn13, ['9781234567890']);
      expect(book.publishDate, '2020');
      expect(book.subjects, ['Fiction', 'Drama']);
    });

    test('should handle missing cover_edition_key', () {
      final json = {
        'title': 'No Cover Book',
        'author_name': ['Author'],
        'edition_key': ['OL111111M', 'OL222222M'],
      };

      final book = Book.fromSearchJson(json);
      expect(book.id, 'OL111111M');
    });

    test('should create from edition JSON', () {
      final json = {
        'title': 'Edition Book',
        'key': '/books/OL987654M',
        'publishers': ['Edition Publisher'],
        'isbn_10': ['0987654321'],
        'isbn_13': ['9780987654321'],
        'publish_date': 'January 2021',
        'number_of_pages': 300,
        'subjects': ['Non-fiction'],
        'weight': '1.2 pounds',
      };

      final book = Book.fromEditionJson(json);
      expect(book.title, 'Edition Book');
      expect(book.id, 'OL987654M');
      expect(book.publishers, ['Edition Publisher']);
      expect(book.isbn10, ['0987654321']);
      expect(book.isbn13, ['9780987654321']);
      expect(book.publishDate, 'January 2021');
      expect(book.pages, 300);
      expect(book.subjects, ['Non-fiction']);
      expect(book.weight, '1.2 pounds');
    });

    test('should handle empty or null fields', () {
      final json = <String, dynamic>{};
      final book = Book.fromSearchJson(json);
      
      expect(book.title, '');
      expect(book.authors, isEmpty);
      expect(book.id, '');
      expect(book.publishers, isNull);
      expect(book.isbn10, isNull);
      expect(book.isbn13, isNull);
    });
  });
}