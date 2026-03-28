import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/utils/app_error_mapper.dart';
import 'package:blog_app/core/utils/app_feedback.dart';
import 'package:blog_app/features/blog/providers/comment_provider.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';
import 'package:blog_app/theme/app_theme.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  const CommentsBottomSheet({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isPosting = true);
    try {
      await ref
          .read(commentsProvider(widget.postId).notifier)
          .addComment(_commentController.text);
      _commentController.clear();

      if (!mounted) {
        return;
      }
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppErrorMapper.readable(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete response?'),
            content: const Text(
              'This removes your response from the conversation.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted) {
      return;
    }
    if (!confirmed) {
      return;
    }

    try {
      await ref
          .read(commentsProvider(widget.postId).notifier)
          .deleteComment(commentId);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppErrorMapper.readable(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider(widget.postId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktopSheet = width >= 900;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktopSheet ? 24 : 0,
          24,
          isDesktopSheet ? 24 : 0,
          0,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(28),
                  bottom: Radius.circular(isDesktopSheet ? 28 : 0),
                ),
                border: Border.all(color: AppTheme.panelBorder(colorScheme)),
                boxShadow: AppTheme.panelShadows(colorScheme.brightness),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Responses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Divider(height: 32, color: colorScheme.outlineVariant),
                  Expanded(
                    child: commentsState.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            AppErrorMapper.readable(
                              err,
                              fallback:
                                  'Responses are unavailable right now. Please try again.',
                            ),
                            style: TextStyle(color: colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      data: (comments) {
                        if (comments.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No responses yet.\nBe the first to share your thoughts.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: colorScheme.outlineVariant),
                          ),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final isMyComment = comment.userId == currentUserId;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: () => context
                                          .push('/user/${comment.userId}'),
                                      child: ProfileAvatar(
                                        userId: comment.userId,
                                        fallbackLabel:
                                            _initial(comment.authorName),
                                        radius: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              InkWell(
                                                onTap: () => context.push(
                                                    '/user/${comment.userId}'),
                                                child: Text(
                                                  '@${comment.authorName}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}',
                                                style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            comment.content,
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: colorScheme.onSurface,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isMyComment)
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: colorScheme.error,
                                        ),
                                        onPressed: () =>
                                            _deleteComment(comment.id),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(isDesktopSheet ? 28 : 0),
                        ),
                        border: Border(
                          top: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            onSubmitted: (_) => _submitComment(),
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'What are your thoughts?',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          backgroundColor: colorScheme.primary,
                          radius: 24,
                          child: _isPosting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _submitComment,
                                ),
                        ),
                      ],
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
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}
