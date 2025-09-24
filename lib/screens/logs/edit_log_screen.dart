import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/log_entry.dart';
import '../../models/media_item.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EditLogScreen extends StatefulWidget {
  final MediaItem media;
  final LogEntry log;
  const EditLogScreen({super.key, required this.media, required this.log});

  @override
  State<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends State<EditLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  double? _rating;
  late DateTime _consumedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.log.rating;
    _reviewCtrl.text = widget.log.review ?? '';
    _tagsCtrl.text = widget.log.tags.join(', ');
    _consumedAt = widget.log.consumedAt;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await context.read<FirestoreService>().updateLog(widget.log.logId, {
      'rating': _rating,
      'review': _reviewCtrl.text.trim().isEmpty ? null : _reviewCtrl.text.trim(),
      'tags': tags,
      'consumedAt': _consumedAt,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log updated')));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Log')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(widget.media.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
