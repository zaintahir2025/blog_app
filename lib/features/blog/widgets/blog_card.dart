import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/providers/app_preferences_provider.dart';
import 'package:blog_app/core/providers/reading_history_provider.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/utils/post_insights.dart';
import 'package:blog_app/features/blog/widgets/comments_bottom_sheet.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';
import 'package:blog_app/theme/app_theme.dart';

class BlogCard extends ConsumerWidget {
  const BlogCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.index,
  });

  final PostModel post;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? currentUserId;
    try {
      currentUserId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      currentUserId = null;
    }
    final isAuthor = currentUserId == post.userId;
    final preferences = ref.watch(appPreferencesProvider);
    final historyEntry = ref.watch(readingHistoryEntryProvider(post.id));
    final compactCards = preferences.compactCards;
    final narrow = MediaQuery.sizeOf(context).width < 700;

    final card = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width >= 1100 ? 760 : 700,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compactCards ? 10 : 16,
            vertical: compactCards ? 8 : 10,
          ),
          child: InkPanel(
            padding: EdgeInsets.all(compactCards ? 18 : 20),
            radius: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.coverImageUrl != null) ...[
                      _CoverImage(url: post.coverImageUrl!),
                      const SizedBox(height: 18),
                    ],
                    _AuthorRow(
                      post: post,
                      isAuthor: isAuthor,
                      onAuthorTap: () => context.push('/user/${post.userId}'),
                      onMenuSelected: (value) async {
                        if (value == 'edit') {
                          context.push('/edit_post', extra: post);
                        } else if (value == 'publish') {
                          await ref
                              .read(blogFeedProvider.notifier)
                              .togglePublish(post.id, post.isPublished);
                        } else if (value == 'delete') {
                          final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete story?'),
                                  content: const Text(
                                    'This removes the story from your studio and the public feed.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Keep it'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                          if (!context.mounted || !confirmed) {
                            return;
                          }
                          await ref
                              .read(blogFeedProvider.notifier)
                              .deletePost(post.id);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    _MetaWrap(post: post, historyEntry: historyEntry),
                    const SizedBox(height: 14),
                    Text(
                      post.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: compactCards ? 24 : 26,
                                height: 1.1,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      PostInsights.excerpt(
                        post.content,
                        maxLength: compactCards ? 145 : 180,
                      ),
                      maxLines: compactCards ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = narrow || constraints.maxWidth < 480;
                        final quickActions = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InlineActionButton(
                              icon: post.isLikedByMe
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              label: '${post.likesCount}',
                              active: post.isLikedByMe,
                              activeColor: Colors.redAccent,
                              onTap: () => ref
                                  .read(blogFeedProvider.notifier)
                                  .toggleLike(post.id),
                            ),
                            _InlineActionButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Comments',
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      CommentsBottomSheet(postId: post.id),
                                );
                              },
                            ),
                            _InlineActionButton(
                              icon: post.isBookmarkedByMe
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              label: post.isBookmarkedByMe ? 'Saved' : 'Save',
                              active: post.isBookmarkedByMe,
                              onTap: () => ref
                                  .read(blogFeedProvider.notifier)
                                  .toggleBookmark(post.id),
                            ),
                          ],
                        );

                        final readButton = FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.brightness ==
                                        Brightness.light
                                    ? AppTheme.inkColor
                                    : Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.brightness ==
                                        Brightness.light
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: const Text('Read more'),
                        );

                        if (stacked) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              quickActions,
                              const SizedBox(height: 12),
                              readButton,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: quickActions),
                            const SizedBox(width: 12),
                            readButton,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: card.animate(delay: (index * 80).ms).fade(duration: 280.ms),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 8.2,
        child: CachedNetworkImage(
          imageUrl: url,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.post,
    required this.isAuthor,
    required this.onAuthorTap,
    required this.onMenuSelected,
  });

  final PostModel post;
  final bool isAuthor;
  final VoidCallback onAuthorTap;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onAuthorTap,
            child: Row(
              children: [
                ProfileAvatar(
                  userId: post.userId,
                  fallbackLabel: _authorInitial(post.authorName),
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${post.authorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${PostInsights.shortDate(post.createdAt)} | ${PostInsights.estimatedReadLabel(post.content)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isAuthor)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onSelected: onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit story'),
              ),
              PopupMenuItem<String>(
                value: 'publish',
                child: Text(post.isPublished ? 'Move to draft' : 'Publish'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _MetaWrap extends StatelessWidget {
  const _MetaWrap({
    required this.post,
    required this.historyEntry,
  });

  final PostModel post;
  final ReadingHistoryEntry? historyEntry;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!post.isPublished)
          const _MetaChip(
            label: 'Draft',
            highlighted: true,
          ),
        _MetaChip(label: PostInsights.estimatedReadLabel(post.content)),
        _MetaChip(label: PostInsights.shortDate(post.createdAt)),
        if (historyEntry != null &&
            historyEntry!.progress > 0 &&
            !historyEntry!.isCompleted)
          _MetaChip(
            label: historyEntry!.progressLabel,
            highlighted: true,
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary.withValues(alpha: 0.18)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: highlighted
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = active
        ? (activeColor ?? colorScheme.primary)
        : colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? foreground.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? foreground.withValues(alpha: 0.18)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _authorInitial(String authorName) {
  final trimmed = authorName.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}
