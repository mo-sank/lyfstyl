

// Mohamed Sankari - 4 hours

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/media_item.dart';
import '../../models/log_entry.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AddLogScreen extends StatefulWidget {
  final Map<String, dynamic>? preFilledData;
  
  const AddLogScreen({super.key, this.preFilledData});

  @override
  State<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends State<AddLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _creatorCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();
  final _playCountCtrl = TextEditingController();
  final _albumCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _genresCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  MediaType _type = MediaType.movie;
  double? _rating;
  DateTime _consumedAt = DateTime.now();
  bool _saving = false;
  
  // Music-specific fields
  int? _durationSeconds;
  int? _playCount;
  String? _album;
  List<String> _genres = [];
  int? _year;

  // Book-specific fields
  int? _pages;
  int? _isbn;
  int? _isbn13;
  String? _publisher;
  int? _readCount;

  // Optional cover art passed from discovery/bookmarks
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _preFillForm();
  }

  void _preFillForm() {
    if (widget.preFilledData != null) {
      final data = widget.preFilledData!;
      _titleCtrl.text = data['title'] ?? '';
      _creatorCtrl.text = data['creator'] ?? '';
      _coverUrl = data['coverUrl'] as String?;
      
      // Set media type based on pre-filled data
      final typeString = data['type']?.toString().toLowerCase();
      switch (typeString) {
        case 'music':
          _type = MediaType.music;
          // Pre-fill music-specific data if available
          if (data['musicData'] != null) {
            final musicData = data['musicData'] as Map<String, dynamic>;
            _album = musicData['album'] as String?;
            _genres = (musicData['genres'] as List<dynamic>? ?? []).cast<String>();
            _year = musicData['year'] as int?;
            _durationSeconds = musicData['durationSeconds'] as int?;
            _playCount = musicData['playCount'] as int? ?? 1;
            
            // Update controllers
            _albumCtrl.text = _album ?? '';
            _genresCtrl.text = _genres.join(', ');
            _yearCtrl.text = _year?.toString() ?? '';
            _playCountCtrl.text = _playCount.toString();
            _durationCtrl.text = _durationSeconds != null ? _formatDuration(_durationSeconds!) : '';
          }
          break;
        case 'book':
          _type = MediaType.book;
          if (data['bookData'] != null) {
            final bookData = data['bookData'] as Map<String, dynamic>;
            _pages = bookData['pages'] as int?;
            _isbn = bookData['isbn'] as int?;
            _isbn13 = bookData['isbn13'] as int?;
            _publisher = bookData['publisher'] as String?;
            _readCount = bookData['readCount'] as int?;
          }

          break;
        case 'film':
        default:
          _type = MediaType.movie;
          // Pre-fill film-specific data if available
          if (data['filmData'] != null) {
            final filmData = data['filmData'] as Map<String, dynamic>;
            _year = filmData['year'] as int?;
            _genres = (filmData['genres'] as List<dynamic>? ?? []).cast<String>();
            
            // Update controllers
            _genresCtrl.text = _genres.join(', ');
            _yearCtrl.text = _year?.toString() ?? '';
          }
          break;
      }
    }
  }

