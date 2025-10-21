import 'package:http/http.dart' as http;
import 'dart:convert';

class MovieItem {
  final String id;
  final String title;
  final String? director;
  final String? overview;
  final String? posterUrl;
  final DateTime? releaseDate;
  final List<String> genres;
  final double? rating;
  final Map<String, dynamic> movieData;

  MovieItem({
    required this.id,
    required this.title,
    this.director,
    this.overview,
    this.posterUrl,
    this.releaseDate,
    this.genres = const [],
    this.rating,
    this.movieData = const {},
  });
}

class MovieService {
  static const String _apiKey = '3fd2be6f0c70a2a598f084ddfb75487c';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  Future<List<MovieItem>> searchMovies(String query, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&page=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.take(limit).map((movie) => _parseMovie(movie)).toList();
      }
    } catch (e) {
      print('Error searching movies: $e');
    }
    return [];
  }

  Future<List<MovieItem>> getMoviesByGenre(String genre, {int limit = 20}) async {
    try {
      final genreId = _getGenreId(genre);
      if (genreId == null) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/discover/movie?api_key=$_apiKey&with_genres=$genreId&sort_by=popularity.desc&page=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.take(limit).map((movie) => _parseMovie(movie)).toList();
      }
    } catch (e) {
      print('Error fetching movies by genre: $e');
    }
    return [];
  }

  Future<List<MovieItem>> getTrendingMovies({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending/movie/week?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.take(limit).map((movie) => _parseMovie(movie)).toList();
      }
    } catch (e) {
      print('Error fetching trending movies: $e');
    }
    return [];
  }

  List<MovieItem> filterMovies(List<MovieItem> movies, {
    String? genre,
    int? minYear,
    int? maxYear,
    double? minRating,
  }) {
    return movies.where((movie) {
      if (genre != null && !movie.genres.any((g) => g.toLowerCase().contains(genre.toLowerCase()))) {
        return false;
      }
      if (minYear != null && (movie.releaseDate?.year ?? 0) < minYear) {
        return false;
      }
      if (maxYear != null && (movie.releaseDate?.year ?? 9999) > maxYear) {
        return false;
      }
      if (minRating != null && (movie.rating ?? 0) < minRating) {
        return false;
      }
      return true;
    }).toList();
  }

  MovieItem _parseMovie(Map<String, dynamic> movie) {
    return MovieItem(
      id: movie['id'].toString(),
      title: movie['title'] ?? '',
      director: null,
      overview: movie['overview'],
      posterUrl: movie['poster_path'] != null ? '$_imageBaseUrl${movie['poster_path']}' : null,
      releaseDate: movie['release_date'] != null ? DateTime.tryParse(movie['release_date']) : null,
      genres: _parseGenres(movie['genre_ids'] as List?),
      rating: movie['vote_average']?.toDouble(),
      movieData: {
        'overview': movie['overview'],
        'popularity': movie['popularity'],
        'voteCount': movie['vote_count'],
        'adult': movie['adult'] ?? false,
      },
    );
  }

  List<String> _parseGenres(List<dynamic>? genreIds) {
    if (genreIds == null) return [];
    
    final genreMap = {
      28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy',
      80: 'Crime', 99: 'Documentary', 18: 'Drama', 10751: 'Family',
      14: 'Fantasy', 36: 'History', 27: 'Horror', 10402: 'Music',
      9648: 'Mystery', 10749: 'Romance', 878: 'Science Fiction',
      10770: 'TV Movie', 53: 'Thriller', 10752: 'War', 37: 'Western'
    };
    
    return genreIds.map((id) => genreMap[id] ?? 'Unknown').toList();
  }

  int? _getGenreId(String genre) {
    final genreMap = {
      'action': 28, 'adventure': 12, 'animation': 16, 'comedy': 35,
      'crime': 80, 'documentary': 99, 'drama': 18, 'family': 10751,
      'fantasy': 14, 'history': 36, 'horror': 27, 'music': 10402,
      'mystery': 9648, 'romance': 10749, 'sci-fi': 878, 'science fiction': 878,
      'thriller': 53, 'war': 10752, 'western': 37
    };
    
    return genreMap[genre.toLowerCase()];
  }
}