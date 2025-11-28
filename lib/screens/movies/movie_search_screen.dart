import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/movie_service.dart';
import '../../services/firestore_service.dart';
import '../../models/media_item.dart';
import '../logs/add_log_screen.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late MovieService _service;
  Future<List<MovieItem>>? _searchFuture;
  Future<List<MovieItem>>? _genreFuture;
  List<MovieItem> _searchResults = [];
  List<MovieItem> _genreResults = [];
  bool _isLoading = false;
  bool _isLoadingGenre = false;

  String _currentMode = 'browse';
  String? _selectedGenre;

  static const List<String> _genres = [
    'Action',
    'Comedy',
    'Drama',
    'Horror',
    'Romance',
    'Thriller',
    'Sci-Fi',
    'Fantasy',
    'Animation',
    'Documentary',
    'Crime',
    'Adventure',
  ];

  @override
  void initState() {
    super.initState();
    _service = MovieService();
    _loadTrendingMovies();
  }

  Future<void> _loadTrendingMovies() async {
    setState(() => _isLoading = true);
    try {
      final movies = await _service.getTrendingMovies();
      setState(() {
        _searchResults = movies;
        _genreResults = movies;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

void _logSearchResult(BuildContext context, MovieItem item) {

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddLogScreen(
          preFilledData: {
            'title': item.title,
            'type': 'movie',
            'creator': item.director,
            'movieData': item.movieData,
          },
        ),
      ),
    );
  }




  Future<void> _searchMovies() async {
    if (_searchCtrl.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentMode = 'search';
      _searchFuture = _performSearch();
    });
  }

  Future<List<MovieItem>> _performSearch() async {
    try {
      final results = await _service.searchMovies(_searchCtrl.text.trim());
      _searchResults = results;
      return results;
    } catch (e) {
      print('Search error: $e');
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _genreResults = _service.filterMovies(
        _searchResults,
        genre: _selectedGenre
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedGenre = null;
      _genreResults = _searchResults;
    });
  }

  Future<void> _bookmarkMovie(MovieItem movie) async {
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
        mediaType: MediaType.movie,
        title: movie.title,
        creator: movie.director,
        coverUrl: movie.posterUrl,
        metadata: {
          'releaseDate': movie.releaseDate?.toIso8601String(),
          'genres': movie.genres,
          'rating': movie.rating,
          'source': 'tmdb',
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
      ).showSnackBar(const SnackBar(content: Text('Failed to bookmark movie')));
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
      _genreResults = [];
      _genreFuture = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Movies'),
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
        backgroundColor: isSelected ? Color(0xFF9B5DE5) : Colors.grey[200],
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
          // Genre Selection
          Container(
            width: double.infinity, // <-- Add this line
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a genre to discover movies',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _genres.map((genre) {
                    return _buildGenreChip(genre);
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

   Widget _buildGenreChip(String genre) {
    return ActionChip(
      label: Text(genre.toUpperCase()),
      onPressed: () => _browseByGenre(genre),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: MediaType.movie.color,
        fontWeight: FontWeight.w500,
      ),
      avatar: Icon(MediaType.movie.icon, size: 16, color: MediaType.movie.color),
    );
  }

  Widget _buildBrowseResults() {
    if (_genreFuture == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Choose a genre to discover movies',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any genre above to see trending and popular movies',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<MovieItem>>(
      future: _genreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            _isLoadingGenre) {
          return const Center(child: CircularProgressIndicator());
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
                  onPressed: () => _browseByGenre('Action'), // Retry with pop
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
                const Icon(Icons.music_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No movies found for this genre',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting a different genre',
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
            // Genre header
            if (_selectedGenre != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Color(0xFF9B5DE5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(MediaType.movie.icon, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedGenre!.toUpperCase()} Movies',
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
                      '${results.length} movies - trending and popular',
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

    Widget _buildSearchResultCard(MovieItem item) {
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
              // Album Art
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: item.posterUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              MediaType.movie.icon,
                              size: 40,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : Icon(
                        MediaType.movie.icon,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),

              const SizedBox(width: 16),

              // Track Info
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

                    // Year
                    Text(
                      item.releaseDate != null ? '${item.releaseDate!.year}' : '',
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
                onPressed: () => _bookmarkMovie(item),
                tooltip: 'Save bookmark',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _browseByGenre(String genre) async {
    setState(() {
      _isLoadingGenre = true;
      _currentMode = 'browse';
      _selectedGenre = genre;
      _genreFuture = _performGenreBrowse(genre);
    });
  }


  Future<List<MovieItem>> _performGenreBrowse(String genre) async {
    try {
      // Use the new dedicated genre method
      final results = await _service.getMoviesByGenre(genre, limit: 30);
      _genreResults = results;
      return results;
    } catch (e) {
      print('Genre browse error: $e');
      return [];
    } finally {
      setState(() => _isLoadingGenre = false);
    }
  }

  Widget _buildSearchContent() {
    return Expanded(
      child: Column(
        children: [
          // Search Section
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
                          hintText: 'Search for films...',
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
                        onSubmitted: (_) => _searchMovies(),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _searchMovies,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9B5DE5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
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
                const SizedBox(height: 8),
                Text(
                  'Search for specific films',
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


  Widget _buildSearchResults() {
    if (_searchFuture == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for specific movies',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a song, artist, or album name to get started',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<MovieItem>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
                  onPressed: _searchMovies,
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
                const Icon(Icons.music_off, size: 64, color: Colors.grey),
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

  Widget _buildRichDataDisplay(MovieItem item) {
    final data = item.movieData;
    final List<Widget> infoWidgets = [];

    // Album
    if (data['album'] != null && data['album'].toString().isNotEmpty) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.album, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              data['album'].toString(),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Duration
    if (data['durationSeconds'] != null) {
      final duration = Duration(seconds: data['durationSeconds'] as int);
      final durationText = duration.inMinutes > 0
          ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
          : '${duration.inSeconds}s';
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              durationText,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Year
    if (data['year'] != null) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              data['year'].toString(),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Genres
    if (data['genres'] != null && (data['genres'] as List).isNotEmpty) {
      final genres = (data['genres'] as List).take(2).join(', ');
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              genres,
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

