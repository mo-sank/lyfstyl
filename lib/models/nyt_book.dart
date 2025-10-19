/*
  NYTBook: Represents a book ranked in NYT
*/
class NYTBook {
  final String title;
  final String author;
  final String description;
  final int rank;
  final String? isbn;

  NYTBook({
    required this.title,
    required this.author,
    required this.description,
    required this.rank,
    this.isbn,
  });

  factory NYTBook.fromJson(Map<String, dynamic> json) => NYTBook(
    title: json['title'],
    author: json['author'],
    description: json['description'],
    rank: json['rank'],
    isbn: json['primary_isbn13'] ?? json['primary_isbn10'], // Prefer isbn 13
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'description': description,
    'rank': rank,
    'isbn': isbn
  };
}

/*
  Represents one of the NYT beststeller lists
*/
class NYTListInfo {
  final String listName;
  final String displayName;
  final List<NYTBook> books;

  NYTListInfo({
    required this.listName,
    required this.displayName,
    required this.books,
  });
}

/*
  Represents one of published dates
*/class NYTOverview {
  final String publishedDate;
  final String? previousPublishedDate;
  final List<NYTListInfo> lists;

  NYTOverview({
    required this.publishedDate,
    required this.previousPublishedDate,
    required this.lists,
  });

  factory NYTOverview.fromJson(Map<String, dynamic> data) {
    final lists = (data['results']['lists'] as List).map((list) {
      
      final books = (list['books'] as List).map((book) => NYTBook(
        title: book['title'],
        author: book['author'],
        description: book['description'],
        rank: book['rank'],
        isbn: book['primary_isbn13'] ?? book['primary_isbn10'], 
      )).toList();
      
      return NYTListInfo(
        listName: list['list_name_encoded'],
        displayName: list['display_name'],
        books: List<NYTBook>.from(books),
      );
    }).toList();
    
    return NYTOverview(
      publishedDate: data['results']['published_date'],
      previousPublishedDate: data['results']['previous_published_date'],
      lists: List<NYTListInfo>.from(lists),
    );
  }
}