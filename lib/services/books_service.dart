import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NYTBook {
  final String title;
  final String author;
  final String description;
  final int rank;
  final String? coverUrl;
  final String? isbn; // <-- add this

  NYTBook({
    required this.title,
    required this.author,
    required this.description,
    required this.rank,
    this.coverUrl,
    this.isbn,
  });

  factory NYTBook.fromJson(Map<String, dynamic> json) => NYTBook(
    title: json['title'],
    author: json['author'],
    description: json['description'],
    rank: json['rank'],
    coverUrl: json['book_image'],
    isbn: json['primary_isbn13'] ?? json['primary_isbn10'],
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'description': description,
    'coverUrl': coverUrl,
    'rank': rank
  };
}

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

class NYTOverview {
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
        coverUrl: book['book_image'],
        rank: book['rank'],
        isbn: book['primary_isbn13'] ?? book['primary_isbn10'], // <-- ADD THIS LINE
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
            coverUrl: book['book_image'],
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
    print('NYT API status: ${response.statusCode}');
    print('NYT API body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      prefs.setString(cacheKey, json.encode(data));
      return NYTOverview.fromJson(data);
    } else {
      throw Exception('Failed to load overview');
    }
  }



/// Returns a Google Books thumbnail URL for the given title/author, or null if not found.


}

void main() async {
  final _service = BooksService();
}
