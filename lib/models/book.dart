class Book {
  final String id; // OLID
  final String title;
  final List<String>? authors;
  final List<String>? publishers;
  final List<String>? isbn10;
  final List<String>? isbn13;
  final String? publishDate;
  final int? pages;
  final List<String>? subjects;
  final String? weight;

  Book({
    required this.id,
    required this.title,
    this.authors,
    this.publishers,
    this.isbn10,
    this.isbn13,
    this.publishDate,
    this.pages,
    this.subjects,
    this.weight,
  });

  // From search.json
  factory Book.fromSearchJson(Map<String, dynamic> json) {
    String? id = json['cover_edition_key'];
    if (id == null && json['edition_key'] != null && json['edition_key'] is List && json['edition_key'].isNotEmpty) {
      id = json['edition_key'][0];
    }
    return Book(
      id: id ?? '',
      title: json['title'] ?? '',
      authors: (json['author_name'] as List?)?.map((e) => e.toString()).toList() ?? [],
      publishers: (json['publisher'] as List?)?.map((e) => e.toString()).toList(),
      isbn10: (json['isbn_10'] as List?)?.map((e) => e.toString()).toList(),
      isbn13: (json['isbn_13'] as List?)?.map((e) => e.toString()).toList(),
      publishDate: json['first_publish_year']?.toString(),
      pages: null, // Not available in search.json
      subjects: (json['subject'] as List?)?.map((e) => e.toString()).toList(),
      weight: null,
    );
  }

  // From books/{OLID}.json
  factory Book.fromEditionJson(Map<String, dynamic> json) {
    return Book(
      id: json['key'] != null ? (json['key'] as String).replaceAll('/books/', '') : '',
      title: json['title'] ?? '',
      authors: (json['authors'] as List?)?.map((e) => e.toString()).toList(),
      publishers: (json['publishers'] as List?)?.map((e) => e.toString()).toList(),
      isbn10: (json['isbn_10'] as List?)?.map((e) => e.toString()).toList(),
      isbn13: (json['isbn_13'] as List?)?.map((e) => e.toString()).toList(),
      publishDate: json['publish_date'],
      pages: json['number_of_pages'],
      subjects: (json['subjects'] as List?)?.map((e) => e.toString()).toList(),
      weight: json['weight'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'authors': authors,
    'publishers': publishers,
    'isbn10': isbn10,
    'isbn13': isbn13,
    'publishDate': publishDate,
    'pages': pages,
    'subjects': subjects,
    'weight': weight,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    authors: (json['authors'] as List?)?.map((e) => e.toString()).toList(),
    publishers: (json['publishers'] as List?)?.map((e) => e.toString()).toList(),
    isbn10: (json['isbn10'] as List?)?.map((e) => e.toString()).toList(),
    isbn13: (json['isbn13'] as List?)?.map((e) => e.toString()).toList(),
    publishDate: json['publishDate'],
    pages: json['pages'],
    subjects: (json['subjects'] as List?)?.map((e) => e.toString()).toList(),
    weight: json['weight'],
  );
}