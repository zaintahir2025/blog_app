import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/utils/app_error_mapper.dart';
import 'package:blog_app/core/utils/app_feedback.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/providers/blog_insights_provider.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';
import 'package:blog_app/features/social/models/friendship_model.dart';
import 'package:blog_app/features/social/providers/social_notifications_provider.dart';
import 'package:blog_app/features/social/providers/social_provider.dart';

class SocialHubScreen extends ConsumerWidget {
  const SocialHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Social')),
        body: InkBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeader =
                  constraints.maxHeight < 760 || constraints.maxWidth < 860;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppLayout.contentMaxWidth(context),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: AppLayout.pagePadding(context)
                            .copyWith(bottom: 12, top: 8),
                        child: Column(
                          children: [
                            _SocialHero(compact: compactHeader),
                            const SizedBox(height: 14),
                            InkPanel(
                              padding: const EdgeInsets.all(8),
                              radius: 24,
                              child: const TabBar(
                                tabs: [
                                  Tab(text: 'Messages'),
                                  Tab(text: 'Friends'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: TabBarView(
                          children: [
                            _MessagesTab(key: PageStorageKey('messages-tab')),
                            _FriendsTab(key: PageStorageKey('friends-tab')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SocialHero extends StatelessWidget {
  const _SocialHero({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkHeroCard(
      padding: EdgeInsets.all(compact ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InkEyebrow(
            label: 'Community',
            icon: Icons.groups_rounded,
          ),
          SizedBox(height: compact ? 12 : 18),
          Text(
            'Keep conversations, requests, and writer discovery in one place.',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: compact ? 24 : 34,
              height: compact ? 1.12 : 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            'Unread conversations, pending requests, and new connections stay easier to scan and act on.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: compact ? 1.45 : 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesTab extends ConsumerWidget {
  const _MessagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendAsync = ref.watch(socialBackendProvider);
    final threadsAsync = ref.watch(chatThreadsProvider);
    final notificationsAsync = ref.watch(socialNotificationsProvider);

    return backendAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (backend) {
        if (!backend.isConfigured) {
          return _SocialSetupView(message: backend.message ?? '');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(chatThreadsProvider);
            await ref.read(socialNotificationsProvider.notifier).refresh();
          },
          child: threadsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => ListView(
              padding: AppLayout.pagePadding(context),
              children: [Text('Could not load messages.\n$error')],
            ),
            data: (threads) {
              final unreadThreadIds =
                  notificationsAsync.valueOrNull?.unreadThreadUserIds ?? {};

              if (threads.isEmpty) {
                return ListView(
                  padding: AppLayout.pagePadding(context).copyWith(top: 0),
                  children: const [
                    SizedBox(height: 40),
                    _EmptySocialState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No conversations yet',
                      body:
                          'Open a writer profile and start the first message from there.',
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: AppLayout.pagePadding(context).copyWith(top: 0),
                itemCount: threads.length + (unreadThreadIds.isEmpty ? 0 : 1),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (unreadThreadIds.isNotEmpty && index == 0) {
                    return _NotificationSummaryCard(
                      icon: Icons.mark_chat_unread_outlined,
                      title: 'Unread messages',
                      body: unreadThreadIds.length == 1
                          ? 'You have 1 conversation waiting for a reply.'
                          : 'You have ${unreadThreadIds.length} conversations waiting for a reply.',
                    );
                  }

                  final thread =
                      threads[index - (unreadThreadIds.isEmpty ? 0 : 1)];
                  final isUnread =
                      unreadThreadIds.contains(thread.otherUser.id);

                  return InkPanel(
                    padding: const EdgeInsets.all(18),
                    radius: 26,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push('/chat/${thread.otherUser.id}'),
                      leading: ProfileAvatar(
                        userId: thread.otherUser.id,
                        fallbackLabel: _initial(thread.otherUser.displayName),
                        radius: 24,
                      ),
                      title: Text(
                        thread.otherUser.displayName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          thread.lastMessage.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _timeLabel(thread.lastMessage.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (isUnread) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendAsync = ref.watch(socialBackendProvider);
    final friendshipsAsync = ref.watch(friendshipsProvider);
    final notificationsAsync = ref.watch(socialNotificationsProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final suggestedProfiles = ref
        .watch(publishedPostsProvider)
        .where((post) => post.userId != currentUserId)
        .fold<Map<String, String>>({}, (map, post) {
      map.putIfAbsent(post.userId, () => post.authorName);
      return map;
    });

    return backendAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (backend) {
        if (!backend.isConfigured) {
          return _SocialSetupView(message: backend.message ?? '');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(friendshipsProvider);
            await ref.read(socialNotificationsProvider.notifier).refresh();
          },
          child: friendshipsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => ListView(
              padding: AppLayout.pagePadding(context),
              children: [Text('Could not load friendships.\n$error')],
            ),
            data: (friendships) {
              final friends = friendships
                  .where((item) => item.isFriendFor(currentUserId))
                  .toList();
              final incoming = friendships
                  .where((item) => item.isPendingFor(currentUserId))
                  .toList();
              final outgoing = friendships
                  .where((item) => item.isOutgoingFor(currentUserId))
                  .toList();
              final connectedIds = friendships
                  .map((item) => item.otherUser(currentUserId).id)
                  .toSet();

              return ListView(
                padding: AppLayout.pagePadding(context).copyWith(top: 0),
                children: [
                  if ((notificationsAsync.valueOrNull?.pendingRequestCount ??
                          0) >
                      0) ...[
                    _NotificationSummaryCard(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Friend requests waiting',
                      body: incoming.length == 1
                          ? 'You have 1 incoming friend request to review.'
                          : 'You have ${incoming.length} incoming friend requests to review.',
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (incoming.isNotEmpty) ...[
                    const InkSectionHeader(
                      eyebrow: 'Requests',
                      title: 'Friend requests',
                      subtitle: 'People waiting for your response.',
                    ),
                    const SizedBox(height: 12),
                    ...incoming.map(
                      (item) => _FriendRequestCard(friendship: item),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (friends.isNotEmpty) ...[
                    const InkSectionHeader(
                      eyebrow: 'Circle',
                      title: 'Friends',
                      subtitle: 'Your current writing network.',
                    ),
                    const SizedBox(height: 12),
                    ...friends.map(
                      (item) => _FriendCard(friendship: item),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (outgoing.isNotEmpty) ...[
                    const InkSectionHeader(
                      eyebrow: 'Pending',
                      title: 'Pending invites',
                      subtitle: 'Requests you have already sent.',
                    ),
                    const SizedBox(height: 12),
                    ...outgoing.map(
                      (item) => _FriendCard(friendship: item, pending: true),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const InkSectionHeader(
                    eyebrow: 'Discover',
                    title: 'Suggested writers',
                    subtitle:
                        'Browse authors from the feed and grow your network.',
                  ),
                  const SizedBox(height: 12),
                  if (suggestedProfiles.entries
                      .where((entry) => !connectedIds.contains(entry.key))
                      .isEmpty)
                    const _EmptySocialState(
                      icon: Icons.people_outline_rounded,
                      title: 'No new suggestions right now',
                      body:
                          'As more writers publish, they will show up here for you to connect with.',
                    )
                  else
                    ...suggestedProfiles.entries
                        .where((entry) => !connectedIds.contains(entry.key))
                        .take(8)
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkPanel(
                              padding: const EdgeInsets.all(16),
                              radius: 24,
                              child: ListTile(
                                onTap: () => context.push('/user/${entry.key}'),
                                contentPadding: EdgeInsets.zero,
                                leading: ProfileAvatar(
                                  userId: entry.key,
                                  fallbackLabel: _initial(entry.value),
                                  radius: 22,
                                ),
                                title: Text('@${entry.value}'),
                                subtitle: const Text('View profile'),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _FriendRequestCard extends ConsumerWidget {
  const _FriendRequestCard({required this.friendship});

  final FriendshipModel friendship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final otherUser = friendship.otherUser(currentUserId);
    final socialNotificationsNotifier =
        ref.read(socialNotificationsProvider.notifier);
    final socialRepository = ref.read(socialRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkPanel(
        padding: const EdgeInsets.all(16),
        radius: 24,
        child: Row(
          children: [
            ProfileAvatar(
              userId: otherUser.id,
              fallbackLabel: _initial(otherUser.displayName),
              radius: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text('@${otherUser.username}'),
                ],
              ),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await socialRepository.acceptFriendRequest(friendship.id);
                  if (!context.mounted) {
                    return;
                  }
                  ref.invalidate(friendshipsProvider);
                  ref.invalidate(friendshipWithUserProvider(otherUser.id));
                  await socialNotificationsNotifier.refresh();
                  AppFeedback.showSuccess(context, 'Friend request accepted.');
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
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                try {
                  await socialRepository.declineFriendRequest(friendship.id);
                  if (!context.mounted) {
                    return;
                  }
                  ref.invalidate(friendshipsProvider);
                  ref.invalidate(friendshipWithUserProvider(otherUser.id));
                  await socialNotificationsNotifier.refresh();
                  AppFeedback.showInfo(context, 'Friend request declined.');
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
              child: const Text('Decline'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends ConsumerWidget {
  const _FriendCard({
    required this.friendship,
    this.pending = false,
  });

  final FriendshipModel friendship;
  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final otherUser = friendship.otherUser(currentUserId);
    final colorScheme = Theme.of(context).colorScheme;
    final socialNotificationsNotifier =
        ref.read(socialNotificationsProvider.notifier);
    final socialRepository = ref.read(socialRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkPanel(
        padding: const EdgeInsets.all(16),
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push('/user/${otherUser.id}'),
              child: Row(
                children: [
                  ProfileAvatar(
                    userId: otherUser.id,
                    fallbackLabel: _initial(otherUser.displayName),
                    radius: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(pending
                            ? 'Request sent'
                            : '@${otherUser.username}'),
                      ],
                    ),
                  ),
                  Icon(
                    pending
                        ? Icons.schedule_send_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!pending)
                  FilledButton.tonalIcon(
                    onPressed: () => context.push('/chat/${otherUser.id}'),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Chat'),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final label = pending ? 'Cancel request' : 'Unfriend';
                    final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('$label?'),
                            content: Text(
                              pending
                                  ? 'This invite will be removed.'
                                  : 'You can always add this person again later.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Keep'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(label),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!context.mounted || !confirmed) {
                      return;
                    }

                    try {
                      await socialRepository.removeFriend(friendship.id);
                      if (!context.mounted) {
                        return;
                      }
                      ref.invalidate(friendshipsProvider);
                      ref.invalidate(friendshipWithUserProvider(otherUser.id));
                      ref.invalidate(publicFriendshipsProvider(otherUser.id));
                      await socialNotificationsNotifier.refresh();
                      AppFeedback.showInfo(
                        context,
                        pending
                            ? 'Friend request canceled.'
                            : 'Friend removed.',
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
                  icon: Icon(
                    pending
                        ? Icons.close_rounded
                        : Icons.person_remove_alt_1_rounded,
                  ),
                  label: Text(pending ? 'Cancel request' : 'Unfriend'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSummaryCard extends StatelessWidget {
  const _NotificationSummaryCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return InkInfoBanner(
      icon: icon,
      title: title,
      body: body,
    );
  }
}

class _SocialSetupView extends StatelessWidget {
  const _SocialSetupView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppLayout.pagePadding(context).copyWith(top: 0),
      children: [
        const SizedBox(height: 40),
        _EmptySocialState(
          icon: Icons.construction_rounded,
          title: 'Social backend not configured yet',
          body: message,
        ),
      ],
    );
  }
}

class _EmptySocialState extends StatelessWidget {
  const _EmptySocialState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkPanel(
        padding: const EdgeInsets.all(24),
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _timeLabel(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  if (difference.inMinutes < 1) {
    return 'now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}h';
  }
  return '${dateTime.month}/${dateTime.day}';
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}
