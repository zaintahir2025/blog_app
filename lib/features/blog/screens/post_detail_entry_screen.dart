import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/providers/story_share_provider.dart';
import 'package:blog_app/features/blog/screens/post_detail_screen.dart';

class PostDetailEntryScreen extends ConsumerStatefulWidget {
  const PostDetailEntryScreen({
    super.key,
    required this.postId,
    this.initialPost,
    this.shareId,
    this.sharedByUserId,
  });

  final String postId;
  final PostModel? initialPost;
  final String? shareId;
  final String? sharedByUserId;

  @override
  ConsumerState<PostDetailEntryScreen> createState() =>
      _PostDetailEntryScreenState();
}

class _PostDetailEntryScreenState extends ConsumerState<PostDetailEntryScreen> {
  @override
  void initState() {
    super.initState();
    final shareId = widget.shareId?.trim() ?? '';
    if (shareId.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(storyShareRepositoryProvider).recordShareOpen(
              shareId: shareId,
              postId: widget.postId,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialPost != null) {
      return PostDetailScreen(
        post: widget.initialPost!,
        sharedByUserId: widget.sharedByUserId,
      );
    }

    final postAsync = ref.watch(postByIdProvider(widget.postId));

    return postAsync.when(
      data: (post) {
        if (post == null) {
          return const _StoryLookupState(
            title: 'Story not found',
            body: 'This story may have been removed or is no longer public.',
            icon: Icons.auto_stories_outlined,
          );
        }

        return PostDetailScreen(
          post: post,
          sharedByUserId: widget.sharedByUserId,
        );
      },
      loading: () => const _StoryLookupState(
        title: 'Opening story',
        body: 'We are fetching the latest version of this story.',
        icon: Icons.hourglass_top_rounded,
        loading: true,
      ),
      error: (error, stack) => _StoryLookupState(
        title: 'Could not open story',
        body: '$error',
        icon: Icons.cloud_off_rounded,
      ),
    );
  }
}

class _StoryLookupState extends StatelessWidget {
  const _StoryLookupState({
    required this.title,
    required this.body,
    required this.icon,
    this.loading = false,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: InkBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: InkPanel(
                radius: 30,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    else
                      Icon(
                        icon,
                        size: 64,
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
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
}
