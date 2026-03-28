import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/providers/reading_history_provider.dart';
import 'package:blog_app/core/utils/archive_links.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/auth/providers/auth_provider.dart';
import 'package:blog_app/features/blog/providers/blog_insights_provider.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/utils/post_insights.dart';
import 'package:blog_app/features/blog/widgets/blog_card.dart';
import 'package:blog_app/features/blog/widgets/dashboard_metric_card.dart';
import 'package:blog_app/features/blog/widgets/reading_history_card.dart';
import 'package:blog_app/features/blog/widgets/story_spotlight_card.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';
import 'package:blog_app/features/social/providers/social_provider.dart';
import 'package:blog_app/features/social/widgets/friend_list_panel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _avatarCacheBuster;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _profileData = null;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id);

      final remoteProfile = response.isNotEmpty
          ? Map<String, dynamic>.from(response.first as Map)
          : null;

      if (!mounted) {
        return;
      }
      setState(() {
        _profileData = _resolvedProfileData(user, remoteProfile: remoteProfile);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profileData = _resolvedProfileData(user);
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text(
              'You will return to the login screen and can sign back in any time.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }

    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedState = ref.watch(blogFeedProvider);
    final myPosts = ref.watch(myPostsProvider);
    final bookmarkedPosts = ref.watch(bookmarkedPostsProvider);
    final dashboardStats = ref.watch(writerDashboardStatsProvider);
    final recentReading = ref.watch(recentReadingItemsProvider);
    final profileId = (_profileData?['id'] as String?) ?? '';
    final friendsAsync = ref.watch(publicFriendshipsProvider(profileId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: colorScheme.error,
            ),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: InkBackground(
        child: RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: () async {
            await _loadProfile();
            await ref.read(blogFeedProvider.notifier).fetchPosts();
            ref.invalidate(publicFriendshipsProvider(profileId));
          },
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                )
              : _profileData == null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppLayout.pagePadding(context),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Could not load profile.')),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: AppLayout.contentMaxWidth(context),
                          ),
                          child: Padding(
                            padding: AppLayout.pagePadding(context)
                                .copyWith(
                                  top: 10,
                                  bottom:
                                      AppLayout.bottomNavigationClearance(
                                    context,
                                  ),
                                ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHero(context, dashboardStats),
                                SizedBox(height: AppLayout.panelGap(context)),
                                _buildMetrics(context, dashboardStats, myPosts),
                                if (dashboardStats.topStory != null) ...[
                                  SizedBox(
                                      height: AppLayout.sectionGap(context)),
                                  StorySpotlightCard(
                                    post: dashboardStats.topStory!,
                                    eyebrow: 'Top performing story',
                                    onAuthorTap: () => context.push(
                                      '/user/${dashboardStats.topStory!.userId}',
                                    ),
                                    onTap: () => context.push(
                                      ArchiveLinks.postPath(
                                        dashboardStats.topStory!.id,
                                      ),
                                      extra: dashboardStats.topStory!,
                                    ),
                                  ),
                                ],
                                if (recentReading.isNotEmpty) ...[
                                  SizedBox(
                                      height: AppLayout.sectionGap(context)),
                                  const InkSectionHeader(
                                    eyebrow: 'Reader Flow',
                                    title: 'Reading activity',
                                    subtitle:
                                        'Resume stories and keep track of what has your attention lately.',
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 304,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: recentReading.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 14),
                                      itemBuilder: (context, index) {
                                        final item = recentReading[index];
                                        return ReadingHistoryCard(
                                          entry: item.historyEntry,
                                          onTap: () => context.push(
                                            ArchiveLinks.postPath(
                                              item.post.id,
                                            ),
                                            extra: item.post,
                                          ),
                                          onRemove: () => ref
                                              .read(readingHistoryProvider
                                                  .notifier)
                                              .removeEntry(item.post.id),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                friendsAsync.when(
                                  data: (friendships) {
                                    final friends = friendships
                                        .map((friendship) =>
                                            friendship.otherUser(profileId))
                                        .toList();

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: AppLayout.sectionGap(context),
                                      ),
                                      child: FriendListPanel(
                                        title: 'My network',
                                        subtitle: friends.isEmpty
                                            ? 'Build your circle by adding writers from their profiles.'
                                            : '${friends.length} writers are in your network right now.',
                                        emptyMessage:
                                            'You have not added any friends yet.',
                                        friends: friends,
                                        onFriendTap: (friend) =>
                                            context.push('/user/${friend.id}'),
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                                SizedBox(height: AppLayout.sectionGap(context)),
                                feedState.when(
                                  data: (_) {
                                    final publishedPosts = myPosts
                                        .where((p) => p.isPublished)
                                        .toList();
                                    final draftPosts = myPosts
                                        .where((p) => !p.isPublished)
                                        .toList();

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (publishedPosts.isNotEmpty) ...[
                                          const InkSectionHeader(
                                            eyebrow: 'Public Work',
                                            title: 'Published stories',
                                            subtitle:
                                                'What readers can discover right now.',
                                          ),
                                          const SizedBox(height: 16),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            itemCount: publishedPosts.length,
                                            itemBuilder: (context, index) =>
                                                BlogCard(
                                              post: publishedPosts[index],
                                              index: index,
                                              onTap: () => context.push(
                                                ArchiveLinks.postPath(
                                                  publishedPosts[index].id,
                                                ),
                                                extra: publishedPosts[index],
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (draftPosts.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          const InkSectionHeader(
                                            eyebrow: 'Private Work',
                                            title: 'Draft board',
                                            subtitle:
                                                'Private stories you are still shaping.',
                                          ),
                                          const SizedBox(height: 16),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            itemCount: draftPosts.length,
                                            itemBuilder: (context, index) =>
                                                BlogCard(
                                              post: draftPosts[index],
                                              index: index,
                                              onTap: () => context.push(
                                                ArchiveLinks.postPath(
                                                  draftPosts[index].id,
                                                ),
                                                extra: draftPosts[index],
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (bookmarkedPosts.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          const InkSectionHeader(
                                            eyebrow: 'Library',
                                            title: 'Saved bookmarks',
                                            subtitle:
                                                'Your personal reading list for later.',
                                          ),
                                          const SizedBox(height: 16),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            itemCount: bookmarkedPosts.length,
                                            itemBuilder: (context, index) =>
                                                BlogCard(
                                              post: bookmarkedPosts[index],
                                              index: index,
                                              onTap: () => context.push(
                                                ArchiveLinks.postPath(
                                                  bookmarkedPosts[index].id,
                                                ),
                                                extra: bookmarkedPosts[index],
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (publishedPosts.isEmpty &&
                                            draftPosts.isEmpty &&
                                            bookmarkedPosts.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 10),
                                            child: InkInfoBanner(
                                              icon: Icons.auto_stories_outlined,
                                              title: 'Nothing here yet',
                                              body:
                                                  'Publish your first story or save a few reads to make this space feel alive.',
                                              compact: true,
                                            ),
                                          ),
                                      ],
                                    ).animate().fade(delay: 240.ms);
                                  },
                                  loading: () => Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  error: (e, st) => Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Error: $e',
                                      style: const TextStyle(color: Colors.red),
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
      ),
    );
  }

  Widget _buildHero(BuildContext context, WriterDashboardStats dashboardStats) {
    final colorScheme = Theme.of(context).colorScheme;
    final fullName =
        (_profileData?['full_name'] as String?)?.trim().isNotEmpty == true
            ? _profileData!['full_name'] as String
            : 'Unknown';
    final username =
        (_profileData?['username'] as String?)?.trim().isNotEmpty == true
            ? _profileData!['username'] as String
            : 'writer';
    final userId = (_profileData?['id'] as String?) ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final stacked = constraints.maxWidth < 760;
        final heroLabelColor = colorScheme.onSurfaceVariant.withValues(
          alpha: colorScheme.brightness == Brightness.dark ? 0.92 : 1,
        );

        return InkHeroCard(
          padding: EdgeInsets.all(compact ? 22 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workspace',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: heroLabelColor,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 16),
              stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileIdentity(
                          userId: userId,
                          fullName: fullName,
                          username: username,
                          avatarCacheBuster: _avatarCacheBuster,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _buildHeroActions(context),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ProfileIdentity(
                            userId: userId,
                            fullName: fullName,
                            username: username,
                            avatarCacheBuster: _avatarCacheBuster,
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 360,
                          child: _buildHeroActions(context),
                        ),
                      ],
                    ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                'Manage your profile, published work, drafts, and reading queue from one clean workspace.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: heroLabelColor,
                    ),
              ),
              SizedBox(height: compact ? 14 : 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  InkMetricPill(
                    label: 'Streak',
                    value: dashboardStats.currentStreak > 0
                        ? '${dashboardStats.currentStreak} days'
                        : 'Start today',
                    icon: Icons.local_fire_department_rounded,
                    inverted: true,
                  ),
                  InkMetricPill(
                    label: 'Likes',
                    value: '${dashboardStats.totalLikes}',
                    icon: Icons.favorite_outline_rounded,
                    inverted: true,
                  ),
                  if (!compact)
                    InkMetricPill(
                      label: 'Words',
                      value: '${dashboardStats.totalWords}',
                      icon: Icons.notes_rounded,
                      inverted: true,
                    ),
                ],
              ),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.08);
      },
    );
  }

  Widget _buildHeroActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StudioActionTile(
          icon: Icons.edit_outlined,
          label: 'Edit profile',
          onTap: () async {
            final didUpdate = await context.push(
              '/edit_profile',
              extra: _profileData,
            );
            if (!mounted) {
              return;
            }
            if (didUpdate == true) {
              setState(() {
                _avatarCacheBuster =
                    DateTime.now().millisecondsSinceEpoch.toString();
              });
              await _loadProfile();
              if (!mounted) {
                return;
              }
              await ref.read(blogFeedProvider.notifier).fetchPosts();
            }
          },
        ),
        const SizedBox(height: 10),
        _StudioActionTile(
          icon: Icons.add_rounded,
          label: 'Add new article',
          onTap: () => context.push('/create_post'),
        ),
        const SizedBox(height: 10),
        _StudioActionTile(
          icon: Icons.tune_rounded,
          label: 'Settings',
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _buildMetrics(
    BuildContext context,
    WriterDashboardStats dashboardStats,
    List<dynamic> myPosts,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 680;
        final cardWidth =
            wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: AppLayout.panelGap(context),
          runSpacing: AppLayout.panelGap(context),
          children: [
            SizedBox(
              width: cardWidth,
              child: DashboardMetricCard(
                label: 'Published',
                value: dashboardStats.publishedCount.toString(),
                icon: Icons.public_rounded,
                accentColor: const Color(0xFF6366F1),
                subtitle: '${myPosts.length} total stories',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardMetricCard(
                label: 'Drafts',
                value: dashboardStats.draftCount.toString(),
                icon: Icons.inventory_2_outlined,
                accentColor: Colors.deepOrange,
                subtitle: 'Private works in progress',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardMetricCard(
                label: 'Saved',
                value: dashboardStats.savedCount.toString(),
                icon: Icons.bookmark_rounded,
                accentColor: Colors.teal,
                subtitle: 'Stories you want to revisit',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardMetricCard(
                label: 'Total likes',
                value: dashboardStats.totalLikes.toString(),
                icon: Icons.favorite_rounded,
                accentColor: Colors.pinkAccent,
                subtitle: '${dashboardStats.totalWords} words written',
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _resolvedProfileData(
    User user, {
    Map<String, dynamic>? remoteProfile,
  }) {
    final email = user.email ?? '';
    final emailPrefix = email.contains('@') ? email.split('@').first : email;
    final metadata = user.userMetadata ?? {};

    final fullName =
        (remoteProfile?['full_name'] as String?)?.trim().isNotEmpty == true
            ? remoteProfile!['full_name'] as String
            : ((metadata['full_name'] as String?)?.trim().isNotEmpty == true
                ? metadata['full_name'] as String
                : (emailPrefix.isNotEmpty ? emailPrefix : 'Unknown User'));

    final username =
        (remoteProfile?['username'] as String?)?.trim().isNotEmpty == true
            ? remoteProfile!['username'] as String
            : ((metadata['username'] as String?)?.trim().isNotEmpty == true
                ? metadata['username'] as String
                : (emailPrefix.isNotEmpty
                    ? emailPrefix.toLowerCase()
                    : 'writer'));

    return {
      'id': user.id,
      'full_name': fullName,
      'username': username,
    };
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.userId,
    required this.fullName,
    required this.username,
    this.avatarCacheBuster,
  });

  final String userId;
  final String fullName;
  final String username;
  final String? avatarCacheBuster;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outline,
              width: 2,
            ),
          ),
          child: ProfileAvatar(
            userId: userId,
            fallbackLabel: _safeInitial(fullName),
            radius: 34,
            cacheBuster: avatarCacheBuster,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 38,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '@$username',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudioActionTile extends StatelessWidget {
  const _StudioActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : colorScheme.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : colorScheme.outlineVariant.withValues(alpha: 0.92),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
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
