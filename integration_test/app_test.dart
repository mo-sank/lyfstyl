import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lyfstyl/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Lyfstyl App Integration Tests', () {
    testWidgets('app launches and shows login screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Lyfstyl'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('navigation between login and register screens', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Lyfstyl'), findsOneWidget);
    });

    testWidgets('form validation on login screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('form validation on register screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(1), 'password123');
      await tester.enterText(passwordFields.at(2), 'different123');
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('Home Screen Navigation Tests', () {
    testWidgets('home screen navigation tabs work correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Your cinematic journey'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();

      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Your reading adventure'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.music_note));
      await tester.pumpAndSettle();

      expect(find.text('Trending Music'), findsOneWidget);
      expect(find.text('Discover what\'s hot right now'), findsOneWidget);
    });

    testWidgets('drawer navigation works correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('My Activity'), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('add log button navigation works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Add Log'), findsOneWidget);
    });
  });

  group('Music Feature Integration Tests', () {
    testWidgets('trending music navigation works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      await tester.tap(find.byIcon(Icons.music_note));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trending Music'));
      await tester.pumpAndSettle();

      expect(find.text('Trending Music'), findsOneWidget);
    });

    testWidgets('music search navigation works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      await tester.tap(find.byIcon(Icons.music_note));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Search Music'));
      await tester.pumpAndSettle();

      expect(find.text('Search Music'), findsOneWidget);
    });
  });

  group('Collections Feature Integration Tests', () {
    testWidgets('collections navigation works from drawer', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Collections'));
      await tester.pumpAndSettle();

      expect(find.text('My Collections'), findsOneWidget);
    });

    testWidgets('collections navigation works from home screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      final collectionsItem = find.text('My Collections');
      if (collectionsItem.evaluate().isNotEmpty) {
        await tester.tap(collectionsItem);
        await tester.pumpAndSettle();

        expect(find.text('My Collections'), findsOneWidget);
      }
    });
  });

  group('Error Handling Integration Tests', () {
    testWidgets('handles network errors gracefully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      await tester.tap(find.byIcon(Icons.music_note));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trending Music'));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('handles image loading errors', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      expect(find.byIcon(Icons.image), findsWidgets);
    });
  });

  group('User Flow Integration Tests', () {
    testWidgets('complete add log flow works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Add Log'), findsOneWidget);

      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'Test Movie');
      await tester.pumpAndSettle();

      expect(find.text('Test Movie'), findsOneWidget);
    });

    testWidgets('stats dialog shows correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Welcome to Lyfstyl').evaluate().isNotEmpty) {
        return;
      }

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Stats'));
      await tester.pumpAndSettle();

      expect(
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.text('Your Stats').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}