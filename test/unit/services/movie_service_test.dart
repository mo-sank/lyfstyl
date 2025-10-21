import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/services/movie_service.dart';

void main() {
  group('MovieService Tests', () {
    late MovieService service;

    setUp(() {
      service = MovieService();
    });

    test('filterMovies filters by genre correctly', () {
      final movies = [
        MovieItem(id: '1', title: 'Action Movie', genres: ['Action']),
        MovieItem(id: '2', title: 'Comedy Movie', genres: ['Comedy']),
        MovieItem(id: '3', title: 'Action Comedy', genres: ['Action', 'Comedy']),
      ];

      final filtered = service.filterMovies(movies, genre: 'Action');
      
      expect(filtered.length, 2);
      expect(filtered[0].title, 'Action Movie');
      expect(filtered[1].title, 'Action Comedy');
    });

    test('filterMovies filters by year correctly', () {
      final movies = [
        MovieItem(id: '1', title: 'Old Movie', releaseDate: DateTime(2000)),
        MovieItem(id: '2', title: 'New Movie', releaseDate: DateTime(2020)),
        MovieItem(id: '3', title: 'Recent Movie', releaseDate: DateTime(2023)),
      ];

      final filtered = service.filterMovies(movies, minYear: 2020);
      
      expect(filtered.length, 2);
      expect(filtered[0].title, 'New Movie');
      expect(filtered[1].title, 'Recent Movie');
    });

    test('filterMovies filters by rating correctly', () {
      final movies = [
        MovieItem(id: '1', title: 'Low Rated', rating: 5.0),
        MovieItem(id: '2', title: 'High Rated', rating: 8.5),
        MovieItem(id: '3', title: 'Top Rated', rating: 9.2),
      ];

      final filtered = service.filterMovies(movies, minRating: 8.0);
      
      expect(filtered.length, 2);
      expect(filtered[0].title, 'High Rated');
      expect(filtered[1].title, 'Top Rated');
    });

    test('filterMovies applies multiple filters', () {
      final movies = [
        MovieItem(id: '1', title: 'Action 2020', genres: ['Action'], releaseDate: DateTime(2020), rating: 7.0),
        MovieItem(id: '2', title: 'Action 2023', genres: ['Action'], releaseDate: DateTime(2023), rating: 8.5),
        MovieItem(id: '3', title: 'Comedy 2023', genres: ['Comedy'], releaseDate: DateTime(2023), rating: 8.5),
      ];

      final filtered = service.filterMovies(
        movies, 
        genre: 'Action', 
        minYear: 2023, 
        minRating: 8.0
      );
      
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Action 2023');
    });
  });
}