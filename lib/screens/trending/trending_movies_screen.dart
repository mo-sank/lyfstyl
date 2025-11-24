// maya poghosyan
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/movie_service.dart';
import '../../services/firestore_service.dart';
import '../../models/media_item.dart';
import '../logs/add_log_screen.dart';
import '../../theme/media_type_theme.dart';

class TrendingMoviesScreen extends StatefulWidget {
  const TrendingMoviesScreen({super.key});

  @override
  State<TrendingMoviesScreen> createState() => _TrendingMoviesScreenState();
}

class _TrendingMoviesScreenState extends State<TrendingMoviesScreen> {
  final TextEditingController _keywordsCtrl = TextEditingController();
  final MovieService _service = MovieService();
  List<MovieItem> _displayMovies = [];
  List<MovieItem> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendingMovies();
    _keywordsCtrl.addListener(_applyFilter);
  }

  Future<void> _loadTrendingMovies() async {
    setState(() => _isLoading = true);
    try {
      final movies = await _service.getTrendingMovies(limit: 50);
      setState(() {
        _displayMovies = movies;
        _filtered = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading movies: $e')));
      }
    }
  }

  void _applyFilter() {
    final keywords = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() {
      _filtered = keywords.isEmpty
          ? _displayMovies
          : _displayMovies
                .where(
                  (movie) => keywords.any(
                    (k) =>
                        movie.title.toLowerCase().contains(k) ||
                        (movie.overview?.toLowerCase().contains(k) ?? false) ||
                        movie.genres.any((g) => g.toLowerCase().contains(k)),
                  ),
                )
                .toList();
    });
  }

  void _logTrendingItem(BuildContext context, MovieItem movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddLogScreen(
          preFilledData: {
            'title': movie.title,
            'type': 'film',
            'creator': movie.director ?? '',
          },
        ),
      ),
    );
  }

  Future<void> _bookmarkTrendingItem(
    BuildContext context,
    MovieItem movie,
  ) async {
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

  Widget _buildPlaceholderPoster() {
    return Container(
      width: 56,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child:  Icon(MediaType.movie.icon, color: Colors.grey, size: 30),
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
      appBar: AppBar(title: const Text('Trending Movies')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _keywordsCtrl,
              decoration: const InputDecoration(
                labelText: 'Filter by keywords (comma separated)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? const Center(
                      child: Text('No results. Try different keywords.'),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final movie = _filtered[index];
                        return ListTile(
                          leading: movie.posterUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    movie.posterUrl!,
                                    width: 56,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderPoster();
                                    },
                                  ),
                                )
                              : _buildPlaceholderPoster(),
                          title: Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: movie.genres.isNotEmpty
                              ? Text(
                                  movie.genres.join(', '),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (movie.rating != null)
                                Chip(
                                  label: Text(movie.rating!.toStringAsFixed(1)),
                                  backgroundColor: Colors.amber[50],
                                  labelStyle: const TextStyle(fontSize: 10),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.bookmark_border,
                                  color: Colors.orangeAccent,
                                ),
                                onPressed: () =>
                                    _bookmarkTrendingItem(context, movie),
                                tooltip: 'Save bookmark',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _logTrendingItem(context, movie),
                                tooltip: 'Log this movie',
                              ),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(movie.title),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (movie.posterUrl != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12.0,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              movie.posterUrl!,
                                              width: 120,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      width: 120,
                                                      height: 180,
                                                      color: Colors.grey[300],
                                                      child: Icon(
                                                        MediaType.movie.icon,
                                                        color: Colors.grey,
                                                        size: 48,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        ),
                                      if (movie.releaseDate != null)
                                        Text(
                                          'Release Date: ${movie.releaseDate!.year}',
                                        ),
                                      if (movie.genres.isNotEmpty)
                                        Text(
                                          'Genres: ${movie.genres.join(', ')}',
                                        ),
                                      if (movie.rating != null)
                                        Text(
                                          'Rating: ${movie.rating!.toStringAsFixed(1)}/10',
                                        ),
                                      if (movie.overview != null &&
                                          movie.overview!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            'Overview: ${movie.overview}',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _logTrendingItem(context, movie);
                                    },
                                    child: const Text('Add Log'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
