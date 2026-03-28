import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/providers/app_preferences_provider.dart';
import 'package:blog_app/core/providers/reading_history_provider.dart';
import 'package:blog_app/core/utils/archive_links.dart';
import 'package:blog_app/core/utils/app_feedback.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/providers/blog_insights_provider.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/providers/story_share_provider.dart';
import 'package:blog_app/features/blog/utils/post_insights.dart';
import 'package:blog_app/features/blog/widgets/comments_bottom_sheet.dart';
import 'package:blog_app/features/blog/widgets/markdown_content.dart';
import 'package:blog_app/features/profile/providers/profile_provider.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    this.sharedByUserId,
  });

  final PostModel post;
  final String? sharedByUserId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late final ScrollController _scrollController;
  late final ValueNotifier<double> _readingProgressNotifier;
  late final ReadingHistoryNotifier _readingHistoryNotifier;
  double _textScale = 1;
  double _lastPersistedProgress = 0;

  @override
  void initState() {
    super.initState();
    _textScale = ref.read(appPreferencesProvider).readerTextScale;
    _readingHistoryNotifier = ref.read(readingHistoryProvider.notifier);
    _readingProgressNotifier = ValueNotifier<double>(0);
    _scrollController = ScrollController()..addListener(_updateProgress);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _readingHistoryNotifier.trackOpen(widget.post);
    });
  }

  @override
  void dispose() {
    _readingHistoryNotifier.updateProgress(
      widget.post,
      _readingProgressNotifier.value,
    );
    _scrollController
      ..removeListener(_updateProgress)
      ..dispose();
    _readingProgressNotifier.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) {
      return;
    }

    final maxExtent = _scrollController.position.maxScrollExtent;
    final progress = maxExtent <= 0
        ? 0.0
        : (_scrollController.offset / maxExtent).clamp(0.0, 1.0);

    if (progress == _readingProgressNotifier.value) {
      return;
    }

    _readingProgressNotifier.value = progress;

    final shouldPersist =
        (progress - _lastPersistedProgress).abs() >= 0.1 || progress >= 0.98;
    if (shouldPersist) {
      _lastPersistedProgress = progress;
      _readingHistoryNotifier.updateProgress(widget.post, progress);
    }
  }

  void _showCommentsSheet(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postId: postId),
    );
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    AppFeedback.showSuccess(context, '$label copied to clipboard.');
  }

  Future<void> _copyStoryLink(PostModel post) async {
    await _copyToClipboard(
      ArchiveLinks.postUri(post.id).toString(),
      'Story link',
    );
  }

  Future<void> _shareStory(PostModel post) async {
    final shareLink =
        await ref.read(storyShareRepositoryProvider).createShareLink(post);
    await _copyToClipboard(
      shareLink.messageFor(post),
      shareLink.trackingEnabled ? 'Share message' : 'Story share message',
    );
    ref.invalidate(storyShareMetricsProvider(post.id));
  }

  void _openTopicSearch(String topic) {
    context.push(ArchiveLinks.discoverPath(query: topic));
  }

  Future<void> _setTextScale(double value,
      {bool persistDefault = false}) async {
    setState(() => _textScale = value);

    if (persistDefault) {
      await ref.read(appPreferencesProvider.notifier).setReaderTextScale(value);
      if (!mounted) {
        return;
      }
      AppFeedback.showSuccess(context, 'Default reading size updated.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(blogFeedProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final currentPost = feedState.value?.firstWhere(
          (post) => post.id == widget.post.id,
          orElse: () => widget.post,
        ) ??
        widget.post;
    final isAuthor = currentUserId == currentPost.userId;
    final relatedPosts = ref.watch(relatedPostsProvider(currentPost.id));
    final topics = PostInsights.extractTopics(currentPost);
    final wideLayout = AppLayout.isExpanded(context);
    final shareMetricsAsync =
        isAuthor ? ref.watch(storyShareMetricsProvider(currentPost.id)) : null;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _readingHistoryNotifier.updateProgress(
            widget.post,
            _readingProgressNotifier.value,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: colorScheme.onSurface,
            ),
            onPressed: () async {
              await _readingHistoryNotifier.updateProgress(
                widget.post,
                _readingProgressNotifier.value,
              );
              if (context.mounted) {
                context.pop();
              }
            },
          ),
          title: ValueListenableBuilder<double>(
            valueListenable: _readingProgressNotifier,
            builder: (context, progress, child) {
              return Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: ValueListenableBuilder<double>(
              valueListenable: _readingProgressNotifier,
              builder: (context, progress, child) {
                return LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: colorScheme.primary,
                );
              },
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.tune_rounded, color: colorScheme.onSurface),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (value) {
                if (value == 'copy_title') {
                  _copyToClipboard(currentPost.title, 'Title');
                } else if (value == 'copy_link') {
                  _copyStoryLink(currentPost);
                } else if (value == 'copy_story') {
                  _copyToClipboard(
                    PostInsights.plainText(currentPost.content),
                    'Story',
                  );
                } else if (value == 'copy_summary') {
                  _copyToClipboard(
                    '${currentPost.title}\nby @${currentPost.authorName}\n${PostInsights.estimatedReadLabel(currentPost.content)}',
                    'Story summary',
                  );
                } else if (value == 'text_small') {
                  _setTextScale(0.92);
                } else if (value == 'text_default') {
                  _setTextScale(1);
                } else if (value == 'text_large') {
                  _setTextScale(1.12);
                } else if (value == 'save_text_default') {
                  _setTextScale(_textScale, persistDefault: true);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'copy_title',
                  child: Text('Copy title'),
                ),
                PopupMenuItem<String>(
                  value: 'copy_link',
                  child: Text('Copy story link'),
                ),
                PopupMenuItem<String>(
                  value: 'copy_story',
                  child: Text('Copy story text'),
                ),
                PopupMenuItem<String>(
                  value: 'copy_summary',
                  child: Text('Copy share summary'),
                ),
                PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'text_small',
                  child: Text('Smaller text'),
                ),
                PopupMenuItem<String>(
                  value: 'text_default',
                  child: Text('Default text'),
                ),
                PopupMenuItem<String>(
                  value: 'text_large',
                  child: Text('Larger text'),
                ),
                PopupMenuItem<String>(
                  value: 'save_text_default',
                  child: Text('Save as default size'),
                ),
              ],
            ),
          ],
        ),
        body: InkBackground(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: wideLayout ? 1180 : 760,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: AppLayout.pagePadding(context)
                          .copyWith(top: 16, bottom: 24),
                      child: wideLayout
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _buildStoryBody(
                                    context,
                                    currentPost,
                                    topics,
                                    _readingProgressNotifier,
                                    sharedByUserId: widget.sharedByUserId,
                                    includeRelatedStories: false,
                                  ),
                                ),
                                const SizedBox(width: 28),
                                SizedBox(
                                  width: 320,
                                  child: _buildSidePanel(
                                    context,
                                    currentPost,
                                    topics,
                                    relatedPosts,
                                    _readingProgressNotifier,
                                    shareMetricsAsync: shareMetricsAsync,
                                  ),
                                ),
                              ],
                            )
                          : _buildStoryBody(
                              context,
                              currentPost,
                              topics,
                              _readingProgressNotifier,
                              sharedByUserId: widget.sharedByUserId,
                              includeRelatedStories: true,
                              relatedPosts: relatedPosts,
                            ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.92),
                        border: Border(
                          top: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  currentPost.isLikedByMe
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: currentPost.isLikedByMe
                                      ? Colors.redAccent
                                      : colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () => ref
                                    .read(blogFeedProvider.notifier)
                                    .toggleLike(currentPost.id),
                              ),
                              Text(
                                currentPost.likesCount.toString(),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(
                                  Icons.chat_bubble_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () =>
                                    _showCommentsSheet(context, currentPost.id),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(
                                  Icons.share_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                tooltip: 'Share story',
                                onPressed: () => _shareStory(currentPost),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              currentPost.isBookmarkedByMe
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: currentPost.isBookmarkedByMe
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => ref
                                .read(blogFeedProvider.notifier)
                                .toggleBookmark(currentPost.id),
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
    );
  }

  Widget _buildStoryBody(
    BuildContext context,
    PostModel currentPost,
    List<String> topics,
    ValueNotifier<double> readingProgress, {
    String? sharedByUserId,
    required bool includeRelatedStories,
    List<PostModel> relatedPosts = const [],
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentPost.coverImageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: currentPost.coverImageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          currentPost.title,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.6,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/user/${currentPost.userId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                ProfileAvatar(
                  userId: currentPost.userId,
                  fallbackLabel: _initial(currentPost.authorName),
                  radius: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${currentPost.authorName}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${PostInsights.shortDate(currentPost.createdAt)} • ${PostInsights.estimatedReadLabel(currentPost.content)}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if ((sharedByUserId?.trim().isNotEmpty ?? false)) ...[
          _SharedByBanner(
            sharedByUserId: sharedByUserId!.trim(),
            currentPost: currentPost,
          ),
          const SizedBox(height: 20),
        ],
        if (topics.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: topics
                .map(
                  (topic) => _DetailPill(
                    label: topic,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurfaceVariant,
                    onTap: () => _openTopicSearch(topic),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 26),
        ] else
          const SizedBox(height: 24),
        MarkdownContent(
          content: currentPost.content,
          textScale: _textScale,
        ),
        if (includeRelatedStories && relatedPosts.isNotEmpty) ...[
          const SizedBox(height: 40),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 26),
          Text(
            'Related stories',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep reading with stories that overlap in topic, momentum, or author.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...relatedPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RelatedStoryCard(post: post),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSidePanel(
    BuildContext context,
    PostModel currentPost,
    List<String> topics,
    List<PostModel> relatedPosts,
    ValueNotifier<double> readingProgress, {
    AsyncValue<StoryShareMetrics>? shareMetricsAsync,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final shareMetrics = shareMetricsAsync?.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkPanel(
          padding: const EdgeInsets.all(20),
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading tools',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<double>(
                valueListenable: readingProgress,
                builder: (context, progress, child) {
                  return _InfoRow(
                    label: 'Progress',
                    value: '${(progress * 100).round()}%',
                  );
                },
              ),
              _InfoRow(
                label: 'Text size',
                value: '${(_textScale * 100).round()}%',
              ),
              _InfoRow(
                label: 'Estimated read',
                value: PostInsights.estimatedReadLabel(currentPost.content),
              ),
              _InfoRow(
                label: 'Published',
                value: PostInsights.shortDate(currentPost.createdAt),
              ),
              if (shareMetricsAsync != null) ...[
                _InfoRow(
                  label: 'Shares',
                  value: shareMetrics == null
                      ? '...'
                      : '${shareMetrics.shareCount}',
                ),
                _InfoRow(
                  label: 'Invite opens',
                  value: shareMetrics == null
                      ? '...'
                      : '${shareMetrics.openCount}',
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => _shareStory(currentPost),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share story'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _copyStoryLink(currentPost),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Copy story link'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _copyToClipboard(
                  '${currentPost.title}\nby @${currentPost.authorName}',
                  'Story summary',
                ),
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copy summary'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    _setTextScale(_textScale, persistDefault: true),
                icon: const Icon(Icons.text_fields_rounded),
                label: const Text('Save current text size'),
              ),
            ],
          ),
        ),
        if (topics.isNotEmpty) ...[
          const SizedBox(height: 18),
          InkPanel(
            padding: const EdgeInsets.all(20),
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Topics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: topics
                      .map(
                        (topic) => _DetailPill(
                          label: topic,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurfaceVariant,
                          onTap: () => _openTopicSearch(topic),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
        if (relatedPosts.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Related stories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          ...relatedPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RelatedStoryCard(post: post),
            ),
          ),
        ],
      ],
    );
  }
}

class _SharedByBanner extends ConsumerWidget {
  const _SharedByBanner({
    required this.sharedByUserId,
    required this.currentPost,
  });

  final String sharedByUserId;
  final PostModel currentPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final sharedByAuthor = sharedByUserId == currentPost.userId;
    final sharerProfileAsync = sharedByAuthor
        ? null
        : ref.watch(publicProfileProvider(sharedByUserId));

    final sharerHandle = sharedByAuthor
        ? '@${currentPost.authorName}'
        : sharerProfileAsync?.valueOrNull?.username != null
            ? '@${sharerProfileAsync!.valueOrNull!.username}'
            : 'another writer';

    final title =
        sharedByAuthor ? 'Shared by the author' : 'Shared by $sharerHandle';
    final body = sharedByAuthor
        ? 'Jump to the author profile to follow more stories from this writer.'
        : 'Open $sharerHandle\'s profile to find more writing and connect inside Inkwell.';

    return InkPanel(
      padding: const EdgeInsets.all(18),
      radius: 24,
      color: colorScheme.surface.withValues(alpha: 0.96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/user/$sharedByUserId'),
            icon: const Icon(Icons.person_outline_rounded),
            label: Text(sharedByAuthor
                ? 'View author profile'
                : 'View shared-by profile'),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedStoryCard extends StatelessWidget {
  const _RelatedStoryCard({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push(
        ArchiveLinks.postPath(post.id),
        extra: post,
      ),
      child: InkPanel(
        padding: const EdgeInsets.all(18),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              PostInsights.excerpt(post.content),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '@${post.authorName} | ${PostInsights.estimatedReadLabel(post.content)}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initial(String authorName) {
  final trimmed = authorName.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}
