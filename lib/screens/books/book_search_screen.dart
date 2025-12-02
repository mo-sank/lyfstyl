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

  int _searchRequestId = 0;
  int _subjectRequestId = 0;

  String _currentMode = 'browse';
  String? _selectedSubject;
  String _searchType = 'title';

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

    final requestId = ++_searchRequestId;
    final query = _searchCtrl.text.trim();

    setState(() {
      _currentMode = 'search';
      _searchFuture = _performSearch(query, requestId);
    });
  }

  Future<List<Book>> _performSearch(String query, int requestId) async {
    try {
      final results = _searchType == 'title'
          ? await _service.fetchBooks(query, '', '')
          : await _service.fetchBooks('', query, '');

      if (requestId != _searchRequestId) return [];
      return results;
    } catch (e) {
      print('Search error: $e');
      rethrow;
    }
  }

  Future<void> _browseBySubject(String subject) async {
    final requestId = ++_subjectRequestId;
    setState(() {
      _currentMode = 'browse';
      _selectedSubject = subject;
      _subjectFuture = _performSubjectBrowse(subject, requestId);
    });
  }

  Future<List<Book>> _performSubjectBrowse(String subject, int requestId) async {
    try {
      final results = await _service.fetchBooks('', '', subject);
      if (requestId != _subjectRequestId) return [];
      return results;
    } catch (e) {
      print('Subject browse error: $e');
      rethrow;
    }
  }

  void _switchToBrowse() {
    setState(() {
      _currentMode = 'browse';
      _searchCtrl.clear();
      _searchFuture = null;
    });
  }

  void _switchToSearch() {
    setState(() {
      _currentMode = 'search';
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
            'creator': (item.authors?.isNotEmpty == true ? item.authors!.join(', ') : ''),
            'bookData': {
              'subjects': item.subjects,
              'publishDate': item.publishDate,
              'id': item.id,
            },
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to bookmarks')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to bookmark book')),
      );
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
          // Mode toggle
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildModeButton('browse', 'Browse by Genre', Icons.category),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeButton('search', 'Search Specific', Icons.search),
                ),
              ],
            ),
          ),
          // Mode-specific content
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
        if (mode == 'browse') _switchToBrowse();
        else _switchToSearch();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? MediaType.book.color : Colors.grey[200],
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a genre to discover books',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _popularSubjects.map(_buildSubjectChip).toList(),
                ),
              ],
            ),
          ),
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
                                    setState(() => _searchFuture = null);
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
                      onPressed: _searchBooks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MediaType.book.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'title',
                      groupValue: _searchType,
                      onChanged: (val) => setState(() => _searchType = val!),
                    ),
                    const Text('Title'),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'author',
                      groupValue: _searchType,
                      onChanged: (val) => setState(() => _searchType = val!),
                    ),
                    const Text('Author'),
                  ],
                ),
              ],
            ),
          ),
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
      labelStyle: TextStyle(color: MediaType.book.color, fontWeight: FontWeight.w500),
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
            Text('Choose a subject to discover books', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Tap any subject above to see trending and popular books', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return FutureBuilder<List<Book>>(
      future: _subjectFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FunLoadingWidget(messages: FunLoadingWidget.bookMessages, color: MediaType.book.color);
        }
        if (snapshot.hasError) return _buildErrorState(() => _browseBySubject(_selectedSubject ?? 'Fiction'), snapshot.error.toString());

        final results = snapshot.data ?? [];
        if (results.isEmpty) return _buildEmptyState('No books found for this subject', 'Try selecting a different subject');

        return _buildGrid(results, _selectedSubject?.toUpperCase());
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
            Text('Search for specific books', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Enter a book title or author to get started', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return FutureBuilder<List<Book>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FunLoadingWidget(messages: FunLoadingWidget.searchMessages, color: MediaType.book.color);
        }
        if (snapshot.hasError) return _buildErrorState(_searchBooks, snapshot.error.toString());

        final results = snapshot.data ?? [];
        if (results.isEmpty) return _buildEmptyState('No results found', 'Try searching with different keywords');

        return _buildGrid(results, null);
      },
    );
  }

  Widget _buildErrorState(VoidCallback retry, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: retry, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Book> results, String? heading) {
    return Column(
      children: [
        if (heading != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: MediaType.book.color,
            child: Row(
              children: [
                Icon(MediaType.book.icon, color: Colors.black),
                const SizedBox(width: 8),
                Text(heading + ' Books', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) => _buildBookGridCard(results[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildBookGridCard(Book item) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _logSearchResult(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: item.id.isNotEmpty
                  ? Image.network(
                      'https://covers.openlibrary.org/b/olid/${item.id}-M.jpg?default=false',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey[300],
                        child: Center(child: Icon(MediaType.book.icon, size: 40, color: Colors.grey)),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[300],
                      child: Center(child: Icon(MediaType.book.icon, size: 40, color: Colors.grey)),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(item.authors?.join(', ') ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bookmark_border, size: 20),
                          color: Colors.orangeAccent,
                          onPressed: () => _bookmarkBook(item),
                          tooltip: 'Save bookmark',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          color: MediaType.book.color,
                          onPressed: () => _logSearchResult(context, item),
                          tooltip: 'Log this book',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