// Make sure form is valid before saving in its current state
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      // Getting firestore service from our backend
      final svc = context.read<FirestoreService>();
      final media = await svc.getOrCreateMedia(
        title: _titleCtrl.text.trim(),
        type: _type,
        creator: _creatorCtrl.text.trim().isEmpty ? null : _creatorCtrl.text.trim(),
        coverUrl: _coverUrl,
      );
      // Getting user ID and filling out the log entry data
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final now = DateTime.now();
      
      // Create consumption data based on media type
      Map<String, dynamic> consumptionData = {};
      
      if (_type == MediaType.music) {
        final musicData = MusicConsumptionData(
          durationSeconds: _durationSeconds,
          playCount: _playCount,
          album: _album,
          artist: _creatorCtrl.text.trim(),
          genres: _genres,
          year: _year,
        );
        consumptionData = musicData.toMap();
      } else if (_type == MediaType.movie) {
        consumptionData = {
          'director': _creatorCtrl.text.trim().isEmpty ? null : _creatorCtrl.text.trim(),
          'genres': _genres,
          'year': _year,
        };
      } else if (_type == MediaType.book){
        final bookData = BookConsumptionData(
          pages: _pages,
          isbn: _isbn,
          isbn13: _isbn13,
          publisher: _publisher,
          readCount: _readCount
        );
        consumptionData = bookData.toMap();
      }
      
      final log = LogEntry(
        logId: 'temp',
        userId: userId,
        mediaId: media.mediaId,
        mediaType: _type,
        rating: _rating,
        review: _reviewCtrl.text.trim().isEmpty ? null : _reviewCtrl.text.trim(),
        tags: _tagsCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        consumedAt: _consumedAt,
        createdAt: now,
        updatedAt: now,
        consumptionData: consumptionData,
      );
      // Creating log in firestore
      await svc.createLog(log);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log added')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildFilmSpecificFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Film Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Genres Field
        CustomTextField(
          controller: _genresCtrl,
          label: 'Genres (comma separated)',
          onChanged: (value) {
            _genres = value
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          },
        ),
        const SizedBox(height: 12),
        
        // Year Field
        CustomTextField(
          controller: _yearCtrl,
          label: 'Release Year (optional)',
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _year = int.tryParse(value);
          },
        ),
      ],
    );
  }

  Widget _buildMusicSpecificFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Music Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Album Field - Always show, editable
        CustomTextField(
          controller: _albumCtrl,
          label: 'Album (optional)',
          onChanged: (value) => _album = value.trim().isEmpty ? null : value.trim(),
        ),
        const SizedBox(height: 12),
        
        // Duration Field - Always show, editable
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _durationCtrl,
                label: 'Duration (e.g., 3:45)',
                onChanged: (value) {
                  _durationSeconds = _parseDuration(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.timer),
              onPressed: () {
                // Could add a duration picker here
              },
              tooltip: 'Duration picker',
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Play Count Field - Always show
        CustomTextField(
          controller: _playCountCtrl,
          label: 'How many times did you listen?',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final count = int.tryParse(value);
              if (count == null || count < 1) {
                return 'Enter a valid number (1 or more)';
              }
            }
            return null;
          },
          onChanged: (value) {
            _playCount = int.tryParse(value);
          },
        ),
        const SizedBox(height: 12),
        
        // Genres Field - Always show, editable
        CustomTextField(
          controller: _genresCtrl,
          label: 'Genres (comma separated)',
          onChanged: (value) {
            _genres = value
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          },
        ),
        const SizedBox(height: 12),
        
        // Year Field - Always show, editable
        CustomTextField(
          controller: _yearCtrl,
          label: 'Release Year (optional)',
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _year = int.tryParse(value);
          },
        ),
      ],
    );
  }

  int? _parseDuration(String durationText) {
    if (durationText.trim().isEmpty) return null;
    
    // Parse formats like "3:45", "3:45:30", "45" (seconds)
    final parts = durationText.split(':');
    if (parts.length == 1) {
      // Just seconds
      return int.tryParse(parts[0]);
    } else if (parts.length == 2) {
      // Minutes:Seconds
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return minutes * 60 + seconds;
    } else if (parts.length == 3) {
      // Hours:Minutes:Seconds
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;
      return hours * 3600 + minutes * 60 + seconds;
    }
    return null;
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _creatorCtrl.dispose();
    _tagsCtrl.dispose();
    _reviewCtrl.dispose();
    _playCountCtrl.dispose();
    _albumCtrl.dispose();
    _durationCtrl.dispose();
    _genresCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Log')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<MediaType>(
                value: _type,
                items: MediaType.values
                    .map((t) => DropdownMenuItem(
                          value: t, 
                          child: Text(t.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? MediaType.movie),
                decoration: const InputDecoration(labelText: 'Media Type'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _titleCtrl,
                label: 'Title',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _creatorCtrl,
                label: _type == MediaType.music ? 'Artist' : 
                       _type == MediaType.book ? 'Author' : 'Director',
              ),
              const SizedBox(height: 12),
              
              // Music-specific fields
              if (_type == MediaType.music) ...[
                _buildMusicSpecificFields(),
                const SizedBox(height: 12),
              ],
              
              // Film-specific fields
              if (_type == MediaType.movie) ...[
                _buildFilmSpecificFields(),
                const SizedBox(height: 12),
              ],
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Rating (optional)', border: OutlineInputBorder()),
                child: Slider(
                  min: 0,
                  max: 5,
                  divisions: 10,
                  value: (_rating ?? 0),
                  label: _rating?.toStringAsFixed(1) ?? '0',
                  onChanged: (v) => setState(() => _rating = v == 0 ? null : v),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _reviewCtrl,
                label: 'Review (optional)',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _tagsCtrl,
                label: 'Tags (comma separated)',
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Consumed date'),
                subtitle: Text(_consumedAt.toLocal().toString().split(' ').first),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _consumedAt,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) setState(() => _consumedAt = picked);
                  },
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(text: 'Save', onPressed: _saving ? null : _save, isLoading: _saving),
            ],
          ),
        ),
      ),
    );
  }
}
