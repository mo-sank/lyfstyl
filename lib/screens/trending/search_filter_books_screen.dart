// Trending Books
// Cami Krugel
// 6 Hours

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lyfstyl/models/media_item.dart';
import '../../services/books_service.dart';
import '../logs/add_log_screen.dart';
import '../../models/book.dart';
import '../../theme/media_type_theme.dart';

class SearchBooksScreen extends StatefulWidget {
  const SearchBooksScreen({super.key});

  @override
  State<SearchBooksScreen> createState() => _SearchBooksScreenState();
}

class _SearchBooksScreenState extends State<SearchBooksScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _authorCtrl = TextEditingController();
  final List<String> _subjects = [
    'Fiction',
    'Nonfiction',
    'Science',
    'Fantasy',
    'Biography',
    'History',
    'Mystery',
    'Romance',
    'Children',
    'Young Adult',
  ];

  String _currentMode = 'browse'; // 'browse' or 'search'
  String? _selectedSubject;
  List<Book> _results = [];
  bool _isSearching = false;
  final BooksService _service = BooksService();
  Timer? _debounce;

  void _switchToBrowse() {
    setState(() {
      _currentMode = 'browse';
      _selectedSubject = null;
      _results = [];
      _titleCtrl.clear();
      _authorCtrl.clear();
    });
  }

  void _switchToSearch() {
    setState(() {
      _currentMode = 'search';
      _selectedSubject = null;
      _results = [];
      _titleCtrl.clear();
      _authorCtrl.clear();
    });
  }

  Future<void> _browseBySubject(String subject) async {
    setState(() {
      _isSearching = true;
      _selectedSubject = subject;
      _results = [];
    });
    List<Book> books = await _service.fetchBooks('', '', subject);
    int count = 0;
    while (books.isEmpty && count < 3){
      count++;
      books = await _service.fetchBooks('', '', subject);
    }
    setState(() {
      _results = books;
      _isSearching = false;
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final title = _titleCtrl.text.trim();
      final author = _authorCtrl.text.trim();
      if (title.isNotEmpty || author.isNotEmpty) {
        setState(() {
          _isSearching = true;
          _results = [];
        });
        final books = await _service.fetchBooks(title, author, '');
        setState(() {
          _results = books;
          _isSearching = false;
        });
      } else {
        setState(() {
          _results = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Books')),
      body: Column(
        children: [
          // Mode Toggle
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _switchToBrowse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentMode == 'browse' ? Colors.blue : Colors.grey[300],
                      foregroundColor: _currentMode == 'browse' ? Colors.white : Colors.black,
                    ),
                    child: const Text('Browse by Subject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _switchToSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentMode == 'search' ? Colors.blue : Colors.grey[300],
                      foregroundColor: _currentMode == 'search' ? Colors.white : Colors.black,
                    ),
                    child: const Text('Search Specific'),
                  ),
                ),
              ],
            ),
          ),
          if (_currentMode == 'browse')
            // Subject Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.map((subject) {
                  return ChoiceChip(
                    label: Text(subject),
                    selected: _selectedSubject == subject,
                    onSelected: (selected) {
                      if (selected) _browseBySubject(subject);
                    },
                  );
                }).toList(),
              ),
            ),
          if (_currentMode == 'search')
            // Search Bar for Title and Author
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search for books by title...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (_) => _onSearchChanged(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search for books by author...',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (_) => _onSearchChanged(),
                  ),
                ],
              ),
            ),
          // Results Section
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _currentMode == 'browse'
                              ? 'Choose a subject to discover books'
                              : 'Search for specific books',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return ListTile(
                            leading: item.id.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      'https://covers.openlibrary.org/b/olid/${item.id}-M.jpg?default=false',
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey[300],
                                          child: Icon(MediaType.book.icon, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(MediaType.book.icon, color: Colors.grey),
                                  ),
                            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(item.authors != null ? item.authors![0] : '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: 'Add Log',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AddLogScreen(
                                      preFilledData: {
                                        'title': item.title,
                                        'type': 'book',
                                        'creator': (item.authors != null ? item.authors!.join(', ') : ''),
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
