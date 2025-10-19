// NYT Bestselling Books API Methods
// Cami Krugel
// 4 Hours

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/*
  NYTBook: Represents a book ranked in NYT
*/
class NYTBook {
  final String title;
  final String author;
  final String description;
  final int rank;
  final String? isbn;

  NYTBook({
    required this.title,
    required this.author,
    required this.description,
    required this.rank,
    this.isbn,
  });

  factory NYTBook.fromJson(Map<String, dynamic> json) => NYTBook(
    title: json['title'],
    author: json['author'],
    description: json['description'],
    rank: json['rank'],
    isbn: json['primary_isbn13'] ?? json['primary_isbn10'], // Prefer isbn 13
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'description': description,
    'rank': rank,
    'isbn': isbn
  };
}

/*
  Represents one of the NYT beststeller lists
*/
class NYTListInfo {
  final String listName;
  final String displayName;
  final List<NYTBook> books;

  NYTListInfo({
    required this.listName,
    required this.displayName,
    required this.books,
  });
}

/*
  Represents one of published dates
*/class NYTOverview {
  final String publishedDate;
  final String? previousPublishedDate;
  final List<NYTListInfo> lists;

  NYTOverview({
    required this.publishedDate,
    required this.previousPublishedDate,
    required this.lists,
  });

  factory NYTOverview.fromJson(Map<String, dynamic> data) {
    final lists = (data['results']['lists'] as List).map((list) {
      final books = (list['books'] as List).map((book) => NYTBook(
        title: book['title'],
        author: book['author'],
        description: book['description'],
        rank: book['rank'],
        isbn: book['primary_isbn13'] ?? book['primary_isbn10'], 
      )).toList();
      return NYTListInfo(
        listName: list['list_name_encoded'],
        displayName: list['display_name'],
        books: List<NYTBook>.from(books),
      );
    }).toList();
    return NYTOverview(
      publishedDate: data['results']['published_date'],
      previousPublishedDate: data['results']['previous_published_date'],
      lists: List<NYTListInfo>.from(lists),
    );
  }
}

class BooksService {
  //TODO remove hard coding
  static const String _apiKey = 'rDldRaR8evRrwrUCMqSZpPcTeANcR9Wp';
  static const String _baseUrl = 'https://api.nytimes.com/svc/books/v3';
  static const String _cacheKey = 'trending_books_cache';
  static const String _cacheDateKey = 'trending_books_cache_date';
  static const String _overviewCachePrefix = 'nyt_overview_';

  Future<List<NYTBook>> getTrendingBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastFetchStr = prefs.getString(_cacheDateKey);
    DateTime? lastFetch = lastFetchStr != null ? DateTime.tryParse(lastFetchStr) : null;

    // Find last Wednesday (NYT updates then)
    final lastWednesday = now.subtract(Duration(days: (now.weekday + 4) % 7));
    final isFresh = lastFetch != null && lastFetch.isAfter(lastWednesday);

