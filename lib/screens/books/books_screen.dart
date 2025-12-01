// Cami Krugel

import 'package:flutter/material.dart';
import 'trending_books_screen.dart';
import 'book_search_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trending Books'),
            Tab(text: 'Search Books'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TrendingBooksScreen(),
          SearchBooksScreen(),
        ],
      ),
    );
  }
}