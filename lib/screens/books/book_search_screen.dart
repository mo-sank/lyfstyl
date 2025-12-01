// Trending Books
// Cami Krugel
// 6 Hours

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lyfstyl/models/media_item.dart';
import '../../services/books_service.dart';
import '../../services/firestore_service.dart';
import '../logs/add_log_screen.dart';
import '../../models/book.dart';
import '../../widgets/fun_loading_widget.dart';

class SearchBooksScreen extends StatefulWidget {
  const SearchBooksScreen({super.key});

  @override
  State<SearchBooksScreen> createState() => _SearchBooksScreenState();
}

class _SearchBooksScreenState extends State<SearchBooksScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late BooksService _service;
  Future<List<Book>>? _searchFuture;
  Future<List<Book>>? _subjectFuture;
  List<Book> _searchResults = [];
  List<Book> _subjectResults = [];
  bool _isSearching = false;
  bool _isLoadingSubject = false;

  // Mode: 'search' or 'browse'
  String _currentMode = 'browse';
  String? _selectedSubject;

  // Search type: 'title' or 'author'
  String _searchType = 'title';

  // Popular subjects for browsing
  static const List<String> _popularSubjects = [
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

  @override
  void initState() {
    super.initState();
    _service = BooksService();
  }

  Future<void> _searchBooks() async {
    if (_searchCtrl.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _currentMode = 'search';
      _searchFuture = _performSearch();
    });
  }

  Future<List<Book>> _performSearch() async {
    try {
      final query = _searchCtrl.text.trim();
      if (_searchType == 'title') {
        return await _service.fetchBooks(query, '', '');
      } else {
        return await _service.fetchBooks('', query, '');
      }
    } catch (e) {
      print('Search error: $e');
      return [];
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _browseBySubject(String subject) async {
    setState(() {
      _isLoadingSubject = true;
      _currentMode = 'browse';
      _selectedSubject = subject;
      _subjectFuture = _performSubjectBrowse(subject);
    });
  }

  Future<List<Book>> _performSubjectBrowse(String subject) async {
    try {
      final results = await _service.fetchBooks('', '', subject);
      _subjectResults = results;
      return results;
    } catch (e) {
      print('Subject browse error: $e');
      return [];
    } finally {
      setState(() => _isLoadingSubject = false);
    }
  }

  void _switchToBrowse() {
    setState(() {
      _currentMode = 'browse';
      _searchCtrl.clear();
      _searchResults = [];
      _searchFuture = null;
    });
  }

  void _switchToSearch() {
    setState(() {
      _currentMode = 'search';
      _subjectResults = [];
      _subjectFuture = null;
    });
  }

  void _logSearchResult(BuildContext context, Book item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddLogScreen(
          preFilledData: {
            'title': item.title,
            'type': 'book',
            'creator': (item.authors != null ? item.authors!.join(', ') : ''),
            'bookData': {
              'subjects': item.subjects,
              'publishDate': item.publishDate,
              'id': item.id,
            },
            // We don't have a direct cover here; FirestoreService can enrich later.
          },
        ),
      ),
    );
  }

  Future<void> _bookmarkBook(Book item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save bookmarks')),
      );
      return;
    }

    final firestore = context.read<FirestoreService>();

    try {
      final coverUrl = await _service.fetchOpenLibraryCoverByTitleAuthor(
        item.title,
        item.authors?.isNotEmpty == true ? item.authors!.first : '',
      );

      await firestore.bookmarkMedia(
        userId: user.uid,
        mediaType: MediaType.book,
        title: item.title,
        creator: item.authors?.isNotEmpty == true ? item.authors!.first : null,
        coverUrl: coverUrl,
        metadata: {
          'bookId': item.id,
          'subjects': item.subjects,
          'publishDate': item.publishDate,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to bookmarks')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to bookmark book')));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Books'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Mode Toggle
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildModeButton(
                    'browse',
                    'Browse by Genre',
                    Icons.category,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeButton(
                    'search',
                    'Search Specific',
                    Icons.search,
                  ),
                ),
              ],
            ),
          ),

          // Content based on mode
          if (_currentMode == 'browse') _buildBrowseContent(),
          if (_currentMode == 'search') _buildSearchContent(),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String label, IconData icon) {
    final isSelected = _currentMode == mode;
    return ElevatedButton(
      onPressed: () {
        if (mode == 'browse') {
          _switchToBrowse();
        } else {
          _switchToSearch();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Color(0xFF9B5DE5): Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
      ),
    );
  }

  Widget _buildBrowseContent() {
    return Expanded(
      child: Column(
        children: [
          // Subject Selection
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a genre to discover books',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _popularSubjects.map((subject) {
                    return _buildSubjectChip(subject);
                  }).toList(),
                ),
              ],
            ),
          ),

          // Results
          Expanded(child: _buildBrowseResults()),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search for books by title or author...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _searchFuture = null;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onSubmitted: (_) => _searchBooks(),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _searchBooks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9B5DE5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Search'),
                    ),
                  ],
                ),
                // Move the toggle below the text input
                Row(
                  children: [
                    Radio<String>(
                      value: 'title',
                      groupValue: _searchType,
                      onChanged: (val) {
                        setState(() => _searchType = val!);
                      },
                    ),
                    const Text('Title'),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'author',
                      groupValue: _searchType,
                      onChanged: (val) {
                        setState(() => _searchType = val!);
                      },
                    ),
                    const Text('Author'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for specific books by title or author',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Search Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSubjectChip(String subject) {
    return ActionChip(
      label: Text(subject.toUpperCase()),
      onPressed: () => _browseBySubject(subject),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: MediaType.book.color,
        fontWeight: FontWeight.w500,
      ),
      avatar: Icon(MediaType.book.icon, size: 16, color: MediaType.book.color),
    );
  }

  Widget _buildBrowseResults() {
    if (_subjectFuture == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Choose a subject to discover books',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any subject above to see trending and popular books',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Book>>(
      future: _subjectFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            _isLoadingSubject) {
          return FunLoadingWidget(
            messages: FunLoadingWidget.bookMessages,
            color: MediaType.book.color,
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _browseBySubject('Fiction'), // Retry with Fiction
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No books found for this subject',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting a different subject',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Subject header
            if (_selectedSubject != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Color(0xFF9B5DE5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(MediaType.book.icon, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedSubject!.toUpperCase()} Books',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${results.length} books - trending and popular',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Color(0xFF9B5DE5)),
                    ),
                  ],
                ),
              ),

            // Results list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  return _buildSearchResultCard(item);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchFuture == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for specific books',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a book title or author to get started',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Book>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FunLoadingWidget(
            messages: FunLoadingWidget.searchMessages,
            color: MediaType.book.color,
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _searchBooks,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No results found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return _buildSearchResultCard(item);
          },
        );
      },
    );
  }

  Widget _buildSearchResultCard(Book item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _logSearchResult(context, item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Book Cover
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: item.id.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://covers.openlibrary.org/b/olid/${item.id}-M.jpg?default=false',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              MediaType.book.icon,
                              size: 40,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : Icon(
                        MediaType.book.icon,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),

              const SizedBox(width: 16),

              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Author
                    Text(
                      item.authors != null && item.authors!.isNotEmpty
                          ? item.authors!.join(', ')
                          : '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Rich Data Display
                    _buildRichDataDisplay(item),

                    const SizedBox(height: 8),

                    // Action Button
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 16,
                                color: Color(0xFF9B5DE5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Log This',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9B5DE5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border,
                  color: Colors.orangeAccent,
                ),
                onPressed: () => _bookmarkBook(item),
                tooltip: 'Save bookmark',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichDataDisplay(Book item) {
    final List<Widget> infoWidgets = [];

    // Subjects
    if (item.subjects != null && item.subjects!.isNotEmpty) {
      final subjects = item.subjects!.take(2).join(', ');
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              subjects,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Publish Date
    if (item.publishDate != null && item.publishDate!.isNotEmpty) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              item.publishDate!,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Book ID
    if (item.id.isNotEmpty) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              item.id,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (infoWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 12, runSpacing: 2, children: infoWidgets);
  }
}
