// Cami Krugel
// 1.75 hours

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lyfstyl/utils/import_parser.dart';
import 'package:lyfstyl/utils/import_handlers.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/media_item.dart';

class NewImportScreen extends StatelessWidget {
  const NewImportScreen({super.key});

  void _showInfoDialog(BuildContext context, String service) {
    String infoText;
    if (service == 'Goodreads') {
      infoText = '''
To export your reading history from Goodreads:
1. Go to Goodreads.com and log in (Desktop only).
2. Click on your profile icon and navigate to "My Books".
3. On the left sidebar, under "Tools", click "Import and export".
4. Under "Export", click "Export Library".
5. Download the CSV file and upload it here.
''';
    } else if (service == 'Letterboxd') {
      infoText = '''
To get your watching history from Letterboxd:
1. Go to letterboxd.com and log in (Desktop only).
2. Under your profile, click "Settings".
3. In the top bar, navigate to "Data" and click "Export your data".
4. Download and unzip the file.
5. You will recived multiple CSVs. Upload the one titled "diary.csv" here.
''';
    } else {
      infoText = 'Instructions not available.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('How to Export from $service'),
        content: Text(infoText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
                // Goodreads
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _ImportCard(
                            title: 'Goodreads',
                            description: 'Upload your reading history from Goodreads.',
                            icon: MediaType.book.icon,
                            color: MediaType.book.color,
                            buttonText: 'Upload Goodreads CSV',
                            uploadEnabled: true,
                            parser: GoodreadsImportParser(),
                            handler: GoodreadsImportHandler(),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              icon: const Icon(Icons.info_outline),
                              tooltip: 'How to export from Goodreads',
                              onPressed: () => _showInfoDialog(context, 'Goodreads'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Letterboxd
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack (children: [_ImportCard(
                        title: 'Letterboxd',
                        description: 'Import your watched films from Letterboxd.',
                        icon: MediaType.movie.icon,
                        color: MediaType.movie.color,
                        buttonText: 'Upload Letterboxd CSV',
                        uploadEnabled: true,
                        
                        parser: GoodreadsImportParser(), // same parser can be reused
                        handler: LetterboxdImportHandler(),
                      ),
                      Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              icon: const Icon(Icons.info_outline),
                              tooltip: 'How to export from Letterboxd',
                              onPressed: () => _showInfoDialog(context, 'Letterboxd'),
                            ),
                          ),
                   ] ),
                    )],
                ),
                const SizedBox(height: 24),
                // Spotify
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _ImportCard(
                            title: 'Spotify',
                            description: 'Import your music listening history from Spotify.',
                            icon: MediaType.music.icon,
                            color: MediaType.music.color,
                            buttonText: 'Coming Soon',
                            uploadEnabled: false,
                          ),
                          
                        ],
                      ),
                    ),
                  ],
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
  final ImportHandler? handler;

  _ImportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.buttonText,
    this.uploadEnabled = false,
    this.parser,
    this.handler,
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
    final parsedRows = widget.parser!.parse(contents);

    final svc = context.read<FirestoreService>();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();

    int successCount = 0;
    int errorCount = 0;

    for (final row in parsedRows) {
      try {
        if (widget.handler != null) {
          print(row);
          await widget.handler!.createFromMap(row, context, svc, userId, now);
          successCount++;
        }
      } catch (e) {
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
                  Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
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
