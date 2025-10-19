// NYT Bestselling Books API Methods
// Cami Krugel
// 4 Hours

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../models/nyt_book.dart';

class BooksService {
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

  Future<String?> fetchOpenLibraryCoverByTitleAuthor(String title, String author) async {
  final titleQuery = Uri.encodeComponent(title);
  final authorQuery = Uri.encodeComponent(author);
  final url = 'https://openlibrary.org/search.json?title=$titleQuery&author=$authorQuery';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final docs = data['docs'] as List?;
    if (docs != null && docs.isNotEmpty) {
      final doc = docs.first;
      // Try cover_i first
      if (doc['cover_i'] != null) {
        return 'https://covers.openlibrary.org/b/id/${doc['cover_i']}-L.jpg?default=false';
      }
      // Try ISBNs from search result
      if (doc['isbn'] != null && doc['isbn'] is List && doc['isbn'].isNotEmpty) {
        return 'https://covers.openlibrary.org/b/isbn/${doc['isbn'][0]}-L.jpg?default=false';
      }
    }
  }
  return null;
}

Future<String?> getBestCoverUrl(NYTBook item) async {
  // Try ISBN cover first with default=false
  if (item.isbn?.isNotEmpty ?? false) {
    final isbnUrl = 'https://covers.openlibrary.org/b/isbn/${item.isbn}-L.jpg?default=false';
    final resp = await http.head(Uri.parse(isbnUrl));
    if (resp.statusCode == 200) {
      return isbnUrl;
    }
  }
  // Fallback to title/author search
  return await fetchOpenLibraryCoverByTitleAuthor(item.title, item.author);
}

void main() async {
  final _service = BooksService();
}
