import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/utils/app_error_mapper.dart';
import 'package:blog_app/core/utils/app_feedback.dart';
import 'package:blog_app/core/utils/app_validators.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/profile/providers/profile_provider.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';
import 'package:blog_app/theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profileData,
  });

  final Map<String, dynamic> profileData;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final ProfileRepository _profileRepository;
  File? _avatarFile;
  Uint8List? _avatarBytes;
  String? _avatarCacheBuster;
  bool _isLoading = false;

  String get _userId =>
      widget.profileData['id'] as String? ??
      Supabase.instance.client.auth.currentUser?.id ??
      '';

  @override
  void initState() {
    super.initState();
    _profileRepository = ref.read(profileRepositoryProvider);
    _fullNameController = TextEditingController(
      text: widget.profileData['full_name'] as String? ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.profileData['username'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1080,
    );

    if (pickedFile == null) {
      return;
    }

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarBytes = bytes;
        _avatarFile = null;
      });
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _avatarFile = File(pickedFile.path);
      _avatarBytes = null;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      AppFeedback.showInfo(context, 'Please fix the highlighted fields first.');
      return;
    }

    final newName = _fullNameController.text.trim();
    final newUsername = _usernameController.text.trim().toLowerCase();

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }

      await Supabase.instance.client.from('profiles').update({
        'full_name': newName,
        'username': newUsername,
      }).eq('id', user.id);

      if (_avatarFile != null || _avatarBytes != null) {
        final avatarUrl = await _profileRepository.uploadAvatar(
          userId: user.id,
          imageFile: _avatarFile,
          webImageBytes: _avatarBytes,
        );
        _avatarCacheBuster = Uri.parse(avatarUrl).queryParameters['v'];
      }

      if (!mounted) {
        return;
      }

      AppFeedback.showSuccess(
        context,
        'Profile updated successfully.',
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, AppErrorMapper.readable(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _updateProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: InkBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                padding: AppLayout.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F172A),
                            Color(0xFF312E81),
                            Color(0xFF1D4ED8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppTheme.panelBorder(colorScheme),
                        ),
                        boxShadow: AppTheme.panelShadows(
                          colorScheme.brightness,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 560;

                          return stacked
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildAvatarBlock(context),
                                    const SizedBox(height: 20),
                                    _buildHeroCopy(),
                                  ],
                                )
                              : Row(
                                  children: [
                                    _buildAvatarBlock(context),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildHeroCopy()),
                                  ],
                                );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.panelBorder(colorScheme),
                        ),
                        boxShadow: AppTheme.panelShadows(
                          colorScheme.brightness,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Profile details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Keep your public identity clear, readable, and consistent across every device.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _fullNameController,
                              textCapitalization: TextCapitalization.words,
                              validator: AppValidators.fullName,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _usernameController,
                              autocorrect: false,
                              validator: AppValidators.username,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(
                                  Icons.alternate_email_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                helperText:
                                    'Use at least 3 characters. Letters, numbers, underscores, and periods work best.',
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarBlock(BuildContext context) {
    final fallbackLabel = _safeInitial(
      _fullNameController.text.trim().isEmpty
          ? _usernameController.text
          : _fullNameController.text,
    );

    Widget avatar = ProfileAvatar(
      userId: _userId,
      fallbackLabel: fallbackLabel,
      radius: 42,
      cacheBuster: _avatarCacheBuster,
    );

    if (_avatarBytes != null) {
      avatar = CircleAvatar(
        radius: 42,
        backgroundImage: MemoryImage(_avatarBytes!),
      );
    } else if (_avatarFile != null) {
      avatar = CircleAvatar(
        radius: 42,
        backgroundImage: FileImage(_avatarFile!),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
              width: 2,
            ),
          ),
          child: avatar,
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          onPressed: _pickAvatar,
          icon: const Icon(Icons.photo_camera_back_outlined),
          label: const Text('Change photo'),
        ),
      ],
    );
  }

  Widget _buildHeroCopy() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Update the way readers recognize you.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'A strong profile photo and a clean public name make every comment, message, and story feel more professional.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
      ],
    );
  }
}

String _safeInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}
