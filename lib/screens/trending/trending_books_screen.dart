// Trending Books
// Cami Krugel
// 5 Hours

import 'package:flutter/material.dart';
import '../../services/books_service.dart';
import '../logs/add_log_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/nyt_book.dart';

class TrendingBooksScreen extends StatefulWidget {
  const TrendingBooksScreen({super.key});

  @override
  State<TrendingBooksScreen> createState() => _TrendingBooksScreenState();
}

class _TrendingBooksScreenState extends State<TrendingBooksScreen> {
  final TextEditingController _keywordsCtrl = TextEditingController();
  final BooksService _service = BooksService();
  Future<NYTOverview>? _futureOverview;
  String? _selectedDate;
  String? _selectedListName;
  List<String> _allDates = [];
  List<NYTListInfo> _allLists = [];
  List<NYTBook> _displayBooks = [];
  List<NYTBook> _filtered = [];

  Widget _noCoverWidget(NYTBook item) => Container(
  width: 56,
  height: 56,
  decoration: BoxDecoration(
    color: Colors.grey[300],
    borderRadius: BorderRadius.circular(8),
  ),
  child: Center(
    child: Text(
      item.isbn == null || item.isbn!.isEmpty ? 'No ISBN' : 'No Cover',
      style: const TextStyle(fontSize: 10, color: Colors.grey),
      textAlign: TextAlign.center,
    ),
  ),
);


  @override
  void initState() {
    super.initState();
    _initDatesAndOverview();
    _keywordsCtrl.addListener(_applyFilter);
  }

  Future<void> _initDatesAndOverview() async {
    final currentOverview = await _service.getOverview();
    final currentDate = currentOverview.publishedDate;
    final prevDate = currentOverview.previousPublishedDate;

    List<String> dates = [currentDate];
    if (prevDate != null) dates.add(prevDate);

    setState(() {
      _allDates = dates;
      _selectedDate = dates.first;
      _futureOverview = _loadOverview(date: dates.first);
    });
  }

  Future<NYTOverview> _loadOverview({String? date}) async {
    final overview = await _service.getOverview(publishedDate: date);
    setState(() {
      _selectedDate = overview.publishedDate;
      _allLists = overview.lists;
      _selectedListName = overview.lists.isNotEmpty ? overview.lists.first.listName : null;
      _displayBooks = overview.lists.isNotEmpty ? overview.lists.first.books : [];
      _filtered = _displayBooks;
      _allDates = [overview.publishedDate]; // You can extend this to fetch more dates if needed
    });
    return overview;
  }

  Future<List<String>> _fetchAvailableDates({int weeks = 10}) async {
    List<String> dates = [];
    String? date;
    for (int i = 0; i < weeks; i++) {
      final overview = await _service.getOverview(publishedDate: date);
      dates.add(overview.publishedDate);
      date = overview.previousPublishedDate;
      if (date == null) break;
    }
    return dates;
  }

  void _onDateChanged(String? date) async {
    if (date == null) return;
    final overview = await _service.getOverview(publishedDate: date);
    setState(() {
      _selectedDate = overview.publishedDate;
      _allLists = overview.lists;
      _selectedListName = overview.lists.isNotEmpty ? overview.lists.first.listName : null;
      _displayBooks = overview.lists.isNotEmpty ? overview.lists.first.books : [];
      _filtered = _displayBooks;
    });
    _applyFilter();
  }

