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
import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/utils/story_markup.dart';
import 'package:blog_app/features/blog/widgets/editor_insights_panel.dart';
import 'package:blog_app/features/blog/widgets/editor_live_preview_card.dart';
import 'package:blog_app/features/blog/widgets/markdown_toolbar.dart';
import 'package:blog_app/features/blog/widgets/publishing_checklist_card.dart';

enum _EditorSurfaceMode { write, preview }

class EditPostScreen extends ConsumerStatefulWidget {
  const EditPostScreen({super.key, required this.post});

  final PostModel post;

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late final BlogFeedNotifier _blogFeedNotifier;

  File? _newImageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  late bool _publishNow;
  bool _removeExistingCover = false;
  late StoryFontPreset _fontPreset;
  Timer? _previewRefreshTimer;
  _EditorSurfaceMode _editorSurfaceMode = _EditorSurfaceMode.write;

  bool get _hasCoverImage =>
      _webImageBytes != null ||
      _newImageFile != null ||
      (widget.post.coverImageUrl != null && !_removeExistingCover);

  @override
  void initState() {
    super.initState();
    _blogFeedNotifier = ref.read(blogFeedProvider.notifier);
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(
      text: StoryMarkup.normalizedBody(widget.post.content),
    );
    _publishNow = widget.post.isPublished;
    _fontPreset = StoryMarkup.fontPreset(widget.post.content);
    _titleController.addListener(_refreshPreview);
    _contentController.addListener(_refreshPreview);
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
        _newImageFile = null;
        _removeExistingCover = false;
      });
    } else {
      if (!mounted) {
        return;
      }
      setState(() {
        _newImageFile = File(pickedFile.path);
        _webImageBytes = null;
        _removeExistingCover = false;
      });
    }
  }

  void _removeCover() {
    setState(() {
      _newImageFile = null;
      _webImageBytes = null;
      _removeExistingCover = true;
    });
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

  Future<void> _updatePost() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      AppFeedback.showInfo(
        context,
        'Add both a title and story content before saving.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _blogFeedNotifier.editPost(
        postId: widget.post.id,
        title: _titleController.text,
        content: _composedContent(),
        isPublished: _publishNow,
        removeCoverImage: _removeExistingCover,
        newImageFile: _newImageFile,
        webImageBytes: _webImageBytes,
        existingImageUrl: widget.post.coverImageUrl,
      );

      if (!mounted) {
        return;
      }
      AppFeedback.showSuccess(
        context,
        'Story updated successfully.',
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

  Widget? _buildPreviewImage() {
    if (_webImageBytes != null) {
      return Image.memory(_webImageBytes!, fit: BoxFit.cover);
    }
    if (_newImageFile != null) {
      return Image.file(_newImageFile!, fit: BoxFit.cover);
    }
    if (!_removeExistingCover && widget.post.coverImageUrl != null) {
      return Image.network(widget.post.coverImageUrl!, fit: BoxFit.cover);
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
    _previewRefreshTimer?.cancel();
    _titleController.removeListener(_refreshPreview);
    _contentController.removeListener(_refreshPreview);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compactLayout = AppLayout.isCompact(context);
    final wideLayout = AppLayout.isExpanded(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refine Story'),
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _updatePost,
                child: Text(compactLayout ? 'Save' : 'Save changes'),
              ),
            ),
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
        _buildIntroCard(),
        const SizedBox(height: 20),
        _buildVisibilityCard(context),
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
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      'Refine the story here...\n\nUse headings, bold text, quotes, lists, and inline images to improve flow.',
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
          statusLabel: _publishNow
              ? 'Saving keeps this story live in the public feed.'
              : 'Saving moves this story back into your drafts.',
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
        _buildVisibilityCard(context),
        const SizedBox(height: 18),
        _buildPreviewPane(
          context,
          fullPreview: false,
        ),
      ],
    );
  }

  Widget _buildVisibilityCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkPanel(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visibility',
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
                label: Text('Published'),
              ),
            ],
            selected: {_publishNow},
            onSelectionChanged: (selection) =>
                setState(() => _publishNow = selection.first),
          ),
          const SizedBox(height: 10),
          Text(
            _publishNow
                ? 'Readers can discover this story in the public feed.'
                : 'This story stays private until you publish it.',
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
            onPressed: _removeCover,
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
                  : _newImageFile != null
                      ? Image.file(_newImageFile!, fit: BoxFit.cover)
                      : !_removeExistingCover &&
                              widget.post.coverImageUrl != null
                          ? Image.network(
                              widget.post.coverImageUrl!,
                              fit: BoxFit.cover,
                            )
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
                                  'Add or replace the cover image to improve feed quality.',
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
          const InkEyebrow(label: 'Revision Room'),
          const SizedBox(height: 16),
          Text(
            'Refine the story without breaking momentum.',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Update the cover, move the story between draft and published states, and keep the reader preview in sync.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
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

  void _refreshPreview() {
    _previewRefreshTimer?.cancel();
    _previewRefreshTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {});
      }
    });
  }
}
