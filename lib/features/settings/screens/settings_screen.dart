import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blog_app/core/providers/app_preferences_provider.dart';
import 'package:blog_app/core/providers/reading_history_provider.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/providers/blog_insights_provider.dart';
import 'package:blog_app/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final history = ref.watch(readingHistoryProvider);
    final drafts = ref.watch(draftPostsProvider);
    final bookmarks = ref.watch(bookmarkedPostsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: InkBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth(context),
            ),
            child: ListView(
              padding: AppLayout.pagePadding(context),
              children: [
                InkHeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const InkEyebrow(
                        label: 'Preferences',
                        icon: Icons.tune_rounded,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Shape the studio around the way you read and write.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Control theme, density, motion, and reader comfort from one calm workspace.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppLayout.sectionGap(context)),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 780;
                    final gap = AppLayout.panelGap(context);
                    final itemWidth = wide
                        ? (constraints.maxWidth - (gap * 2)) / 3
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: _SettingsMetric(
                            label: 'Reading history',
                            value: history.length.toString(),
                            icon: Icons.history_rounded,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _SettingsMetric(
                            label: 'Drafts',
                            value: drafts.length.toString(),
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _SettingsMetric(
                            label: 'Bookmarks',
                            value: bookmarks.length.toString(),
                            icon: Icons.bookmark_rounded,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: AppLayout.sectionGap(context)),
                _SettingsSection(
                  title: 'Appearance',
                  subtitle:
                      'Adjust the product tone and reading comfort across the app.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final selector = SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.system,
                                icon: Icon(Icons.brightness_auto),
                                label: Text('System'),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_outlined),
                                label: Text('Light'),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_outlined),
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {preferences.themeMode},
                            onSelectionChanged: (selection) => ref
                                .read(appPreferencesProvider.notifier)
                                .setThemeMode(selection.first),
                          );

                          if (constraints.maxWidth >= 420) {
                            return selector;
                          }

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: selector,
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: preferences.compactCards,
                        onChanged: (value) => ref
                            .read(appPreferencesProvider.notifier)
                            .setCompactCards(value),
                        title: const Text('Compact story cards'),
                        subtitle: const Text(
                          'Fit more cards on screen, especially on desktop and web.',
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: preferences.reducedMotion,
                        onChanged: (value) => ref
                            .read(appPreferencesProvider.notifier)
                            .setReducedMotion(value),
                        title: const Text('Reduce motion'),
                        subtitle: const Text(
                          'Tone down transitions for comfort and focus.',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Default reading size',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: preferences.readerTextScale,
                        min: 0.9,
                        max: 1.3,
                        divisions: 4,
                        label:
                            '${(preferences.readerTextScale * 100).round()}%',
                        onChanged: (value) => ref
                            .read(appPreferencesProvider.notifier)
                            .setReaderTextScale(value),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppLayout.panelGap(context)),
                _SettingsSection(
                  title: 'Maintenance',
                  subtitle:
                      'Reset local preferences or clean up stored reading activity.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkInfoBanner(
                        icon: Icons.shield_outlined,
                        title: 'Safe resets',
                        body:
                            'These actions affect only local app behavior and continuity data.',
                        compact: true,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: history.isEmpty
                            ? null
                            : () => ref
                                .read(readingHistoryProvider.notifier)
                                .clearHistory(),
                        icon: const Icon(Icons.history_toggle_off_rounded),
                        label: const Text('Clear reading history'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(appPreferencesProvider.notifier).reset(),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reset display preferences'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkPanel(
      padding: const EdgeInsets.all(24),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkSectionHeader(
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SettingsMetric extends StatelessWidget {
  const _SettingsMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkPanel(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 32,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