  void _onListChanged(String? listName) {
    if (listName == null) return;
    final list = _allLists.firstWhere((l) => l.listName == listName);
    setState(() {
      _selectedListName = listName;
      _displayBooks = list.books;
      _filtered = _displayBooks;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final ks = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() {
      _filtered = ks.isEmpty

          ? _displayBooks
          : _displayBooks.where((item) =>
              ks.any((k) =>
                item.title.toLowerCase().contains(k) ||
                item.author.toLowerCase().contains(k) ||
                item.description.toLowerCase().contains(k)
              )).toList();
    });
  }

  void _logTrendingItem(BuildContext context, NYTBook item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddLogScreen(
          preFilledData: {
            'title': item.title,
            'type': 'book',
            'creator': item.author,
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keywordsCtrl.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trending Books')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<NYTOverview>(
          future: _futureOverview,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final overview = snapshot.data!;
            final lists = overview.lists;

            return Column(
              children: [
                // Date Dropdown
                DropdownButton<String>(
                  value: _selectedDate,
                  items: _allDates.map((date) => DropdownMenuItem(
                    value: date,
                    child: Text(date),
                  )).toList(),
                  onChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                      _futureOverview = _loadOverview(date: date);
                    });
                  },
                  hint: const Text('Select Date'),
                ),
                // List Dropdown
                DropdownButton<String>(
                  value: _selectedListName,
                  items: lists.map((l) => DropdownMenuItem(
                    value: l.listName,
                    child: Text(l.displayName),
                  )).toList(),
                  onChanged: _onListChanged,
                  hint: const Text('Select List'),
                ),
                // Filter by keyword
                TextField(
                  controller: _keywordsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Filter by keywords (comma separated)',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No results. Try different keywords.'))
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _filtered[index];
                            if (item.isbn == null || item.isbn!.isEmpty) {
                              print('No ISBN for book: ${item.title} by ${item.author}');
                            }
                            return ListTile(
                              leading: FutureBuilder<String?>(
                                future: _service.getBestCoverUrl(item),
                                builder: (context, snapshot) {
                                  final url = snapshot.data;
                                  if (url != null) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Cover failed for ${item.title}: $error');
                                          return _noCoverWidget(item);
                                        },
                                      ),
                                    );
                                  } else {
                                    return _noCoverWidget(item);
                                  }
                                },
                              ),
                              title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(item.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(item.rank.toString()),
                                    backgroundColor: Colors.blue[50],
                                    labelStyle: const TextStyle(fontSize: 10),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                    onPressed: () => _logTrendingItem(context, item),
                                    tooltip: 'Log this book',
                                  ),
                                ],
                              ),
                              onTap: () async {
                                // Use title and author to search Open Library
                                final books = await _service.fetchBooks(item.title, item.author, '');
                                if (books.isNotEmpty && context.mounted) {
                                  final book = books.first;
                                  final details = await _service.bookDetails(book.id);
                                  final bookToShow = details ?? book;

                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        bookToShow.title.isNotEmpty ? bookToShow.title : item.title,
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (bookToShow.id.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 12.0),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    'https://covers.openlibrary.org/b/olid/${bookToShow.id}-L.jpg?default=false',
                                                    width: 120,
                                                    height: 180,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 120,
                                                        height: 180,
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.book, color: Colors.grey, size: 48),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            // Authors: fallback to NYT if Open Library is empty
                                            if (bookToShow.authors != null)
                                              Text('Authors: ${bookToShow.authors!.join(", ")}')
                                            else if (item.author.isNotEmpty)
                                              Text('Authors: ${item.author}'),
                                            if (bookToShow.publishers != null)
                                              Text('Publishers: ${bookToShow.publishers!.join(", ")}'),
                                            if (bookToShow.publishDate != null)
                                              Text('Published: ${bookToShow.publishDate}'),
                                            if (bookToShow.pages != null)
                                              Text('Pages: ${bookToShow.pages}'),
                                            if (bookToShow.subjects != null)
                                              Text('Subjects: ${bookToShow.subjects!.join(", ")}'),
                                            if (bookToShow.weight != null)
                                              Text('Weight: ${bookToShow.weight}'),
                                            if (bookToShow.isbn13 != null)
                                              Text('ISBN-13: ${bookToShow.isbn13!.join(", ")}'),
                                            if (bookToShow.isbn10 != null)
                                              Text('ISBN-10: ${bookToShow.isbn10!.join(", ")}'),
                                            // NYT Description fallback
                                            if ((bookToShow.subjects == null || bookToShow.subjects!.isEmpty) && item.description.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text('Description: ${item.description}'),
                                              ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Close'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => AddLogScreen(
                                                  preFilledData: {
                                                    'title': bookToShow.title.isNotEmpty ? bookToShow.title : item.title,
                                                    'type': 'book',
                                                    'creator': (bookToShow.authors != null
                                                        ? bookToShow.authors?.join(', ')
                                                        : item.author),
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Add Log'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  // Optionally show a message if no Open Library match found
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(item.title),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (item.author.isNotEmpty)
                                            Text('Authors: ${item.author}'),
                                          if (item.description.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text('Description: ${item.description}'),
                                            ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },

                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
