// Contributors: 
// Julia: (3 hours) Getting user profile from Firestore and sharing



import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/user_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/home_screen.dart';
import 'screens/friends/search_friends_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'screens/profile/public_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use URL-based routing instead of hash-based routing
  usePathUrlStrategy();
  
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
        Provider<UserService>(create: (context) => UserService()),
      ],
      child: Builder(
        builder: (context) {
          // Create router inside the Builder to ensure it has access to providers
          final router = GoRouter(
            initialLocation: '/',
            debugLogDiagnostics: true, // Enable debug logging
            routes: [
              // Public profile route - MUST come first to match before '/'
              GoRoute(
                path: '/profile/:username',
                builder: (context, state) {
                  final username = state.pathParameters['username']!;
                  print('DEBUG ROUTER: Building PublicProfileScreen for username: $username');
                  return PublicProfileScreen(username: username);
                },
              ),
              
              // Home / auth wrapper route
              GoRoute(
                path: '/',
                builder: (context, state) {
                  print('DEBUG ROUTER: Building AuthWrapper');
                  return const AuthWrapper();
                },
              ),
              GoRoute(
                path: '/friends',
                builder: (context, state) => const FriendsScreen(),
              ),
              GoRoute(
                path: '/search_users',
                builder: (context, state) => const SearchUsersScreen(),
              ),
            ],
          );

          return MaterialApp.router(
            title: 'Lyfstyl',
            theme: buildAppTheme(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('DEBUG WRAPPER: AuthWrapper building...');
    
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        
        print('DEBUG WRAPPER: Consumer rebuild triggered');
        print('DEBUG WRAPPER: Current user: ${user?.email ?? "null"}');
        print('DEBUG WRAPPER: Email verified: ${user?.emailVerified ?? "N/A"}');
        print('DEBUG WRAPPER: AuthService loading: ${authService.isLoading}');
        
        // Show loading screen while authentication is in progress
        if (authService.isLoading) {
          print('DEBUG WRAPPER: Showing loading screen (auth in progress)');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (user != null) {
          print('DEBUG WRAPPER: User found - ${user.email}, verified: ${user.emailVerified}');
          if (user.emailVerified) {
            print('DEBUG WRAPPER: Navigating to HomeScreen');
            return const HomeScreen();
          } else {
            print('DEBUG WRAPPER: Navigating to EmailVerificationScreen');
            return const EmailVerificationScreen();
          }
        }
        
        print('DEBUG WRAPPER: No user found, navigating to LoginScreen');
        return const LoginScreen();
      },
    );
  }
}