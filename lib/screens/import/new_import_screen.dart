import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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
                ),
                const SizedBox(height: 24),
                _ImportCard(
                  title: 'Letterboxd',
                  description: 'Import your watched films from Letterboxd.',
                  icon: Icons.movie,
                  color: Colors.teal,
                  buttonText: 'Upload Letterboxd CSV',
                  uploadEnabled: true,
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
  bool parseEnabled;

  _ImportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.buttonText,
    this.uploadEnabled = false,
    this.parseEnabled = false,
    super.key,
  });

  @override
  State<_ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends State<_ImportCard> {
  String? _fileName;
  final TextEditingController _controller = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.isNotEmpty) {
      widget.parseEnabled = true;
      setState(() {
        _fileName = result.files.single.name;
        _controller.text = _fileName ?? '';
      });
      // TODO: Handle file upload logic here
    }
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
                  if (widget.uploadEnabled && widget.parseEnabled) ...[
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
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(widget.buttonText, style: const TextStyle(fontSize: 16)),
                    ),
                  ] else if (widget.uploadEnabled)... [
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
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[600],
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
