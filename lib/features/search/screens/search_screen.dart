import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:blog_app/core/providers/reading_history_provider.dart';
import 'package:blog_app/core/utils/archive_links.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/providers/blog_insights_provider.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/utils/post_insights.dart';
import 'package:blog_app/features/blog/widgets/blog_card.dart';
import 'package:blog_app/features/blog/widgets/reading_history_card.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';
import 'package:blog_app/theme/app_theme.dart';

enum _SearchScope { all, title, author, content }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery,
  });

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _recentSearchLimit = 8;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  final Map<String, String> _normalizedContentCache = {};
  final Map<String, String> _contentSourceCache = {};
  String _searchQuery = '';
  _SearchScope _scope = _SearchScope.all;
  bool _savedOnly = false;
  bool _coverOnly = false;
  List<String> _recentSearches = const [];

  static Box<dynamic> get _settingsBox => Hive.box<dynamic>('settings_box');

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_handleSearchControllerChanged);
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _applyInitialQuery();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_handleSearchControllerChanged);
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSearchFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      _storeCurrentSearch();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _loadRecentSearches() {
    final stored = _settingsBox.get(_recentSearchesKey);
    final items = (stored is List)
        ? stored
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList()
        : <String>[];

    setState(() => _recentSearches = items);
  }

  void _applyInitialQuery() {
    final initialQuery = widget.initialQuery?.trim() ?? '';
    if (initialQuery.isEmpty) {
      return;
    }

    _searchController.value = TextEditingValue(
      text: initialQuery,
      selection: TextSelection.collapsed(offset: initialQuery.length),
    );
    _searchQuery = initialQuery.toLowerCase();
  }

  Future<void> _saveRecentSearch(String value) async {
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return;
    }

    final updated = [
      trimmed,
      ..._recentSearches.where(
        (item) => item.toLowerCase() != trimmed.toLowerCase(),
      ),
    ].take(_recentSearchLimit).toList();

    setState(() => _recentSearches = updated);
    await _settingsBox.put(_recentSearchesKey, updated);
  }

  Future<void> _removeRecentSearch(String value) async {
    final updated = _recentSearches
        .where((item) => item.toLowerCase() != value.toLowerCase())
        .toList();
    setState(() => _recentSearches = updated);
    await _settingsBox.put(_recentSearchesKey, updated);
  }

  Future<void> _clearRecentSearches() async {
    setState(() => _recentSearches = const []);
    await _settingsBox.put(_recentSearchesKey, const <String>[]);
  }

  void _storeCurrentSearch() {
    final currentValue = _searchController.text.trim();
    if (currentValue.length < 2) {
      return;
    }
    unawaited(_saveRecentSearch(currentValue));
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) {
        return;
      }
      final normalized = value.trim().toLowerCase();
      if (normalized == _searchQuery) {
        return;
      }
      setState(() => _searchQuery = normalized);
    });
  }

  void _applySearch(
    String value, {
    _SearchScope? scope,
    bool persist = true,
    bool unfocus = false,
  }) {
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {
      _searchQuery = trimmed.toLowerCase();
      if (scope != null) {
        _scope = scope;
      }
    });

    if (persist && trimmed.length >= 2) {
      unawaited(_saveRecentSearch(trimmed));
    }

    if (unfocus) {
      _searchFocusNode.unfocus();
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _openPost(BuildContext context, PostModel post) {
    context.push(
      ArchiveLinks.postPath(post.id),
      extra: post,
    );
  }

  List<String> _visibleRecentSearches() {
    final query = _searchController.text.trim().toLowerCase();
    return _recentSearches.where((item) {
      if (query.isEmpty) {
        return true;
      }
      return item.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedState = ref.watch(blogFeedProvider);
    final publishedPosts = ref.watch(publishedPostsProvider);
    final topTopics = ref.watch(topTopicsProvider);
    final topAuthors = ref.watch(topAuthorsProvider);
    final bookmarkedPosts = ref.watch(bookmarkedPostsProvider);
    final recentReading = ref.watch(recentReadingItemsProvider);
    final searchResults = _filterPosts(publishedPosts);
    final recentSearches = _visibleRecentSearches();
    final showRecentSearches = _searchFocusNode.hasFocus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
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
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth(context),
                ),
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: AppLayout.pagePadding(context)
                          .copyWith(top: 8, bottom: 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBrowserSearchHero(
                              context,
                              recentSearches: recentSearches,
                              showRecentSearches: showRecentSearches,
                            ),
                            const SizedBox(height: 18),
                            _buildSearchControls(context),
                          ],
                        ),
                      ),
                    ),
                    if (_searchQuery.trim().isEmpty)
                      SliverPadding(
                        padding: AppLayout.pagePadding(context)
                            .copyWith(
                              top: 22,
                              bottom:
                                  AppLayout.bottomNavigationClearance(context),
                            ),
                        sliver: SliverToBoxAdapter(
                          child: _buildDiscoveryBody(
                            context,
                            recentReading: recentReading,
                            topTopics: topTopics,
                            topAuthors: topAuthors,
                            bookmarkedPosts: bookmarkedPosts,
                          ),
                        ),
                      )
                    else if (searchResults.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: AppLayout.pagePadding(context)
                              .copyWith(top: 26, bottom: 96),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: InkInfoBanner(
                                icon: Icons.search_off_rounded,
                                title: 'No stories found',
                                body:
                                    'Try another phrase, widen your scope, or turn off some filters.',
                                compact: true,
                              ),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: AppLayout.pagePadding(context)
                            .copyWith(top: 22, bottom: 12),
                        sliver: SliverToBoxAdapter(
                          child: InkInfoBanner(
                            icon: Icons.manage_search_rounded,
                            title: '${searchResults.length} results',
                            body:
                                'Showing matches for "${_searchController.text.trim()}".',
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = searchResults[index];
                            return BlogCard(
                              post: post,
                              index: index,
                              onTap: () {
                                _storeCurrentSearch();
                                _openPost(context, post);
                              },
                            );
                          },
                          childCount: searchResults.length,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: AppLayout.bottomNavigationClearance(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error: $error',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrowserSearchHero(
    BuildContext context, {
    required List<String> recentSearches,
    required bool showRecentSearches,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final mobileCompact = MediaQuery.sizeOf(context).width < 640;

    return InkHeroCard(
      padding: EdgeInsets.all(mobileCompact ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InkEyebrow(
            label: 'Discover',
            icon: Icons.travel_explore_rounded,
          ),
          SizedBox(height: mobileCompact ? 12 : 16),
          Text(
            'Search the archive with clarity.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: mobileCompact
                      ? 24
                      : compact
                          ? 28
                          : 32,
                ),
          ),
          SizedBox(height: mobileCompact ? 8 : 10),
          Text(
            'Search titles, authors, and story content without losing your recent queries.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          SizedBox(height: mobileCompact ? 16 : 20),
          _buildAddressBar(context),
          if (showRecentSearches) ...[
            SizedBox(height: mobileCompact ? 12 : 16),
            _buildRecentSearchesPanel(
              context,
              recentSearches: recentSearches,
            ),
          ],
        ],
      ),
    ).animate().fade(duration: 420.ms).slideY(begin: -0.06);
  }

  Widget _buildAddressBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mobileCompact = MediaQuery.sizeOf(context).width < 620;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobileCompact ? 14 : 16,
        vertical: mobileCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onSubmitted: (value) =>
                  _applySearch(value, persist: true, unfocus: true),
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
              decoration: InputDecoration(
                hintText: 'Search titles, authors, or ideas...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Clear search',
              onPressed: _clearSearch,
              icon: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentSearchesPanel(
    BuildContext context, {
    required List<String> recentSearches,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final panel = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recent searches',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (_recentSearches.isNotEmpty)
                  TextButton(
                    onPressed: _clearRecentSearches,
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant,
          ),
          if (recentSearches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Searches you run here will appear as quick jump-backs.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
            )
          else
            ...recentSearches.map(
              (item) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _applySearch(
                    item,
                    persist: true,
                    unfocus: true,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove from history',
                          onPressed: () => _removeRecentSearch(item),
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return panel.animate().fade(duration: 180.ms).slideY(begin: -0.04);
  }

  Widget _buildSearchControls(BuildContext context) {
    return InkPanel(
      padding: const EdgeInsets.all(18),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InkSectionHeader(
            eyebrow: 'Filters',
            title: 'Refine results',
            subtitle: 'Narrow the archive when you need precision.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _ScopeChip(
                  label: 'All',
                  selected: _scope == _SearchScope.all,
                  onTap: () => setState(() => _scope = _SearchScope.all),
                ),
                _ScopeChip(
                  label: 'Titles',
                  selected: _scope == _SearchScope.title,
                  onTap: () => setState(() => _scope = _SearchScope.title),
                ),
                _ScopeChip(
                  label: 'Authors',
                  selected: _scope == _SearchScope.author,
                  onTap: () => setState(() => _scope = _SearchScope.author),
                ),
                _ScopeChip(
                  label: 'Content',
                  selected: _scope == _SearchScope.content,
                  onTap: () => setState(() => _scope = _SearchScope.content),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilterChip(
                label: const Text('Saved only'),
                selected: _savedOnly,
                onSelected: (value) => setState(() => _savedOnly = value),
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.14),
              ),
              FilterChip(
                label: const Text('With cover'),
                selected: _coverOnly,
                onSelected: (value) => setState(() => _coverOnly = value),
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryBody(
    BuildContext context, {
    required List<dynamic> recentReading,
    required List<dynamic> topTopics,
    required List<dynamic> topAuthors,
    required List<PostModel> bookmarkedPosts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recentReading.isNotEmpty) ...[
          const InkSectionHeader(
            eyebrow: 'Resume',
            title: 'Recently opened stories',
            subtitle: 'Jump back into stories already in progress.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 304,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentReading.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = recentReading[index];
                return ReadingHistoryCard(
                  entry: item.historyEntry,
                  onTap: () => _openPost(context, item.post),
                  onRemove: () => ref
                      .read(readingHistoryProvider.notifier)
                      .removeEntry(item.post.id),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],
        const InkSectionHeader(
          eyebrow: 'Topics',
          title: 'Trending topics',
          subtitle: 'Start with what readers are talking about.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: topTopics
              .map(
                (topic) => ActionChip(
                  label: Text('${topic.label} (${topic.mentions})'),
                  onPressed: () => _applySearch(
                    topic.label,
                    persist: true,
                    unfocus: true,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 28),
        const InkSectionHeader(
          eyebrow: 'Writers',
          title: 'Popular writers',
          subtitle: 'Search by creator when you already know the voice.',
        ),
        const SizedBox(height: 12),
        ...topAuthors.map(
          (author) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkPanel(
              padding: const EdgeInsets.all(16),
              radius: 24,
              child: ListTile(
                onTap: () => context.push('/user/${author.userId}'),
                contentPadding: EdgeInsets.zero,
                leading: ProfileAvatar(
                  userId: author.userId,
                  fallbackLabel: _initial(author.name),
                  radius: 22,
                ),
                title: Text(
                  '@${author.name}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${author.storyCount} stories | ${author.totalLikes} likes',
                ),
                trailing: IconButton(
                  tooltip: 'Search this writer',
                  onPressed: () => _applySearch(
                    author.name,
                    scope: _SearchScope.author,
                    persist: true,
                    unfocus: true,
                  ),
                  icon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (bookmarkedPosts.isNotEmpty) ...[
          const SizedBox(height: 16),
          const InkSectionHeader(
            eyebrow: 'Saved',
            title: 'Bookmarked stories',
            subtitle: 'Quick return points for stories you want to revisit.',
          ),
          const SizedBox(height: 12),
          ...bookmarkedPosts.take(3).map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkPanel(
                    padding: const EdgeInsets.all(16),
                    radius: 24,
                    child: ListTile(
                      onTap: () => _openPost(context, post),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      subtitle: Text('@${post.authorName}'),
                      trailing: const Icon(
                        Icons.bookmark_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  List<PostModel> _filterPosts(List<PostModel> posts) {
    final query = _searchQuery.trim().toLowerCase();
    final hits = <_SearchHit>[];

    for (final post in posts) {
      if (_savedOnly && !post.isBookmarkedByMe) {
        continue;
      }
      if (_coverOnly && post.coverImageUrl == null) {
        continue;
      }

      final score = query.isEmpty ? 0.0 : _score(post, query);
      if (query.isEmpty || score > 0) {
        hits.add(_SearchHit(post: post, score: score));
      }
    }

    hits.sort((first, second) {
      final byScore = second.score.compareTo(first.score);
      if (byScore != 0) {
        return byScore;
      }
      return second.post.createdAt.compareTo(first.post.createdAt);
    });

    return hits.map((hit) => hit.post).toList();
  }

  double _score(PostModel post, String query) {
    final title = post.title.toLowerCase();
    final author = post.authorName.toLowerCase();
    final content = _normalizedContent(post);
    var score = 0.0;

    if (_scope == _SearchScope.all || _scope == _SearchScope.title) {
      if (title.contains(query)) {
        score += title.startsWith(query) ? 9 : 6;
      }
    }
    if (_scope == _SearchScope.all || _scope == _SearchScope.author) {
      if (author.contains(query)) {
        score += author.startsWith(query) ? 8 : 5;
      }
    }
    if (_scope == _SearchScope.all || _scope == _SearchScope.content) {
      if (content.contains(query)) {
        score += 4;
      }
    }

    score += post.likesCount * 0.08;
    return score;
  }

  String _normalizedContent(PostModel post) {
    final cachedSource = _contentSourceCache[post.id];
    if (cachedSource != post.content ||
        !_normalizedContentCache.containsKey(post.id)) {
      _contentSourceCache[post.id] = post.content;
      _normalizedContentCache[post.id] =
          PostInsights.plainText(post.content).toLowerCase();
    }

    return _normalizedContentCache[post.id]!;
  }
}

class _SearchHit {
  const _SearchHit({
    required this.post,
    required this.score,
  });

  final PostModel post;
  final double score;
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.16),
        side: BorderSide.none,
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? AppTheme.primaryColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
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
