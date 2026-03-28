import 'package:flutter/material.dart';

import 'package:blog_app/features/profile/models/user_profile_model.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';
import 'package:blog_app/theme/app_theme.dart';

class FriendListPanel extends StatelessWidget {
  const FriendListPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.friends,
    required this.onFriendTap,
    this.emptyMessage = 'No friends to show yet.',
  });

  final String title;
  final String subtitle;
  final List<UserProfileModel> friends;
  final ValueChanged<UserProfileModel> onFriendTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.panelBorder(colorScheme)),
        boxShadow: AppTheme.panelShadows(colorScheme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (friends.isEmpty)
            Text(
              emptyMessage,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final columns = constraints.maxWidth > 860
                    ? 3
                    : constraints.maxWidth > 520
                        ? 2
                        : 1;
                final itemWidth = columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - (spacing * (columns - 1))) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: friends
                      .map(
                        (friend) => SizedBox(
                          width: itemWidth,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => onFriendTap(friend),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  ProfileAvatar(
                                    userId: friend.id,
                                    fallbackLabel: _initial(friend.displayName),
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          friend.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '@${friend.username}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
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
