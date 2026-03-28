import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:blog_app/core/providers/reading_history_provider.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/theme/app_theme.dart';

class ReadingHistoryCard extends StatelessWidget {
  const ReadingHistoryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onRemove,
  });

  final ReadingHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final compactViewport = viewportWidth < 480;
    final cardWidth = compactViewport
        ? math.max(0.0, viewportWidth - 56)
        : math.min(304.0, math.max(0.0, viewportWidth - 32));
    final hasCoverImage = entry.coverImageUrl != null;
    final compact = cardWidth < 286;

    return SizedBox(
      width: cardWidth,
      height: compactViewport ? 308 : (compact ? 300 : 304),
      child: InkPanel(
        padding: EdgeInsets.zero,
        radius: 28,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCoverImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: SizedBox(
                      height: compact ? 88 : 96,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: entry.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: compact ? 64 : 68,
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient(colorScheme.brightness),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 18,
                      compact ? 14 : 16,
                      compact ? 16 : 18,
                      18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkMetricPill(
                                label: 'Continue',
                                value: entry.progressLabel,
                                icon: Icons.menu_book_rounded,
                                accentColor: colorScheme.primary,
                              ),
                            ),
                            if (onRemove != null) ...[
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: onRemove,
                                icon: const Icon(Icons.close_rounded, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        Text(
                          entry.title,
                          maxLines: hasCoverImage ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontSize: compact ? 22 : 24,
                                    height: 1.08,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '@${entry.authorName} | ${entry.readMinutes} min read',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        Expanded(
                          child: Text(
                            entry.excerpt,
                            maxLines: compact
                                ? (hasCoverImage ? 2 : 3)
                                : (hasCoverImage ? 3 : 4),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: entry.progress,
                            minHeight: 8,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
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
