import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:blog_app/core/providers/app_preferences_provider.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/home/screens/home_screen.dart';
import 'package:blog_app/features/profile/screens/profile_screen.dart';
import 'package:blog_app/features/search/screens/search_screen.dart';
import 'package:blog_app/features/social/providers/social_notifications_provider.dart';
import 'package:blog_app/features/social/screens/social_hub_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    SocialHubScreen(),
    ProfileScreen(),
  ];

  final List<
          (String label, String subtitle, IconData icon, IconData activeIcon)>
      _destinations = const [
    ('Feed', 'Latest writing', Icons.home_outlined, Icons.home_rounded),
    (
      'Discover',
      'Search stories',
      Icons.travel_explore_outlined,
      Icons.travel_explore_rounded,
    ),
    (
      'Social',
      'Messages and friends',
      Icons.forum_outlined,
      Icons.forum_rounded
    ),
    (
      'Profile',
      'Your studio',
      Icons.person_outline_rounded,
      Icons.person_rounded
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final expanded = AppLayout.isExpanded(context);
    final preferences = ref.watch(appPreferencesProvider);
    final socialNotificationsAsync = ref.watch(socialNotificationsProvider);
    final socialBadgeCount = socialNotificationsAsync.value?.totalCount ?? 0;

    ref.listen<AsyncValue<SocialNotificationSnapshot>>(
      socialNotificationsProvider,
      (previous, next) {
        final previousSnapshot = previous?.value;
        final nextSnapshot = next.value;
        if (!mounted ||
            nextSnapshot == null ||
            previousSnapshot == null ||
            _currentIndex == 2) {
          return;
        }

        final newRequestIds = nextSnapshot.pendingRequestIds
            .difference(previousSnapshot.pendingRequestIds);
        final newThreadIds = nextSnapshot.unreadThreadUserIds
            .difference(previousSnapshot.unreadThreadUserIds);

        if (newRequestIds.isEmpty && newThreadIds.isEmpty) {
          return;
        }

        final message = _notificationMessage(
          nextSnapshot,
          newRequestIds: newRequestIds,
          newThreadIds: newThreadIds,
        );
        if (message == null || message.isEmpty) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => setState(() => _currentIndex = 2),
              ),
            ),
          );
      },
    );

    if (!expanded) {
      return Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: InkPanel(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            radius: 24,
            child: NavigationBar(
              height: 68,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              destinations: List.generate(
                _destinations.length,
                (index) => NavigationDestination(
                  icon: _destinationIcon(
                    index: index,
                    selected: false,
                    socialBadgeCount: socialBadgeCount,
                  ),
                  selectedIcon: _destinationIcon(
                    index: index,
                    selected: true,
                    socialBadgeCount: socialBadgeCount,
                  ),
                  label: _destinations[index].$1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final extendedRail = AppLayout.isLargeDesktop(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: extendedRail ? 248 : 96,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: SafeArea(
              child: InkPanel(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                radius: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: extendedRail ? 8 : 0,
                        vertical: 4,
                      ),
                      child: extendedRail
                          ? const _RailBrandExpanded()
                          : const _RailBrandCompact(),
                    ),
                    const SizedBox(height: 16),
                    extendedRail
                        ? FilledButton.icon(
                            onPressed: () => context.push('/create_post'),
                            icon: const Icon(Icons.edit_square),
                            label: const Text('Write'),
                          )
                        : Tooltip(
                            message: 'Write',
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => context.push('/create_post'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Icon(
                                  Icons.edit_square,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    ...List.generate(
                      _destinations.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DesktopDestination(
                          label: _destinations[index].$1,
                          subtitle: _destinations[index].$2,
                          icon: _destinations[index].$3,
                          activeIcon: _destinations[index].$4,
                          extended: extendedRail,
                          selected: _currentIndex == index,
                          badgeCount: index == 2 ? socialBadgeCount : 0,
                          onTap: () => setState(() => _currentIndex = index),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (extendedRail)
                      Text(
                        switch (preferences.themeMode) {
                          ThemeMode.light => 'Light theme',
                          ThemeMode.dark => 'Dark theme',
                          ThemeMode.system => 'System theme',
                        },
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 10),
                    extendedRail
                        ? OutlinedButton.icon(
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Icons.tune_rounded),
                            label: const Text('Settings'),
                          )
                        : Center(
                            child: IconButton(
                              tooltip: 'Settings',
                              onPressed: () => context.push('/settings'),
                              icon: Icon(
                                Icons.tune_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _destinationIcon({
    required int index,
    required bool selected,
    required int socialBadgeCount,
  }) {
    final destination = _destinations[index];
    final icon = Icon(selected ? destination.$4 : destination.$3);
    if (index != 2 || socialBadgeCount <= 0) {
      return icon;
    }
    return _NavigationBadge(
      count: socialBadgeCount,
      child: icon,
    );
  }

  String? _notificationMessage(
    SocialNotificationSnapshot snapshot, {
    required Set<String> newRequestIds,
    required Set<String> newThreadIds,
  }) {
    if (newRequestIds.isNotEmpty && newThreadIds.isNotEmpty) {
      return '${newRequestIds.length} new friend ${newRequestIds.length == 1 ? 'request' : 'requests'} and ${newThreadIds.length} unread ${newThreadIds.length == 1 ? 'message' : 'messages'}.';
    }

    if (newRequestIds.isNotEmpty) {
      if (newRequestIds.length == 1) {
        final request = snapshot.requestById(newRequestIds.first);
        final name = request?.requester.displayName ?? 'a writer';
        return 'New friend request from $name.';
      }
      return '${newRequestIds.length} new friend requests.';
    }

    if (newThreadIds.isNotEmpty) {
      if (newThreadIds.length == 1) {
        final thread = snapshot.threadByUserId(newThreadIds.first);
        final name = thread?.otherUser.displayName ?? 'a writer';
        return 'New message from $name.';
      }
      return '${newThreadIds.length} unread conversations need your attention.';
    }

    return null;
  }
}

class _RailBrandExpanded extends StatelessWidget {
  const _RailBrandExpanded();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inkwell',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Reading and writing',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RailBrandCompact extends StatelessWidget {
  const _RailBrandCompact();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.auto_stories_rounded,
        color: colorScheme.primary,
        size: 24,
      ),
    );
  }
}

class _DesktopDestination extends StatelessWidget {
  const _DesktopDestination({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
    required this.extended,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;
  final bool extended;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compactDestination = !extended;
    final iconWidget = _NavigationBadge(
      count: badgeCount,
      hidden: badgeCount <= 0,
      child: Icon(
        selected ? activeIcon : icon,
        size: compactDestination ? 20 : 24,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: extended ? 16 : 8,
            vertical: extended ? 16 : 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
          ),
          child: compactDestination
              ? Center(child: iconWidget)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    iconWidget,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: selected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }
}

class _NavigationBadge extends StatelessWidget {
  const _NavigationBadge({
    required this.count,
    required this.child,
    this.hidden = false,
  });

  final int count;
  final Widget child;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return child;
    }

    final label = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(999),
            ),
            constraints: const BoxConstraints(minWidth: 18),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
