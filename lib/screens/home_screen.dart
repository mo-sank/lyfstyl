// Contributors:
// Julia: (2 hours) Home page bugs and generic home page

// maya poghosyan
import 'package:flutter/material.dart';
import 'package:lyfstyl/screens/import/new_import_screen.dart';
import 'package:lyfstyl/screens/trending/books_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/stats_service.dart';
import '../models/log_entry.dart';
import '../models/media_item.dart';
import 'auth/login_screen.dart';
import 'profile/profile_screen.dart';
import 'logs/add_log_screen.dart';
import 'collections/my_collections_screen.dart';
import 'bookmarks/bookmarks_screen.dart';
import 'trending/trending_music_screen.dart';
import 'trending/trending_movies_screen.dart';
import 'music/music_search_screen.dart';
import 'movies/movie_search_screen.dart';
import '../theme/media_type_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<List<(LogEntry, MediaItem?)>> _logsFuture;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home,
      label: 'All',
      color: const Color(0xFF8B5CF6),
    ),
    NavigationItem(
      icon: MediaType.film.icon,
      label: 'Movies',
      color: MediaType.film.color,
    ),
    NavigationItem(
      icon: MediaType.book.icon,
      label: 'Books',
      color: MediaType.book.color,
    ),
    NavigationItem(
      icon: MediaType.music.icon,
      label: 'Music',
      color: MediaType.music.color,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    _logsFuture = _fetchLogsWithMedia();
  }

  Future<List<(LogEntry, MediaItem?)>> _fetchLogsWithMedia() async {
    final user = FirebaseAuth.instance.currentUser!;
    final svc = context.read<FirestoreService>();
    final logs = await svc.getUserLogs(user.uid, limit: 50);

    final logsWithMedia = <(LogEntry, MediaItem?)>[];
    for (final log in logs) {
      final media = await svc.getMediaItem(log.mediaId);
      logsWithMedia.add((log, media));
    }

    return logsWithMedia;
  }

  List<(LogEntry, MediaItem?)> _filterByType(
    List<(LogEntry, MediaItem?)> logs,
    List<MediaType> types,
  ) {
    return logs.where((entry) => types.contains(entry.$1.mediaType)).toList();
  }

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
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddLogScreen()),
                    );
                    // Refresh logs after adding
                    setState(() {
                      _loadLogs();
                    });
                  },
                ),
                const SizedBox(height: 20),
                // Refresh button
                _buildSidebarButton(
                  icon: Icons.refresh,
                  onTap: () {
                    setState(() {
                      _loadLogs();
                    });
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
          Expanded(child: _buildMainContent()),
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
        icon: Icon(
          icon,
          color: color != null ? Colors.white : Colors.grey[600],
        ),
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
    return FutureBuilder<List<(LogEntry, MediaItem?)>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allLogs = snapshot.data ?? [];

        switch (_selectedIndex) {
          case 0:
            return _buildAllMediaContent(allLogs);
          case 1:
            final movieLogs = _filterByType(allLogs, [
              MediaType.film,
              MediaType.show,
            ]);
            return _buildMoviesContent(movieLogs);
          case 2:
            final bookLogs = _filterByType(allLogs, [MediaType.book]);
            return _buildBooksContent(bookLogs);
          case 3:
            final musicLogs = _filterByType(allLogs, [
              MediaType.album,
              MediaType.song,
              MediaType.music,
            ]);
            return _buildMusicContent(musicLogs);
          default:
            return _buildAllMediaContent(allLogs);
        }
      },
    );
  }

  Widget _buildAllMediaContent(List<(LogEntry, MediaItem?)> logs) {
    final movieLogs = _filterByType(logs, [MediaType.film, MediaType.show]);
    final bookLogs = _filterByType(logs, [MediaType.book]);
    final musicLogs = _filterByType(logs, [
      MediaType.album,
      MediaType.song,
      MediaType.music,
    ]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Lyfstyl',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track all your media in one place • ${logs.length} items logged',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Stats Overview
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Movies & Shows',
                  movieLogs.length.toString(),
                  MediaType.film.icon,
                  MediaType.film.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Books',
                  bookLogs.length.toString(),
                  MediaType.book.icon,
                  MediaType.book.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Music',
                  musicLogs.length.toString(),
                  MediaType.music.icon,
                  MediaType.music.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Movies & Shows Section
          if (movieLogs.isNotEmpty) ...[
            _buildSectionHeader('Movies & Shows', MediaType.film, () {
              setState(() => _selectedIndex = 1);
            }),
            const SizedBox(height: 16),
            ...movieLogs.take(3).map((entry) {
              final (log, media) = entry;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMediaCard(log, media),
              );
            }),
            if (movieLogs.length > 3) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: Text('View all ${movieLogs.length} movies & shows →'),
              ),
            ],
            const SizedBox(height: 32),
          ],

          // Books Section
          if (bookLogs.isNotEmpty) ...[
            _buildSectionHeader('Books', MediaType.book, () {
              setState(() => _selectedIndex = 2);
            }),
            const SizedBox(height: 16),
            ...bookLogs.take(3).map((entry) {
              final (log, media) = entry;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMediaCard(log, media),
              );
            }),
            if (bookLogs.length > 3) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 2),
                child: Text('View all ${bookLogs.length} books →'),
              ),
            ],
            const SizedBox(height: 32),
          ],

          // Music Section
          if (musicLogs.isNotEmpty) ...[
            _buildSectionHeader('Music', MediaType.music, () {
              setState(() => _selectedIndex = 3);
            }),
            const SizedBox(height: 16),
            ...musicLogs.take(3).map((entry) {
              final (log, media) = entry;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMediaCard(log, media),
              );
            }),
            if (musicLogs.length > 3) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 3),
                child: Text('View all ${musicLogs.length} tracks →'),
              ),
            ],
          ],

          // Empty state if no logs at all
          if (logs.isEmpty) ...[
            const SizedBox(height: 48),
            _buildEmptyState(
              'Start Your Journey',
              'Log your first movie, book, or song to get started!',
              Icons.add_circle_outline,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    MediaType type,
    VoidCallback onViewAll,
  ) {
    return Row(
      children: [
        Icon(type.icon, size: 24, color: const Color(0xFF1F2937)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildMoviesContent(List<(LogEntry, MediaItem?)> logs) {
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
                          'Movies & Shows',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${logs.length} items logged',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(MediaType.film.icon, color: Colors.white, size: 48),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick actions for movies
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Search Movies',
                  Icons.search,
                  const Color(0xFF3B82F6),
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MovieSearchScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Trending',
                  Icons.trending_up,
                  const Color(0xFF8B5CF6),
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TrendingMoviesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (logs.isEmpty)
            _buildEmptyState(
              'No movies or shows logged yet',
              'Start logging your favorite films and TV shows!',
              Icons.movie_outlined,
            )
          else
            ..._buildMediaList(logs),
        ],
      ),
    );
  }

  Widget _buildBooksContent(List<(LogEntry, MediaItem?)> logs) {
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
                        Text(
                          '${logs.length} books logged',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(MediaType.book.icon, color: Colors.white, size: 48),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Discover Books button
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BooksScreen()));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Discover Books',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (logs.isEmpty)
            _buildEmptyState(
              'No books logged yet',
              'Start tracking your reading journey!',
              MediaType.book.icon,
            )
          else
            ..._buildMediaList(logs),
        ],
      ),
    );
  }

  Widget _buildMusicContent(List<(LogEntry, MediaItem?)> logs) {
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
                colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                          'Music',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${logs.length} tracks logged',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Search Music',
                  Icons.search,
                  const Color(0xFF3B82F6),
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MusicSearchScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Trending',
                  Icons.trending_up,
                  const Color(0xFF8B5CF6),
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TrendingMusicScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (logs.isEmpty)
            _buildEmptyState(
              'No music logged yet',
              'Start tracking your favorite songs and albums!',
              MediaType.music.icon,
            )
          else
            ..._buildMediaList(logs),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMediaList(List<(LogEntry, MediaItem?)> logs) {
    return logs.map((entry) {
      final (log, media) = entry;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildMediaCard(log, media),
      );
    }).toList();
  }

  Widget _buildMediaCard(LogEntry log, MediaItem? media) {
    return Container(
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
          // Cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: media?.coverUrl != null
                ? Image.network(
                    media!.coverUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage(log.mediaType);
                    },
                  )
                : _buildPlaceholderImage(log.mediaType),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media?.title ?? 'Unknown ${log.mediaType.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (media?.creator != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    media!.creator!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
                if (log.review != null && log.review!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.review!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Rating
          if (log.rating != null)
            Column(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < log.rating! ? Icons.star : Icons.star_border,
                      color: const Color(0xFFF59E0B),
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(MediaType type) {
    IconData icon = type.icon;
    Color color = type.color;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Column(
          children: [
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
                    Icon(Icons.person, size: 60, color: Colors.white),
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
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
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
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.collections_bookmark,
                    title: 'Collections',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyCollectionsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bookmark,
                    title: 'Bookmarks',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BookmarksScreen(),
                        ),
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
                    icon: Icons.upload_file,
                    title: 'Import Media',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NewImportScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final logs = await svc.getUserLogs(uid, limit: 1000);
      final stats = statsService.calculateUserStats(logs);

      Navigator.of(context).pop();

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
                _buildStatRow('Total Items', stats.totalItemsLogged.toString()),
                if (stats.averageRating > 0)
                  _buildStatRow(
                    'Avg Rating',
                    stats.averageRating.toStringAsFixed(1),
                  ),
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
