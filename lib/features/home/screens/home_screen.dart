import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:blog_app/core/providers/reading_history_provider.dart';
import 'package:blog_app/core/utils/archive_links.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/providers/blog_insights_provider.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/widgets/blog_card.dart';
import 'package:blog_app/features/blog/widgets/reading_history_card.dart';
import 'package:blog_app/features/blog/widgets/story_spotlight_card.dart';
import 'package:blog_app/theme/app_theme.dart';

enum _FeedLens { latest, trending, forYou, saved }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _FeedLens _selectedLens = _FeedLens.latest;

  void _openPost(BuildContext context, PostModel post) {
    context.push(
      ArchiveLinks.postPath(post.id),
      extra: post,
    );
  }

  void _openTopicSearch(BuildContext context, String topic) {
    context.push(ArchiveLinks.discoverPath(query: topic));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedState = ref.watch(blogFeedProvider);
    final publishedPosts = ref.watch(publishedPostsProvider);
    final trendingPosts = ref.watch(trendingPostsProvider);
    final recommendedPosts = ref.watch(recommendedPostsProvider);
    final bookmarkedPosts = ref.watch(bookmarkedPostsProvider);
    final featuredPost = ref.watch(featuredPostProvider);
    final topTopics = ref.watch(topTopicsProvider);
    final continueReading = ref.watch(continueReadingItemsProvider);

    final selectedPosts = switch (_selectedLens) {
      _FeedLens.latest => publishedPosts,
      _FeedLens.trending => trendingPosts,
      _FeedLens.forYou => recommendedPosts,
      _FeedLens.saved => bookmarkedPosts,
    };

    final visiblePosts = selectedPosts
        .where((post) =>
            _selectedLens == _FeedLens.saved || post.id != featuredPost?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inkwell'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: InkBackground(
        child: feedState.when(
          data: (_) {
            if (publishedPosts.isEmpty) {
              return _HomeEmptyState(
                onWrite: () => context.push('/create_post'),
              );
            }

            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () => ref.read(blogFeedProvider.notifier).fetchPosts(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: AppLayout.contentMaxWidth(context),
                        ),
                        child: Padding(
                          padding: AppLayout.pagePadding(context)
                              .copyWith(top: 8, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHero(
                                context,
                                publishedPosts: publishedPosts,
                                bookmarkedPosts: bookmarkedPosts,
                                continueReadingCount: continueReading.length,
                              ),
                              if (continueReading.isNotEmpty) ...[
                                SizedBox(height: AppLayout.sectionGap(context)),
                                const InkSectionHeader(
                                  eyebrow: 'Pick Up Where You Left Off',
                                  title: 'Continue reading',
                                  subtitle:
                                      'Return to stories already in motion without searching for them again.',
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 304,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: continueReading.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 14),
                                    itemBuilder: (context, index) {
                                      final item = continueReading[index];
                                      return ReadingHistoryCard(
                                        entry: item.historyEntry,
                                        onTap: () => _openPost(
                                          context,
                                          item.post,
                                        ),
                                        onRemove: () => ref
                                            .read(
                                                readingHistoryProvider.notifier)
                                            .removeEntry(item.post.id),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              SizedBox(height: AppLayout.sectionGap(context)),
                              InkSectionHeader(
                                eyebrow: 'Curate The Feed',
                                title: _sectionTitle(_selectedLens),
                                subtitle: _sectionSubtitle(
                                  _selectedLens,
                                  posts: selectedPosts,
                                ),
                              ),
                              if (featuredPost != null &&
                                  _selectedLens != _FeedLens.saved) ...[
                                SizedBox(height: AppLayout.panelGap(context)),
                                StorySpotlightCard(
                                  post: featuredPost,
                                  eyebrow: _selectedLens == _FeedLens.forYou
                                      ? 'Recommended for you'
                                      : 'Editor spotlight',
                                  onAuthorTap: () => context
                                      .push('/user/${featuredPost.userId}'),
                                  onTap: () => _openPost(
                                    context,
                                    featuredPost,
                                  ),
                                ),
                              ],
                              if (topTopics.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: topTopics
                                      .take(4)
                                      .map(
                                        (topic) => _TopicChip(
                                          label: topic.label,
                                          mentions: topic.mentions,
                                          onTap: () => _openTopicSearch(
                                            context,
                                            topic.label,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (visiblePosts.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _FeedEmptyState(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = visiblePosts[index];
                          return BlogCard(
                            post: post,
                            index: index,
                            onTap: () => _openPost(context, post),
                          );
                        },
                        childCount: visiblePosts.length,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: AppLayout.bottomNavigationClearance(context),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: InkPanel(
                radius: 30,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_tethering_error_rounded,
                      size: 72,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We could not refresh the feed.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again in a moment.\n$error',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(blogFeedProvider.notifier).fetchPosts(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: AppLayout.isExpanded(context)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/create_post'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Write'),
            ).animate().scale(delay: 320.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildHero(
    BuildContext context, {
    required List<PostModel> publishedPosts,
    required List<PostModel> bookmarkedPosts,
    required int continueReadingCount,
  }) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    final narrow = MediaQuery.sizeOf(context).width < 430;
    final colorScheme = Theme.of(context).colorScheme;

    return InkHeroCard(
      padding: EdgeInsets.all(compact ? 18 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push('/discover'),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: narrow ? 14 : 16,
                      vertical: narrow ? 12 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: narrow ? 10 : 12),
                        Expanded(
                          child: Text(
                            narrow
                                ? 'Search stories or topics'
                                : 'Search stories, writers, or topics',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: narrow ? 13 : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => context.push('/create_post'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.inkColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(narrow ? 50 : 56, narrow ? 50 : 56),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          SizedBox(height: compact ? 16 : 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _LensChip(
                  label: 'For you',
                  selected: _selectedLens == _FeedLens.forYou,
                  onTap: () => setState(() => _selectedLens = _FeedLens.forYou),
                ),
                _LensChip(
                  label: 'Latest',
                  selected: _selectedLens == _FeedLens.latest,
                  onTap: () => setState(() => _selectedLens = _FeedLens.latest),
                ),
                _LensChip(
                  label: 'Trending',
                  selected: _selectedLens == _FeedLens.trending,
                  onTap: () =>
                      setState(() => _selectedLens = _FeedLens.trending),
                ),
                _LensChip(
                  label: 'Saved',
                  selected: _selectedLens == _FeedLens.saved,
                  onTap: () => setState(() => _selectedLens = _FeedLens.saved),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 16 : 18),
          Text(
            'A calmer reading desk for your daily feed.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: compact ? 24 : 28,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Move between discovery, saved reads, and new writing without losing focus.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: compact ? 14 : 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              InkMetricPill(
                label: 'Stories',
                value: '${publishedPosts.length} stories',
                icon: Icons.description_outlined,
                inverted: true,
              ),
              InkMetricPill(
                label: 'Continue',
                value: '$continueReadingCount reads',
                icon: Icons.history_edu_rounded,
                inverted: true,
              ),
              if (!compact)
                InkMetricPill(
                  label: 'Saved',
                  value: '${bookmarkedPosts.length} stories',
                  icon: Icons.bookmark_rounded,
                  inverted: true,
                ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 420.ms).slideY(begin: 0.08);
  }

  String _sectionTitle(_FeedLens lens) {
    return switch (lens) {
      _FeedLens.latest => 'Latest stories',
      _FeedLens.trending => 'Trending now',
      _FeedLens.forYou => 'Picked for you',
      _FeedLens.saved => 'Saved stories',
    };
  }

  String _sectionSubtitle(_FeedLens lens, {required List<PostModel> posts}) {
    final count = posts.length;
    return switch (lens) {
      _FeedLens.latest => '$count stories sorted by newest first.',
      _FeedLens.trending => '$count stories getting the most attention.',
      _FeedLens.forYou => '$count stories matched to your reading habits.',
      _FeedLens.saved => '$count stories kept for later.',
    };
  }
}

class _LensChip extends StatelessWidget {
  const _LensChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: Colors.transparent),
        shape: const StadiumBorder(),
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              decoration: selected ? TextDecoration.underline : null,
              decorationColor: selected ? colorScheme.onSurface : null,
            ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.mentions,
    required this.onTap,
  });

  final String label;
  final int mentions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Text(
            '$label ($mentions)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: InkInfoBanner(
          icon: Icons.bookmark_border_rounded,
          title: 'Nothing in this collection yet',
          body:
              'Like or bookmark a few stories and this space will start feeling personal.',
          compact: true,
        ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({
    required this.onWrite,
  });

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppLayout.pagePadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: InkHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InkEyebrow(
                  label: 'Empty Studio',
                  icon: Icons.auto_stories_rounded,
                ),
                const SizedBox(height: 18),
                Text(
                  'No stories are published yet.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The redesigned dashboard is ready. Publish the first piece to start building discovery, reading history, and social momentum.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onWrite,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Write the first story'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
