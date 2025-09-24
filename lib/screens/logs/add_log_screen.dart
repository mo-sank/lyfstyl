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
  MediaType _type = MediaType.film;
  double? _rating;
  DateTime _consumedAt = DateTime.now();
  bool _saving = false;

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
          _type = MediaType.film;
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
      final log = LogEntry(
        logId: 'temp',
        userId: userId,
        mediaId: media.mediaId,
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
      );

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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _creatorCtrl.dispose();
    _tagsCtrl.dispose();
    _reviewCtrl.dispose();
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
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? MediaType.film),
                decoration: const InputDecoration(labelText: 'Type'),
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
                label: 'Creator (optional)',
              ),
              const SizedBox(height: 12),
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
