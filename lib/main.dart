import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LyfstylApp());
}

class LyfstylApp extends StatelessWidget {
  const LyfstylApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Lyfstyl',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        // Show loading spinner while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in and email is verified, show home screen
        if (snapshot.hasData && context.read<AuthService>().isEmailVerified) {
          return const HomeScreen();
        }

        // Otherwise, show login screen
        return const LoginScreen();
      },
    );
  }
}

