import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyfstyl/screens/movies/movie_search_screen.dart';

void main() {
  group('MovieSearchScreen Widget Tests', () {
    testWidgets('renders search bar and filters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MovieSearchScreen(),
        ),
      );

      expect(find.text('Discover Movies'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Genre'), findsOneWidget);
      expect(find.text('Min Year'), findsOneWidget);
      expect(find.text('Min Rating'), findsOneWidget);
    });

    testWidgets('search field accepts input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MovieSearchScreen(),
        ),
      );

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Inception');
      
      expect(find.text('Inception'), findsOneWidget);
    });

    testWidgets('genre filter shows dropdown options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MovieSearchScreen(),
        ),
      );

      final genreDropdown = find.byType(DropdownButton<String>).first;
      await tester.tap(genreDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
    });

    testWidgets('shows loading indicator when searching', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MovieSearchScreen(),
        ),
      );


      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('clear filters button appears when filters are applied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MovieSearchScreen(),
        ),
      );


      final genreDropdown = find.byType(DropdownButton<String>).first;
      await tester.tap(genreDropdown);
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Action').last);
      await tester.pumpAndSettle();

      expect(find.text('Clear'), findsOneWidget);
    });
  });
}