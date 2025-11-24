import 'package:flutter/material.dart';
import 'package:lyfstyl/theme/media_type_theme.dart';
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
  List<MovieItem> _movies = [];
  List<MovieItem> _filteredMovies = [];
  bool _isLoading = false;

  String? _selectedGenre;
  int? _minYear;
  double? _minRating;

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
        _movies = movies;
        _filteredMovies = movies;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchMovies() async {
    if (_searchCtrl.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final movies = await _service.searchMovies(_searchCtrl.text.trim());
      setState(() {
        _movies = movies;
        _applyFilters();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMovies = _service.filterMovies(
        _movies,
        genre: _selectedGenre,
        minYear: _minYear,
        minRating: _minRating,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedGenre = null;
      _minYear = null;
      _minRating = null;
      _filteredMovies = _movies;
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
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search movies...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onSubmitted: (_) => _searchMovies(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchMovies,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownButton<String>(
                    hint: const Text('Genre'),
                    value: _selectedGenre,
                    items: _genres
                        .map(
                          (genre) => DropdownMenuItem(
                            value: genre,
                            child: Text(genre),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedGenre = value);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 16),

                  DropdownButton<int>(
                    hint: const Text('Min Year'),
                    value: _minYear,
                    items: List.generate(30, (i) => 2024 - i)
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _minYear = value);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 16),

                  DropdownButton<double>(
                    hint: const Text('Min Rating'),
                    value: _minRating,
                    items: [5.0, 6.0, 7.0, 8.0, 9.0]
                        .map(
                          (rating) => DropdownMenuItem(
                            value: rating,
                            child: Text('${rating.toInt()}+'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _minRating = value);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 16),

                  if (_selectedGenre != null ||
                      _minYear != null ||
                      _minRating != null)
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMovies.isEmpty
                ? const Center(child: Text('No movies found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = _filteredMovies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: movie.posterUrl != null
                              ? Image.network(
                                  movie.posterUrl!,
                                  width: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                       Icon(MediaType.movie.icon),
                                )
                              :  Icon(MediaType.movie.icon),
                          title: Text(movie.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (movie.releaseDate != null)
                                Text('${movie.releaseDate!.year}'),
                              if (movie.genres.isNotEmpty)
                                Text(movie.genres.take(2).join(', ')),
                              if (movie.rating != null)
                                Text('★ ${movie.rating!.toStringAsFixed(1)}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.bookmark_border,
                                  color: Colors.orangeAccent,
                                ),
                                tooltip: 'Save bookmark',
                                onPressed: () => _bookmarkMovie(movie),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                tooltip: 'Log this movie',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => AddLogScreen(
                                        preFilledData: {
                                          'title': movie.title,
                                          'type': 'film',
                                          'creator': movie.director,
                                          'filmData': movie.movieData,
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddLogScreen(
                                preFilledData: {
                                  'title': movie.title,
                                  'type': 'film',
                                  'creator': movie.director,
                                  'filmData': movie.movieData,
                                },
                              ),
                            ),
                          ),
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