    if (isFresh) { 
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        // Do not need to pull from API again
        final List decoded = json.decode(cached);
        return decoded.map((e) => NYTBook.fromJson(e)).toList();
      }
    }

    // Fetch from API
    final url = Uri.parse('$_baseUrl/lists/overview.json?api-key=$_apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {

      final data = json.decode(response.body);
      final lists = data['results']['lists'] as List;
      final books = <NYTBook>[];
      for (final list in lists) {
        for (final book in list['books']) {
          books.add(NYTBook(
            title: book['title'],
            author: book['author'],
            description: book['description'],
            rank: book['rank'],
            isbn: book['primary_isbn13'] ?? book['primary_isbn10'],
          ));
        }
      }
      prefs.setString(_cacheKey, json.encode(books.map((b) => b.toJson()).toList()));
      prefs.setString(_cacheDateKey, now.toIso8601String());
      return books;
    } else {
      throw Exception('Failed to load trending books');
    }
  }

  Future<NYTOverview> getOverview({String? publishedDate}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_overviewCachePrefix${publishedDate ?? "current"}';
    final cached = prefs.getString(cacheKey);

    if (cached != null) {
      final data = json.decode(cached);
      return NYTOverview.fromJson(data);
    }

    final url = Uri.parse(
      '$_baseUrl/lists/overview.json?api-key=$_apiKey'
      '${publishedDate != null ? '&published_date=$publishedDate' : ''}'
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      prefs.setString(cacheKey, json.encode(data));
      return NYTOverview.fromJson(data);
    } else {
      throw Exception('Failed to load overview');
    }
  }

  Future<List<Book>> fetchBooks(String title, String author, String subject) async {
    final titleQuery = Uri.encodeComponent(title);
    final authorQuery = Uri.encodeComponent(author);
    final subjectQuery = Uri.encodeComponent(subject);
    String url = 'https://openlibrary.org/search.json?language=eng&';
    if (title.isNotEmpty) url += 'title=$titleQuery&';
    if (author.isNotEmpty) url += 'author=$authorQuery&';
    if (subject.isNotEmpty) url += 'subject=$subjectQuery&';
    final response = await http.get(Uri.parse(url));
    final List<Book> possibleBooks = List.empty(growable: true);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final docs = data['docs'] as List;
      for (var doc in docs) {
        if (doc != null) {
          Book book = Book.fromSearchJson(doc);
          possibleBooks.add(book);
        }
      }
    }
    return possibleBooks;
  }

  Future<Book?> bookDetails(String id) async {
    final url = 'https://openlibrary.org/books/$id.json';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null) {
        final book = Book.fromEditionJson(data);
        return book;
      }
    }
    return null;
  }

  Future<List<String>> fetchAuthorNames(List authors) async {
    List<String> names = [];
    for (var author in authors) {
      final key = author['key'];
      final response = await http.get(Uri.parse('https://openlibrary.org$key.json'));
      if (response.statusCode == 200) {
        final authorData = json.decode(response.body);
        if (authorData['name'] != null) names.add(authorData['name']);
      }
    }
    return names;
  }
}

class Book {
  final String title;
  final List<String> authors;
  final String id; // OLID
  final List<String>? publishers;
  final List<String>? isbn10;
  final List<String>? isbn13;
  final String? publishDate;
  final int? pages;
  final List<String>? subjects;
  final String? weight;

  Book({
    required this.title,
    required this.authors,
    required this.id,
    this.publishers,
    this.isbn10,
    this.isbn13,
    this.publishDate,
    this.pages,
    this.subjects,
    this.weight,
  });

  // From search.json
  factory Book.fromSearchJson(Map<String, dynamic> json) {
    String? id = json['cover_edition_key'];
    if (id == null && json['edition_key'] != null && json['edition_key'] is List && json['edition_key'].isNotEmpty) {
      id = json['edition_key'][0];
    }
    return Book(
      title: json['title'] ?? '',
      authors: (json['author_name'] as List?)?.map((e) => e.toString()).toList() ?? [],
      id: id ?? '',
      publishers: (json['publisher'] as List?)?.map((e) => e.toString()).toList(),
      isbn10: (json['isbn_10'] as List?)?.map((e) => e.toString()).toList(),
      isbn13: (json['isbn_13'] as List?)?.map((e) => e.toString()).toList(),
      publishDate: json['first_publish_year']?.toString(),
      pages: null, // Not available in search.json
      subjects: (json['subject'] as List?)?.map((e) => e.toString()).toList(),
      weight: null,
    );
  }

  // From books/{OLID}.json
  factory Book.fromEditionJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? '',
      authors: [], // You can fetch author names separately if needed
      id: json['key'] != null ? (json['key'] as String).replaceAll('/books/', '') : '',
      publishers: (json['publishers'] as List?)?.map((e) => e.toString()).toList(),
      isbn10: (json['isbn_10'] as List?)?.map((e) => e.toString()).toList(),
      isbn13: (json['isbn_13'] as List?)?.map((e) => e.toString()).toList(),
      publishDate: json['publish_date'],
      pages: json['number_of_pages'],
      subjects: (json['subjects'] as List?)?.map((e) => e.toString()).toList(),
      weight: json['weight'],
    );
  }
}

void main() async {
  final service = BooksService();
}
