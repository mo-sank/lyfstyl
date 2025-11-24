import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/enhanced_trending_service.dart';
import '../../models/media_item.dart';
import '../../models/enhanced_log_entry.dart' as enhanced;
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../models/log_entry.dart' as base;

class EnhancedAddLogScreen extends StatefulWidget {
  final Map<String, dynamic>? preFilledData;
  final EnhancedTrendingItem? trendingItem;
  
  const EnhancedAddLogScreen({
    super.key, 
    this.preFilledData,
    this.trendingItem,
  });

  @override
  State<EnhancedAddLogScreen> createState() => _EnhancedAddLogScreenState();
}

class _EnhancedAddLogScreenState extends State<EnhancedAddLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _creatorCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();
  final _playCountCtrl = TextEditingController();
  
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

  @override
  void initState() {
    super.initState();
    _preFillForm();
  }

  void _preFillForm() {
    if (widget.trendingItem != null) {
      final item = widget.trendingItem!;
      _titleCtrl.text = item.title;
      _creatorCtrl.text = item.artist;
      _type = MediaType.music;
      _album = item.musicData.album;
      _genres = item.musicData.genres;
      _year = item.musicData.year;
      _durationSeconds = item.musicData.durationSeconds;
      _playCount = item.musicData.playCount ?? 1;
      _playCountCtrl.text = _playCount.toString();
    } else if (widget.preFilledData != null) {
      final data = widget.preFilledData!;
      _titleCtrl.text = data['title'] ?? '';
      _creatorCtrl.text = data['creator'] ?? '';
      
      // Set media type based on pre-filled data
      final typeString = data['type']?.toString().toLowerCase();
      switch (typeString) {
        case 'music':
          _type = MediaType.music;
          break;
        case 'book':
          _type = MediaType.book;
          break;
        case 'film':
        default:
          _type = MediaType.movie;
          break;
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final svc = context.read<FirestoreService>();
      final media = await svc.getOrCreateMedia(
        title: _titleCtrl.text.trim(),
        type: _type,
        creator: _creatorCtrl.text.trim().isEmpty ? null : _creatorCtrl.text.trim(),
      );
      
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final now = DateTime.now();
      
      // Create consumption data based on media type
      Map<String, dynamic> consumptionData = {};
      
      if (_type == MediaType.music) {
        final musicData = enhanced.MusicConsumptionData(
          durationSeconds: _durationSeconds,
          playCount: _playCount,
          album: _album,
          artist: _creatorCtrl.text.trim(),
          genres: _genres,
          year: _year,
        );
        consumptionData = musicData.toMap();
      }
      
      final log = base.LogEntry(
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
      
      await svc.createLog(log);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log added successfully!')),
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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _creatorCtrl.dispose();
    _tagsCtrl.dispose();
    _reviewCtrl.dispose();
    _playCountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Log'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Media Type Dropdown
              DropdownButtonFormField<MediaType>(
                initialValue: _type,
                items: MediaType.values
                    .map((t) => DropdownMenuItem(
                          value: t, 
                          child: Text(t.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? MediaType.movie),
                decoration: const InputDecoration(
                  labelText: 'Media Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title Field
              CustomTextField(
                controller: _titleCtrl,
                label: 'Title',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              
              // Creator/Artist Field
              CustomTextField(
                controller: _creatorCtrl,
                label: _type == MediaType.music ? 'Artist' : 
                       _type == MediaType.book ? 'Author' : 'Director',
              ),
              const SizedBox(height: 16),
              
              // Music-specific fields
              if (_type == MediaType.music) ...[
                _buildMusicSpecificFields(),
                const SizedBox(height: 16),
              ],
              
              // Rating Slider
              _buildRatingSlider(),
              const SizedBox(height: 16),
              
              // Review Field
              CustomTextField(
                controller: _reviewCtrl,
                label: 'Review (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Tags Field
              CustomTextField(
                controller: _tagsCtrl,
                label: 'Tags (comma separated)',
              ),
              const SizedBox(height: 16),
              
              // Consumed Date
              _buildDatePicker(),
              const SizedBox(height: 24),
              
              // Save Button
              CustomButton(
                text: 'Save Log', 
                onPressed: _saving ? null : _save, 
                isLoading: _saving,
              ),
            ],
          ),
        ),
      ),
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
        
        // Album Field
        if (_album != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.album, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Album: $_album',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Duration Field
        if (_durationSeconds != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Duration: ${_formatDuration(_durationSeconds!)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Play Count Field
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
        
        // Genres
        if (_genres.isNotEmpty) ...[
          Text(
            'Genres:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _genres.map((genre) => Chip(
              label: Text(genre),
              backgroundColor: Colors.blue[100],
              labelStyle: const TextStyle(fontSize: 12),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating: ${_rating?.toStringAsFixed(1) ?? 'Not rated'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Slider(
          min: 0,
          max: 5,
          divisions: 10,
          value: (_rating ?? 0),
          label: _rating?.toStringAsFixed(1) ?? '0',
          onChanged: (v) => setState(() => _rating = v == 0 ? null : v),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.calendar_today),
        title: const Text('Consumed Date'),
        subtitle: Text(_consumedAt.toLocal().toString().split(' ').first),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _consumedAt,
            firstDate: DateTime(1950),
            lastDate: DateTime.now().add(const Duration(days: 1)),
          );
          if (picked != null) setState(() => _consumedAt = picked);
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }
}
