import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/image_upload_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  String? _avatarUrl;
  bool _uploadingAvatar = false;
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    setState(() => _uploadingAvatar = true);
    final url = await ImageUploadService.pickAndUpload(
      folder: 'avatars',
      maxWidth: 400,
      quality: 85,
    );
    if (mounted) {
      setState(() {
        if (url != null) _avatarUrl = url;
        _uploadingAvatar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userAsync = ref.watch(currentUserDocProvider);

    userAsync.whenData((userModel) {
      if (!_initialized && userModel != null) {
        _nameCtrl.text = userModel.displayName;
        _bioCtrl.text = userModel.bio;
        _cityCtrl.text = userModel.city;
        _stateCtrl.text = userModel.state;
        _avatarUrl =
            userModel.avatarUrl.isNotEmpty ? userModel.avatarUrl : null;
        _initialized = true;
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar picker
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: _avatarUrl != null
                        ? CachedNetworkImageProvider(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? Icon(Icons.person,
                            size: 48, color: theme.colorScheme.onSurface)
                        : null,
                  ),
                  if (_uploadingAvatar)
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    FloatingActionButton.small(
                      heroTag: 'avatar_pick',
                      onPressed: _pickAvatar,
                      child: const Icon(Icons.camera_alt, size: 18),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Display name
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Bio
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: AppSpacing.md),

            // City + State row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _stateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'State'),
                    maxLength: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save button
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _loading = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .update({
                          'displayName': _nameCtrl.text.trim(),
                          'bio': _bioCtrl.text.trim(),
                          'city': _cityCtrl.text.trim(),
                          'state': _stateCtrl.text.trim().toUpperCase(),
                          if (_avatarUrl != null) 'avatarUrl': _avatarUrl,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (!mounted) return;
                        navigator.pop();
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error saving profile: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
