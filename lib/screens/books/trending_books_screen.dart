// Trending Books
// Cami Krugel, Maya Poghosyan
// 5 Hours

import 'package:flutter/material.dart';
import '../../models/media_item.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/books_service.dart';
import '../../services/firestore_service.dart';
import '../../models/nyt_book.dart';
import '../logs/add_log_screen.dart';

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
  
  // Cache cover URLs to avoid repeated API calls
  final Map<String, String?> _coverUrlCache = {};

  Widget _noCoverWidget(NYTBook item) => Container(
    width: double.infinity,
    height: 180,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(MediaType.book.icon, color: Colors.grey, size: 48),
          const SizedBox(height: 8),
          Text(
            item.isbn == null || item.isbn!.isEmpty ? 'No ISBN' : 'No Cover',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
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
    try {
      // Load current overview first for immediate display
      final currentOverview = await _service.getOverview();
      
      setState(() {
        _allDates = [currentOverview.publishedDate];
        _selectedDate = currentOverview.publishedDate;
        _futureOverview = Future.value(currentOverview);
        _allLists = currentOverview.lists;
        _selectedListName = currentOverview.lists.isNotEmpty
            ? currentOverview.lists.first.listName
            : null;
        _displayBooks = currentOverview.lists.isNotEmpty
            ? currentOverview.lists.first.books
            : [];
        _filtered = _displayBooks;
      });
      
      // Then fetch additional dates in background (12 weeks total, starting from current)
      _fetchAvailableDates(weeks: 12, startDate: null).then((dates) {
        if (dates.isNotEmpty && mounted) {
          setState(() {
            _allDates = dates;
          });
        }
      });
    } catch (e) {
      final currentOverview = await _service.getOverview();
      setState(() {
        _allDates = [currentOverview.publishedDate];
        _selectedDate = currentOverview.publishedDate;
        _futureOverview = Future.value(currentOverview);
      });
    }
  }

  Future<NYTOverview> _loadOverview({String? date}) async {
    final overview = await _service.getOverview(publishedDate: date);
    setState(() {
      _selectedDate = overview.publishedDate;
      _allLists = overview.lists;
      _selectedListName = overview.lists.isNotEmpty
          ? overview.lists.first.listName
          : null;
      _displayBooks = overview.lists.isNotEmpty
          ? overview.lists.first.books
          : [];
      _filtered = _displayBooks;
      _coverUrlCache.clear(); // Clear cache when loading new data
    });
    return overview;
  }

  Future<List<String>> _fetchAvailableDates({int weeks = 10, String? startDate}) async {
    List<String> dates = [];
    String? date = startDate;
    print('Starting to fetch $weeks weeks of dates...');
    for (int i = 0; i < weeks; i++) {
      try {
        print('Fetching week ${i + 1}, date: $date');
        final overview = await _service.getOverview(publishedDate: date);
        dates.add(overview.publishedDate);
        print('Successfully fetched: ${overview.publishedDate}, previous: ${overview.previousPublishedDate}');
        date = overview.previousPublishedDate;
        if (date == null) {
          print('No more previous dates available. Stopping at ${i + 1} weeks.');
          break;
        }
        
        // Add delay between requests to avoid rate limiting (increased to 1 second)
        if (i < weeks - 1) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      } catch (e) {
        print('Error fetching date $date: $e');
        // If we hit an error but still have a date to try, continue
        if (date != null) {
          continue;
        }
        break;
      }
    }
    print('Finished fetching dates. Total: ${dates.length}');
    return dates;
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
          : _displayBooks
                .where(
                  (item) => ks.any(
                    (k) =>
                        item.title.toLowerCase().contains(k) ||
                        item.author.toLowerCase().contains(k) ||
                        item.description.toLowerCase().contains(k),
                  ),
                )
                .toList();
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

  Future<void> _bookmarkTrendingItem(BuildContext context, NYTBook item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save bookmarks')),
      );
      return;
    }

    final firestore = context.read<FirestoreService>();

    try {
      await firestore.bookmarkMedia(
        userId: user.uid,
        mediaType: MediaType.book,
        title: item.title,
        creator: item.author,
        coverUrl: await _service.getBestCoverUrl(item),
        metadata: {
          'source': 'nyt',
          'rank': item.rank,
          'description': item.description,
        },
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to bookmarks')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to bookmark book')));
    }
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
                  items: _allDates
                      .map(
                        (date) =>
                            DropdownMenuItem(value: date, child: Text(date)),
                      )
                      .toList(),
                  onChanged: (date) {
                    if (date != null) {
                      setState(() {
                        _futureOverview = _loadOverview(date: date);
                      });
                    }
                  },
                  hint: const Text('Select Date'),
                ),
                // List Dropdown
                DropdownButton<String>(
                  value: _selectedListName,
                  items: lists
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.listName,
                          child: Text(l.displayName),
                        ),
                      )
                      .toList(),
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
                      ? const Center(
                          child: Text('No results. Try different keywords.'),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final item = _filtered[index];
                            if (item.isbn == null || item.isbn!.isEmpty) {
                              print(
                                'No ISBN for book: ${item.title} by ${item.author}',
                              );
                            }
                            return _buildBookCard(context, item);
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

  Widget _buildBookCard(BuildContext context, NYTBook item) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showBookDetails(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  FutureBuilder<String?>(
                    future: _getCoverUrlCached(item),
                    builder: (context, snapshot) {
                      final url = snapshot.data;
                      if (url != null) {
                        return Image.network(
                          url,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Cover failed for ${item.title}: $error');
                            return _noCoverWidget(item);
                          },
                        );
                      } else {
                        return _noCoverWidget(item);
                      }
                    },
                  ),
                  // Rank badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${item.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Book Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark_border,
                            size: 20,
                          ),
                          color: Colors.orangeAccent,
                          onPressed: () => _bookmarkTrendingItem(context, item),
                          tooltip: 'Save bookmark',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 20,
                          ),
                          color: Colors.blue,
                          onPressed: () => _logTrendingItem(context, item),
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
  
  // Add caching method to avoid repeated cover URL fetches
  Future<String?> _getCoverUrlCached(NYTBook item) async {
    final cacheKey = '${item.title}_${item.author}';
    if (_coverUrlCache.containsKey(cacheKey)) {
      return _coverUrlCache[cacheKey];
    }
    final url = await _service.getBestCoverUrl(item);
    _coverUrlCache[cacheKey] = url;
    return url;
  }

  Future<void> _showBookDetails(BuildContext context, NYTBook item) async {
    final books = await _service.fetchBooks(
      item.title,
      item.author,
      '',
    );
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
                            child: Icon(
                              MediaType.book.icon,
                              color: Colors.grey,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
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
                if ((bookToShow.subjects == null ||
                        bookToShow.subjects!.isEmpty) &&
                    item.description.isNotEmpty)
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
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddLogScreen(
                      preFilledData: {
                        'title': bookToShow.title.isNotEmpty
                            ? bookToShow.title
                            : item.title,
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(item.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.author.isNotEmpty) Text('Authors: ${item.author}'),
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
  }
}