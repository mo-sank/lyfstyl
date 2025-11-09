// Cami Krugel 
// 0.5 hours

import 'package:csv/csv.dart';

abstract class ImportParser {
  List<Map<String, dynamic>> parse(String fileContent);
}

class GoodreadsImportParser extends ImportParser {
  @override
  List<Map<String, dynamic>> parse(String fileContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(fileContent);

    if (rows.isEmpty) return [];

    // Get header row
    final headers = rows.first.map((e) => e.toString()).toList();

    // Parse each book row into a map
    final books = <Map<String, dynamic>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final book = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        book[headers[j]] = row[j];
      }
      books.add(book);
    }
    return books;
  }
}

class LetterboxdImportParser extends ImportParser {
  @override
  List<Map<String, dynamic>> parse(String fileContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(fileContent);

    if (rows.isEmpty) return [];

    // Get header row
    final headers = rows.first.map((e) => e.toString()).toList();

    // Parse each book row into a map
    final movies = <Map<String, dynamic>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final movie = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        movie[headers[j]] = row[j];
      }
      movies.add(movie);
    }
    return movies;
  }
  
}