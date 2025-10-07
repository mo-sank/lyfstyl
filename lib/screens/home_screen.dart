import 'package:flutter/material.dart';
import 'package:lyfstyl/screens/trending/trending_books_screen.dart';
import 'package:lyfstyl/screens/trending/search_filter_books_screen.dart';
import 'package:lyfstyl/screens/trending/books_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/stats_service.dart';
import 'auth/login_screen.dart';
import 'profile/profile_screen.dart';
import 'logs/add_log_screen.dart';
import 'collections/my_collections_screen.dart';
import 'trending/trending_music_screen.dart';
import 'music/music_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.movie,
      label: 'Movies',
      color: const Color(0xFF8B5CF6),
    ),
    NavigationItem(
      icon: Icons.book,
      label: 'Books',
      color: const Color(0xFF6B7280),
    ),
    NavigationItem(
      icon: Icons.music_note,
      label: 'Music',
      color: const Color(0xFF6B7280),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 80,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              border: Border(
                right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Menu button
                Builder(
                  builder: (context) => _buildSidebarButton(
                    icon: Icons.menu,
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Add button
                _buildSidebarButton(
                  icon: Icons.add,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddLogScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Back button
                _buildSidebarButton(
                  icon: Icons.arrow_back,
                  onTap: () {
                    // Only pop if there's something to pop
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const Spacer(),
                // Navigation items
                ..._navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildNavigationItem(item, index),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color != null ? Colors.white : Colors.grey[600]),
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? item.color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          item.icon,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildMoviesContent();
      case 1:
        return _buildBooksContent();
      case 2:
        return _buildMusicContent();
      default:
        return _buildMoviesContent();
    }
  }

  Widget _buildMoviesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Movies',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your cinematic journey',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Filter buttons
          Row(
            children: [
              _buildFilterChip('All', true),
              const SizedBox(width: 12),
              _buildFilterChip('Favorites', false),
            ],
          ),
          const SizedBox(height: 24),
          // Content list
          _buildContentList(),
        ],
      ),
    );
  }

  Widget _buildBooksContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Books',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your reading adventure',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildFilterChip('All', true),
              const SizedBox(width: 12),
              _buildFilterChip('Favorites', false),
            ],
          ),
          const SizedBox(height: 24),
          _buildContentList(),
        ],
      ),
    );
  }

  Widget _buildMusicContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrendingMusicScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Trending Music',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Discover what\'s hot right now',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Search Music Card
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MusicSearchScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 100,
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Search Music',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find and log your favorite songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Filter buttons
          Row(
            children: [
              _buildFilterChip('All', true),
              const SizedBox(width: 12),
              _buildFilterChip('Favorites', false),
            ],
          ),
          const SizedBox(height: 24),
          // Quick access cards
          _buildMusicQuickAccess(),
        ],
      ),
    );
  }

  Widget _buildMusicQuickAccess() {
    return Column(
      children: [
        _buildListItem(
          title: 'Trending Music',
          category: 'Music • Latest',
          description: 'Discover what\'s trending in music right now.',
          imageUrl: 'https://via.placeholder.com/60x60/10B981/FFFFFF?text=♪',
          rating: 4,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TrendingMusicScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildListItem(
          title: 'My Music Collection',
          category: 'Collections • Music',
          description: 'View and organize your logged music.',
          imageUrl: 'https://via.placeholder.com/60x60/3B82F6/FFFFFF?text=🎵',
          rating: 4,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyCollectionsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildListItem(
          title: 'Add Music Log',
          category: 'Log • Music',
          description: 'Log a new music item you\'ve listened to.',
          imageUrl: 'https://via.placeholder.com/60x60/8B5CF6/FFFFFF?text=+',
          rating: 4,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddLogScreen(
                  preFilledData: {
                    'type': 'music',
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF374151) : const Color(0xFF8B5CF6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            const Icon(Icons.check, color: Colors.white, size: 16),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    return Column(
      children: [
        _buildListItem(
          title: 'The Conjuring',
          category: 'Horror',
          description: 'Supporting line text lorem ipsum dolor sit amet, consectetur.',
          imageUrl: 'https://via.placeholder.com/60x60/DC2626/FFFFFF?text=TC',
          rating: 5,
        ),
        const SizedBox(height: 12),
        _buildListItem(
          title: 'KPop Demon Hunters',
          category: 'Action',
          description: 'Supporting line text lorem ipsum dolor sit amet, consectetur.',
          imageUrl: 'https://via.placeholder.com/60x60/7C3AED/FFFFFF?text=KDH',
          rating: 5,
        ),
        const SizedBox(height: 12),
        _buildListItem(
          title: 'My Collections',
          category: 'Collections • All Media',
          description: 'View and organize your logged media by type.',
          imageUrl: 'https://via.placeholder.com/60x60/3B82F6/FFFFFF?text=📚',
          rating: 4,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyCollectionsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListItem({
    required String title,
    required String category,
    required String description,
    required String imageUrl,
    required int rating,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
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
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFF59E0B),
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.favorite_border,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            // Header
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your media journey awaits',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history,
                    title: 'My Activity',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyCollectionsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.collections_bookmark,
                    title: 'Collections',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyCollectionsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: 'My Stats',
                    onTap: () {
                      Navigator.pop(context);
                      _showStatsDialog(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.search,
                    title: 'Search Music',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MusicSearchScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    title: 'Trending Music',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TrendingMusicScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    title: 'Discover Books',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BooksScreen()),
                      );
                    },
                  ),
                                   
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Add settings screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings coming soon!')),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Add help screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support coming soon!')),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    onTap: () {
                      Navigator.pop(context);
                      _signOut(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B7280)),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
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

  Future<void> _showStatsDialog(BuildContext context) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final svc = context.read<FirestoreService>();
      final statsService = StatsService();
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Fetch logs and calculate stats
      final logs = await svc.getUserLogs(uid, limit: 1000);
      final stats = statsService.calculateUserStats(logs);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show stats dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your Stats'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Total Items Logged', stats.totalItemsLogged.toString()),
                if (stats.totalMusicMinutes > 0)
                  _buildStatRow('Total Music Time', statsService.formatDuration(stats.totalMusicMinutes)),
                if (stats.averageRating > 0)
                  _buildStatRow('Average Rating', stats.averageRating.toStringAsFixed(1)),
                if (stats.topGenres.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Top Genres:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...stats.topGenres.take(3).map((genre) => 
                    Text('• $genre (${stats.genreCounts[genre]} items)')
                  ),
                ],
                if (stats.topArtists.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Top Artists:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...stats.topArtists.take(3).map((artist) => 
                    Text('• $artist (${stats.artistCounts[artist]} songs)')
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: $e')),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}