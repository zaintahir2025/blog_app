import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/utils/archive_links.dart';
import 'package:blog_app/core/utils/app_error_mapper.dart';
import 'package:blog_app/core/utils/app_feedback.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/providers/blog_insights_provider.dart';
import 'package:blog_app/features/blog/widgets/blog_card.dart';
import 'package:blog_app/features/profile/models/user_profile_model.dart';
import 'package:blog_app/features/profile/providers/profile_provider.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';
import 'package:blog_app/features/social/models/friendship_model.dart';
import 'package:blog_app/features/social/providers/social_notifications_provider.dart';
import 'package:blog_app/features/social/providers/social_provider.dart';
import 'package:blog_app/features/social/widgets/friend_list_panel.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final socialBackendAsync = ref.watch(socialBackendProvider);
    final friendshipAsync = ref.watch(friendshipWithUserProvider(userId));
    final publicFriendsAsync = ref.watch(publicFriendshipsProvider(userId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final userPosts = ref
        .watch(publishedPostsProvider)
        .where((post) => post.userId == userId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Writer Profile')),
      body: InkBackground(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load this profile.\n$error'),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('This user could not be found.'));
            }

            final isMe = currentUserId == profile.id;
            final totalLikes =
                userPosts.fold<int>(0, (sum, post) => sum + post.likesCount);
            final publicFriends = publicFriendsAsync.valueOrNull
                    ?.map((friendship) => friendship.otherUser(userId))
                    .toList() ??
                const [];

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: AppLayout.contentMaxWidth(context)),
                child: ListView(
                  padding: AppLayout.pagePadding(context),
                  children: [
                    InkHeroCard(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 760;

                          return stacked
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const InkEyebrow(label: 'Public Portfolio'),
                                    const SizedBox(height: 18),
                                    _ProfileHeader(profile: profile),
                                    const SizedBox(height: 20),
                                    _ProfileStats(
                                      publishedCount: userPosts.length,
                                      totalLikes: totalLikes,
                                      friendCount: publicFriends.length,
                                    ),
                                    const SizedBox(height: 20),
                                    _ProfileActions(
                                      profileId: profile.id,
                                      isMe: isMe,
                                      socialBackendAsync: socialBackendAsync,
                                      friendshipAsync: friendshipAsync,
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const InkEyebrow(
                                              label: 'Public Portfolio'),
                                          const SizedBox(height: 18),
                                          _ProfileHeader(profile: profile),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    SizedBox(
                                      width: 360,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _ProfileStats(
                                            publishedCount: userPosts.length,
                                            totalLikes: totalLikes,
                                            friendCount: publicFriends.length,
                                          ),
                                          const SizedBox(height: 16),
                                          _ProfileActions(
                                            profileId: profile.id,
                                            isMe: isMe,
                                            socialBackendAsync:
                                                socialBackendAsync,
                                            friendshipAsync: friendshipAsync,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                    ),
                    if (!isMe)
                      socialBackendAsync.when(
                        data: (backend) => backend.isConfigured
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: _SocialSetupCard(
                                  message: backend.message ??
                                      'Social features are not configured yet.',
                                ),
                              ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    const SizedBox(height: 24),
                    publicFriendsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (friendships) {
                        final friends = friendships
                            .map((friendship) => friendship.otherUser(userId))
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: FriendListPanel(
                            title: 'Friends',
                            subtitle: friends.isEmpty
                                ? '@${profile.username} has not connected with other writers yet.'
                                : '${friends.length} writers connected with @${profile.username}.',
                            emptyMessage:
                                'This writer has not added friends yet.',
                            friends: friends,
                            onFriendTap: (friend) =>
                                context.push('/user/${friend.id}'),
                          ),
                        );
                      },
                    ),
                    _SectionTitle(
                      title: 'Published stories',
                      subtitle: userPosts.isEmpty
                          ? 'No public stories yet.'
                          : '${userPosts.length} stories by @${profile.username}.',
                    ),
                    const SizedBox(height: 16),
                    if (userPosts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('Nothing public here yet.'),
                        ),
                      )
                    else
                      ...userPosts.asMap().entries.map(
                            (entry) => BlogCard(
                              post: entry.value,
                              index: entry.key,
                              onTap: () => context.push(
                                ArchiveLinks.postPath(entry.value.id),
                                extra: entry.value,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatar(
          userId: profile.id,
          fallbackLabel: _initial(profile.displayName),
          radius: 38,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '@${profile.username}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A public author page for discovering stories, starting conversations, and building a network around strong writing.',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({
    required this.publishedCount,
    required this.totalLikes,
    required this.friendCount,
  });

  final int publishedCount;
  final int totalLikes;
  final int friendCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatPill(label: '$publishedCount stories'),
        _StatPill(label: '$totalLikes likes'),
        _StatPill(label: '$friendCount friends'),
      ],
    );
  }
}

class _ProfileActions extends ConsumerWidget {
  const _ProfileActions({
    required this.profileId,
    required this.isMe,
    required this.socialBackendAsync,
    required this.friendshipAsync,
  });

  final String profileId;
  final bool isMe;
  final AsyncValue<SocialBackendStatus> socialBackendAsync;
  final AsyncValue<FriendshipModel?> friendshipAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialNotificationsNotifier =
        ref.read(socialNotificationsProvider.notifier);
    final socialRepository = ref.read(socialRepositoryProvider);

    if (isMe) {
      return FilledButton.icon(
        onPressed: () async {
          final profileData =
              await ref.read(currentUserProfileDataProvider.future);
          if (!context.mounted || profileData == null) {
            return;
          }
          await context.push('/edit_profile', extra: profileData);
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit profile'),
      );
    }

    return socialBackendAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (backend) {
        if (!backend.isConfigured) {
          return OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.group_off_outlined),
            label: const Text('Social setup required'),
          );
        }

        return friendshipAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text(
            'Social features are unavailable right now.\n$error',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          data: (friendship) {
            final currentUserId =
                Supabase.instance.client.auth.currentUser?.id ?? '';
            final isIncoming = friendship?.isPendingFor(currentUserId) ?? false;
            final isFriends = friendship?.isFriendFor(currentUserId) ?? false;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (friendship == null)
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await socialRepository.sendFriendRequest(profileId);
                        if (!context.mounted) {
                          return;
                        }
                        ref.invalidate(friendshipWithUserProvider(profileId));
                        ref.invalidate(friendshipsProvider);
                        await socialNotificationsNotifier.refresh();
                        AppFeedback.showSuccess(
                          context,
                          'Friend request sent.',
                        );
                      } catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        AppFeedback.showError(
                          context,
                          AppErrorMapper.readable(error),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add friend'),
                  )
                else if (isIncoming) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await socialRepository
                            .acceptFriendRequest(friendship.id);
                        if (!context.mounted) {
                          return;
                        }
                        ref.invalidate(friendshipWithUserProvider(profileId));
                        ref.invalidate(friendshipsProvider);
                        ref.invalidate(publicFriendshipsProvider(profileId));
                        await socialNotificationsNotifier.refresh();
                        AppFeedback.showSuccess(
                          context,
                          'Friend request accepted.',
                        );
                      } catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        AppFeedback.showError(
                          context,
                          AppErrorMapper.readable(error),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Accept'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await socialRepository
                            .declineFriendRequest(friendship.id);
                        if (!context.mounted) {
                          return;
                        }
                        ref.invalidate(friendshipWithUserProvider(profileId));
                        ref.invalidate(friendshipsProvider);
                        await socialNotificationsNotifier.refresh();
                        AppFeedback.showInfo(
                          context,
                          'Friend request declined.',
                        );
                      } catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        AppFeedback.showError(
                          context,
                          AppErrorMapper.readable(error),
                        );
                      }
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ] else if (isFriends)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Unfriend this writer?'),
                              content: const Text(
                                'You can always reconnect later if you want to.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Keep friend'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Unfriend'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (!context.mounted) {
                        return;
                      }

                      if (!confirmed) {
                        return;
                      }

                      try {
                        await socialRepository.removeFriend(friendship.id);
                        if (!context.mounted) {
                          return;
                        }
                        ref.invalidate(friendshipWithUserProvider(profileId));
                        ref.invalidate(friendshipsProvider);
                        ref.invalidate(publicFriendshipsProvider(profileId));
                        await socialNotificationsNotifier.refresh();
                        AppFeedback.showInfo(context, 'Friend removed.');
                      } catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        AppFeedback.showError(
                          context,
                          AppErrorMapper.readable(error),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_remove_alt_1_rounded),
                    label: const Text('Unfriend'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await socialRepository
                            .declineFriendRequest(friendship.id);
                        if (!context.mounted) {
                          return;
                        }
                        ref.invalidate(friendshipWithUserProvider(profileId));
                        ref.invalidate(friendshipsProvider);
                        await socialNotificationsNotifier.refresh();
                        AppFeedback.showInfo(
                          context,
                          'Friend request canceled.',
                        );
                      } catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        AppFeedback.showError(
                          context,
                          AppErrorMapper.readable(error),
                        );
                      }
                    },
                    icon: const Icon(Icons.schedule_send_rounded),
                    label: const Text('Cancel request'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/chat/$profileId'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SocialSetupCard extends StatelessWidget {
  const _SocialSetupCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
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
