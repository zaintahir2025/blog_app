import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:blog_app/core/utils/app_error_mapper.dart';
import 'package:blog_app/core/utils/app_feedback.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/utils/editor_draft_store.dart';
import 'package:blog_app/features/blog/utils/story_markup.dart';
import 'package:blog_app/features/blog/widgets/editor_insights_panel.dart';
import 'package:blog_app/features/blog/widgets/editor_live_preview_card.dart';
import 'package:blog_app/features/blog/widgets/markdown_toolbar.dart';
import 'package:blog_app/features/blog/widgets/publishing_checklist_card.dart';

enum _EditorSurfaceMode { write, preview }

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late final BlogFeedNotifier _blogFeedNotifier;

  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  bool _publishNow = true;
  bool _restoredDraft = false;
  DateTime? _lastSavedAt;
  Timer? _autosaveTimer;
  Timer? _previewRefreshTimer;
  StoryFontPreset _fontPreset = StoryFontPreset.clean;
  _EditorSurfaceMode _editorSurfaceMode = _EditorSurfaceMode.write;

  bool get _hasCoverImage => _webImageBytes != null || _imageFile != null;

  @override
  void initState() {
    super.initState();
    _blogFeedNotifier = ref.read(blogFeedProvider.notifier);
    _titleController.addListener(_handleEditorChanged);
    _contentController.addListener(_handleEditorChanged);
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final draft = EditorDraftStore.readDraft(EditorDraftStore.createDraftKey);
    if (draft == null || !mounted) {
      return;
    }

    final title = (draft['title'] as String?) ?? '';
    final rawContent = (draft['content'] as String?) ?? '';
    final isPublished = (draft['isPublished'] as bool?) ?? true;
    final updatedAt = DateTime.tryParse((draft['updatedAt'] as String?) ?? '');

    setState(() {
      _titleController.text = title;
      _contentController.text = StoryMarkup.normalizedBody(rawContent);
      _publishNow = isPublished;
      _fontPreset = StoryMarkup.fontPreset(rawContent);
      _restoredDraft = title.isNotEmpty || rawContent.isNotEmpty;
      _lastSavedAt = updatedAt;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) {
      return;
    }

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _webImageBytes = bytes;
        _imageFile = null;
      });
    } else {
      if (!mounted) {
        return;
      }
      setState(() {
        _imageFile = File(pickedFile.path);
        _webImageBytes = null;
      });
    }
    _scheduleAutosave();
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _webImageBytes = null;
    });
    _scheduleAutosave();
  }

  Future<String?> _pickInlineStoryImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 76,
        maxWidth: 1440,
      );
      if (pickedFile == null) {
        return null;
      }
      if (!mounted) {
        return null;
      }

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        if (!mounted) {
          return null;
        }
        return _blogFeedNotifier.uploadStoryImage(
          webImageBytes: bytes,
          prefix: 'inline',
        );
      }

      return _blogFeedNotifier.uploadStoryImage(
        imageFile: File(pickedFile.path),
        prefix: 'inline',
      );
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          AppErrorMapper.readable(
            error,
            fallback: 'Image upload failed. Please try again.',
          ),
        );
      }
      return null;
    }
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      AppFeedback.showInfo(
        context,
        'Add both a title and story content before publishing.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _blogFeedNotifier.addPost(
        title: _titleController.text,
        content: _composedContent(),
        isPublished: _publishNow,
        imageFile: _imageFile,
        webImageBytes: _webImageBytes,
      );
      await EditorDraftStore.clearDraft(EditorDraftStore.createDraftKey);

      if (!mounted) {
        return;
      }
      AppFeedback.showSuccess(
        context,
        _publishNow
            ? 'Story published successfully.'
            : 'Draft saved to your profile.',
      );
      context.pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, AppErrorMapper.readable(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearLocalDraft() async {
    await EditorDraftStore.clearDraft(EditorDraftStore.createDraftKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _restoredDraft = false;
      _lastSavedAt = null;
    });
    AppFeedback.showInfo(context, 'Local draft cache cleared.');
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 700), () async {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      if (title.isEmpty && content.isEmpty) {
        return;
      }

      await EditorDraftStore.saveDraft(
        key: EditorDraftStore.createDraftKey,
        title: title,
        content: _composedContent(),
        isPublished: _publishNow,
      );

      if (mounted) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  Widget? _buildPreviewImage() {
    if (_webImageBytes != null) {
      return Image.memory(_webImageBytes!, fit: BoxFit.cover);
    }
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    }
    return null;
  }

  String _composedContent() {
    return StoryMarkup.applyFontPreset(
      _contentController.text.trim(),
      _fontPreset,
    );
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _previewRefreshTimer?.cancel();
    _titleController.removeListener(_handleEditorChanged);
    _contentController.removeListener(_handleEditorChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compactLayout = AppLayout.isCompact(context);
    final wideLayout = AppLayout.isExpanded(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Studio'),
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
          else ...[
            if (!compactLayout && _lastSavedAt != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    'Autosaved ${_formatSavedAt(_lastSavedAt!)}',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (compactLayout && _lastSavedAt != null)
              IconButton(
                tooltip: 'Autosaved ${_formatSavedAt(_lastSavedAt!)}',
                onPressed: null,
                icon: Icon(
                  Icons.cloud_done_outlined,
                  color: colorScheme.primary,
                ),
              ),
            if (_lastSavedAt != null)
              IconButton(
                tooltip: 'Clear local draft',
                onPressed: _clearLocalDraft,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _submitPost,
                child: Text(
                  compactLayout
                      ? (_publishNow ? 'Publish' : 'Save')
                      : (_publishNow ? 'Publish' : 'Save Draft'),
                ),
              ),
            ),
          ],
        ],
      ),
      body: InkBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: AppLayout.contentMaxWidth(context)),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppLayout.pagePadding(context),
                child: wideLayout
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: _buildEditorColumn(context)),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 340,
                            child: _buildSidePanel(context),
                          ),
                        ],
                      )
                    : compactLayout
                        ? _buildCompactWorkspace(context)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildEditorColumn(context),
                              const SizedBox(height: 24),
                              _buildSidePanel(context),
                            ],
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactWorkspace(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_restoredDraft) ...[
          _buildDraftRestorationNotice(context),
          const SizedBox(height: 20),
        ],
        _buildIntroCard(),
        const SizedBox(height: 20),
        _buildPublishingModeCard(context),
        const SizedBox(height: 16),
        _buildWorkspaceModeSwitch(context),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(_editorSurfaceMode),
            child: _editorSurfaceMode == _EditorSurfaceMode.write
                ? _buildEditorColumn(
                    context,
                    compactLayout: true,
                    showIntroCard: false,
                    showRestoredDraftNotice: false,
                  )
                : _buildPreviewPane(
                    context,
                    fullPreview: true,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorColumn(
    BuildContext context, {
    bool compactLayout = false,
    bool showIntroCard = true,
    bool showRestoredDraftNotice = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_restoredDraft && showRestoredDraftNotice) ...[
          _buildDraftRestorationNotice(context),
          const SizedBox(height: 20),
        ],
        if (showIntroCard) ...[
          _buildIntroCard(),
          const SizedBox(height: 24),
        ],
        _buildCoverCard(context, compactLayout: compactLayout),
        const SizedBox(height: 24),
        MarkdownToolbar(
          controller: _contentController,
          fontPreset: _fontPreset,
          compact: compactLayout,
          onFontPresetChanged: (preset) => setState(() => _fontPreset = preset),
          onInsertImage: _pickInlineStoryImage,
        ),
        const SizedBox(height: 18),
        InkPanel(
          padding: const EdgeInsets.all(24),
          radius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: compactLayout ? 28 : 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Post Title',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
              Divider(color: colorScheme.outlineVariant),
              TextField(
                controller: _contentController,
                style: TextStyle(
                  fontSize: compactLayout ? 16 : 18,
                  color: colorScheme.onSurface,
                  height: 1.8,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Write your story here...\n\nTip: headings, quotes, lists, bold text, and inline images are supported.',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPane(
    BuildContext context, {
    required bool fullPreview,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorLivePreviewCard(
          title: _titleController.text,
          content: _composedContent(),
          previewImage: _buildPreviewImage(),
          fullPreview: fullPreview,
        ),
        const SizedBox(height: 18),
        EditorInsightsPanel(
          title: _titleController.text,
          content: _composedContent(),
          isPublished: _publishNow,
          fontPresetLabel: StoryMarkup.fontLabel(_fontPreset),
          statusLabel: _lastSavedAt == null
              ? 'Autosave is on while you write.'
              : 'Autosaved ${_formatSavedAt(_lastSavedAt!)}',
        ),
        const SizedBox(height: 18),
        PublishingChecklistCard(
          title: _titleController.text,
          content: _composedContent(),
          hasCoverImage: _hasCoverImage,
        ),
      ],
    );
  }

  Widget _buildSidePanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPublishingModeCard(context),
        const SizedBox(height: 18),
        _buildPreviewPane(
          context,
          fullPreview: false,
        ),
      ],
    );
  }

  Widget _buildPublishingModeCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkPanel(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publishing mode',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<bool>(
                value: false,
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Draft'),
              ),
              ButtonSegment<bool>(
                value: true,
                icon: Icon(Icons.public_rounded),
                label: Text('Publish'),
              ),
            ],
            selected: {_publishNow},
            onSelectionChanged: (selection) {
              setState(() => _publishNow = selection.first);
              _scheduleAutosave();
            },
          ),
          const SizedBox(height: 10),
          Text(
            _publishNow
                ? 'Your story will appear in the public feed when you submit.'
                : 'Keep refining privately and publish later from your profile.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverCard(
    BuildContext context, {
    bool compactLayout = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = Text(
      'Cover image',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(_hasCoverImage ? 'Replace' : 'Add image'),
        ),
        if (_hasCoverImage)
          TextButton.icon(
            onPressed: _removeImage,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Remove'),
          ),
      ],
    );

    return InkPanel(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          compactLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    actions,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    actions,
                  ],
                ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: compactLayout ? 200 : 240,
              width: double.infinity,
              color: colorScheme.surfaceContainerHighest,
              child: _webImageBytes != null
                  ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                  : _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.landscape_rounded,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add a cover image to give your story stronger feed presence.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return InkHeroCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InkEyebrow(label: 'Story Studio'),
          const SizedBox(height: 16),
          Text(
            'Craft a story that reads well everywhere.',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Autosave protects your draft while the checklist and preview keep the post ready for publishing.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftRestorationNotice(BuildContext context) {
    return InkInfoBanner(
      icon: Icons.cloud_done_outlined,
      title: 'Recovered local draft',
      body:
          'Recovered your local draft${_lastSavedAt != null ? ' from ${_formatSavedAt(_lastSavedAt!)}' : ''}.',
      compact: true,
    );
  }

  Widget _buildWorkspaceModeSwitch(BuildContext context) {
    return InkPanel(
      padding: const EdgeInsets.all(6),
      radius: 20,
      child: SegmentedButton<_EditorSurfaceMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment<_EditorSurfaceMode>(
            value: _EditorSurfaceMode.write,
            icon: Icon(Icons.edit_note_rounded),
            label: Text('Write'),
          ),
          ButtonSegment<_EditorSurfaceMode>(
            value: _EditorSurfaceMode.preview,
            icon: Icon(Icons.visibility_outlined),
            label: Text('Preview'),
          ),
        ],
        selected: {_editorSurfaceMode},
        onSelectionChanged: (selection) {
          setState(() => _editorSurfaceMode = selection.first);
        },
      ),
    );
  }

  String _formatSavedAt(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleEditorChanged() {
    _previewRefreshTimer?.cancel();
    _previewRefreshTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {});
      }
    });
    _scheduleAutosave();
  }
}
