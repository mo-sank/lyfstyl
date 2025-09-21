import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyfstyl'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.movie,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Lyfstyl!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your media logging journey starts here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Consumer<AuthService>(
              builder: (context, authService, child) {
                final user = authService.currentUser;
                if (user != null) {
                  return Column(
                    children: [
                      Text(
                        'Logged in as: ${user.email}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: user.emailVerified ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          user.emailVerified ? 'Email Verified ✓' : 'Email Not Verified',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'Features coming soon:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Column(
              children: [
                FeatureCard(
                  icon: Icons.rate_review,
                  title: 'Media Logging',
                  description: 'Track what you watch, read, and listen to',
                ),
                SizedBox(height: 12),
                FeatureCard(
                  icon: Icons.trending_up,
                  title: 'Trending Feed',
                  description: 'Discover what\'s popular in your community',
                ),
                SizedBox(height: 12),
                FeatureCard(
                  icon: Icons.person,
                  title: 'Profile & Collections',
                  description: 'Share your stats and curated collections',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthService>().signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
