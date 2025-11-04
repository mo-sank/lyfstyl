// Cami Krugel
// 1.75 hours

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lyfstyl/utils/import_parser.dart';
import 'dart:io';
import '../../models/log_entry.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/media_item.dart';
import '../../models/log_entry.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';


class NewImportScreen extends StatelessWidget {
  const NewImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from Other Services')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Import your media logs from popular platforms',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _ImportCard(
                  title: 'Goodreads',
                  description: 'Upload your reading history from Goodreads.',
                  icon: Icons.book,
                  color: Colors.deepPurple,
                  buttonText: 'Upload Goodreads CSV',
                  uploadEnabled: true,
                  parser: GoodreadsImportParser(),
                ),
                const SizedBox(height: 24),
                _ImportCard(
                  title: 'Letterboxd',
                  description: 'Import your watched films from Letterboxd.',
                  icon: Icons.movie,
                  color: Colors.teal,
                  buttonText: 'Upload Letterboxd CSV',
                  uploadEnabled: true,
                  parser: LetterboxdImportParser(),
                ),
                const SizedBox(height: 24),
                _ImportCard(
                  title: 'Spotify',
                  description: 'Import your music listening history from Spotify.',
                  icon: Icons.music_note,
                  color: Colors.green,
                  buttonText: 'Coming Soon',
                  uploadEnabled: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String buttonText;
  final bool uploadEnabled;
  final ImportParser? parser; // Add this

  _ImportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.buttonText,
    this.uploadEnabled = false,
    this.parser,
    super.key,
  });

  @override
  State<_ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends State<_ImportCard> {
  String? _fileName;
  PlatformFile? _pickedFile;
  final TextEditingController _controller = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.single;
        _fileName = _pickedFile!.name;
        _controller.text = _fileName ?? '';
      });
    }
  }

  Future<void> _parseFile() async {
    if (_pickedFile == null || widget.parser == null) return;
    String contents;
    if (_pickedFile!.bytes != null) {
      contents = String.fromCharCodes(_pickedFile!.bytes!);
    } else if (_pickedFile!.path != null) {
      contents = await File(_pickedFile!.path!).readAsString();
    } else {
      throw Exception('No file data found');
    }
    final parsedBooks = widget.parser!.parse(contents);

    final svc = context.read<FirestoreService>();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();

    int successCount = 0;
    int errorCount = 0;

    for (final book in parsedBooks) {
      try {
        if (book['Exclusive Shelf']=='read'){
        final media = await svc.getOrCreateMedia(
          title: book['Title'] ?? '',
          type: MediaType.book,
          creator: book['Author'] ?? '',
        );
        final dateRead = parseGoodreadsDate(book['Date Read']);
        final log = LogEntry(
          logId: 'temp',
          userId: userId,
          mediaId: media.mediaId,
          mediaType: MediaType.book,
          rating: book['My Rating'],
          review: book['My Review'],
          consumedAt: dateRead,
          createdAt: now,
          updatedAt: now,
          consumptionData: BookConsumptionData(
            pages: book['Number of Pages'],
            isbn: book['ISBN'],
            isbn13: book['ISBN13'],
            publisher: book['Publisher'],
            readCount: book['Read Count']
          ).toMap()
        );
        await svc.createLog(log);
        successCount++;
      }} catch (e) {
        errorCount++;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $successCount logs, $errorCount errors')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: widget.color.withOpacity(0.15),
              child: Icon(widget.icon, color: widget.color, size: 36),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: widget.color)),
                  const SizedBox(height: 8),
                  Text(widget.description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  if (widget.uploadEnabled) ...[
                    const SizedBox(height: 10),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Selected file',
                        hintText: 'No file selected',
                        prefixIcon: Icon(Icons.insert_drive_file, color: widget.color),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.upload_file),
                          onPressed: _pickFile,
                          tooltip: 'Choose file',
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      controller: _controller,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickedFile != null ? _parseFile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pickedFile != null ? widget.color : Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(widget.buttonText, style: const TextStyle(fontSize: 16)),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(widget.buttonText, style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int? parseInt(dynamic value) {
  if (value == null) return null;
  var str = value.toString().trim();
  // Remove Excel artifact
  if (str.startsWith('="') && str.endsWith('"')) {
    str = str.substring(2, str.length - 1);
  }
  // Remove any remaining quotes
  str = str.replaceAll('"', '');
  return int.tryParse(str);
}

DateTime parseGoodreadsDate(String? value) {
  if (value == null || value.trim().isEmpty) return DateTime.now();
  final parts = value.split('/');
  try {
    if (parts.length == 3 && parts[0].length == 4) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
  } catch (_) {}
  return DateTime.now();
}
