// Trending Books
// Cami Krugel
// 6 Hours

import 'package:flutter/material.dart';
import '../../services/books_service.dart';
import '../logs/add_log_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchBooksScreen extends StatefulWidget {
  const SearchBooksScreen({super.key});

  @override
  State<SearchBooksScreen> createState() => _SearchBooksScreenState();
}


class _SearchBooksScreenState extends State<SearchBooksScreen> {
  final TextEditingController _keywordsCtrl = TextEditingController();
  final TextEditingController _subjectCtrl = TextEditingController();
  String _searchTitle = '';
  String _searchAuthor = '';
  String _searchSubject = '';
  Future<List<Book>>? _searchFuture;
  final BooksService _service = BooksService();


  @override
  void initState() {
    super.initState();
  }




  @override
  void dispose() {
    _keywordsCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }




    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Books')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Title'),
                    onChanged: (val) => _searchTitle = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Author'),
                    onChanged: (val) => _searchAuthor = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    onChanged: (val) => _searchSubject = val,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchFuture = _service.fetchBooks(_searchTitle, _searchAuthor, _searchSubject);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _searchFuture == null
                  ? const Center(child: Text('Enter a title or author to search.'))
                  : FutureBuilder<List<Book>>(
                      future: _searchFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No results.'));
                        }
                        final Books = snapshot.data!;
                        return ListView.separated(
                          itemCount: Books.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = Books[index];
                            return ListTile(
                              leading: item.id.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        'https://covers.openlibrary.org/b/olid/${item.id}-M.jpg?default=false',
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 56,
                                            height: 56,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.book, color: Colors.grey),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.book, color: Colors.grey),
                                    ),
                              title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(item.authors[0], maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(item.id.toString()),
                                    backgroundColor: Colors.blue[50],
                                    labelStyle: const TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    tooltip: 'Add Log',
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => AddLogScreen(
                                            preFilledData: {
                                              'title': item.title,
                                              'type': 'book',
                                              'creator': (item.authors.isNotEmpty ? item.authors.join(', ') : ''),
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final url = 'https://openlibrary.org/books/${item.id}.json';
                                final response = await http.get(Uri.parse(url));
                                if (response.statusCode == 200 && context.mounted) {
                                  final data = json.decode(response.body);

                                  // Fetch author names if possible
                                  List<String> authorNames = [];
                                  if (data['authors'] != null) {
                                    authorNames = await _service.fetchAuthorNames(data['authors']);
                                  }
                                  // Fallback to search result author
                                  if (authorNames.isEmpty && item.authors.isNotEmpty) {
                                    authorNames = [item.authors[0]];
                                  }

                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(data['title'] ?? 'No Title'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Show cover image
                                            if (item.id.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 12.0),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    'https://covers.openlibrary.org/b/olid/${item.id}-L.jpg?default=false',
                                                    width: 120,
                                                    height: 180,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 120,
                                                        height: 180,
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.book, color: Colors.grey, size: 48),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            if (authorNames.isNotEmpty)
                                              Text('Authors: ${authorNames.join(", ")}'),
                                            if (data['publishers'] != null)
                                              Text('Publishers: ${data['publishers'].join(", ")}'),
                                            if (data['publish_date'] != null)
                                              Text('Published: ${data['publish_date']}'),
                                            if (data['number_of_pages'] != null)
                                              Text('Pages: ${data['number_of_pages']}'),
                                            if (data['subjects'] != null)
                                              Text('Subjects: ${data['subjects'].join(", ")}'),
                                            if (data['weight'] != null)
                                              Text('Weight: ${data['weight']}'),
                                            if (data['isbn_13'] != null)
                                              Text('ISBN-13: ${data['isbn_13'].join(", ")}'),
                                            if (data['isbn_10'] != null)
                                              Text('ISBN-10: ${data['isbn_10'].join(", ")}'),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Close'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => AddLogScreen(
                                                  preFilledData: {
                                                    'title': item.title,
                                                    'type': 'book',
                                                    'creator': (item.authors.isNotEmpty ? item.authors.join(', ') : ''),
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Add Log'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

}
