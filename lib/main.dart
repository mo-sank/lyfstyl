import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (context) => AuthService()),
        Provider<FirestoreService>(create: (context) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'Lyfstyl',
        theme: buildAppTheme(),
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
      stream: context.watch<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.emailVerified) {
            return const HomeScreen();
          } else {
            // User is logged in but email not verified
            return const EmailVerificationScreen();
          }
        }
        return const LoginScreen();
      },
    );
  }
}

