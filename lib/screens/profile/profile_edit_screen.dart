import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController(); // comma separated
  bool _isPublic = true;
  bool _loading = true;

  late UserProfile _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final svc = context.read<FirestoreService>();
    await svc.ensureUserProfile(FirebaseAuth.instance.currentUser!);
    final profile = await svc.getUserProfile(uid);
    if (profile != null) {
      _existing = profile;
      _nameCtrl.text = profile.displayName ?? '';
      _bioCtrl.text = profile.bio ?? '';
      _interestsCtrl.text = profile.interests.join(', ');
      _isPublic = profile.isPublic;
    } else {
      _existing = UserProfile(
        userId: uid,
        email: FirebaseAuth.instance.currentUser!.email ?? '',
        displayName: null,
        username: null,
        bio: null,
        interests: const [],
        favoriteIds: const [],
        isPublic: true,
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final interests = _interestsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updated = UserProfile(
      userId: _existing.userId,
      email: _existing.email,
      displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      username: _existing.username,
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      interests: interests,
      favoriteIds: _existing.favoriteIds,
      isPublic: _isPublic,
      avatarUrl: _existing.avatarUrl,
      createdAt: _existing.createdAt,
      updatedAt: now,
    );

    await context.read<FirestoreService>().upsertUserProfile(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    CustomTextField(
                      controller: _nameCtrl,
                      label: 'Display name',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _bioCtrl,
                      label: 'Bio',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _interestsCtrl,
                      label: 'Interests (comma separated)',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Switch(
                          value: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v),
                        ),
                        const Text('Public profile')
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomButton(text: 'Save', onPressed: _save),
                  ],
                ),
              ),
            ),
    );
  }
}
