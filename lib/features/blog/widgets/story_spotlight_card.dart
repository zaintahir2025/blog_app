import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/utils/post_insights.dart';
import 'package:blog_app/theme/app_theme.dart';

class StorySpotlightCard extends StatelessWidget {
  const StorySpotlightCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.eyebrow,
    this.onAuthorTap,
  });

  final PostModel post;
  final VoidCallback onTap;
  final String eyebrow;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final hasCoverImage = post.coverImageUrl != null;
    final useOnImageContrast = hasCoverImage;
    final titleColor =
        useOnImageContrast ? Colors.white : colorScheme.onSurface;
    final supportingColor = useOnImageContrast
        ? Colors.white.withValues(alpha: 0.86)
        : colorScheme.onSurfaceVariant;
    final titleShadows = useOnImageContrast
        ? [
            Shadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 3),
            ),
          ]
        : const <Shadow>[];
    final supportingShadows = useOnImageContrast
        ? [
            Shadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ]
        : const <Shadow>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 760;
        final narrow = width < 560;
        final aspectRatio = narrow
            ? 4 / 5
            : compact
                ? 16 / 11.2
                : 16 / 10;

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: AppTheme.heroGradient(
                  colorScheme.brightness,
                ),
                border: Border.all(color: AppTheme.panelBorder(colorScheme)),
                boxShadow: AppTheme.panelShadows(
                  colorScheme.brightness,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (hasCoverImage)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: post.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: hasCoverImage
                              ? [
                                  Colors.black.withValues(
                                    alpha: isDark ? 0.12 : 0.08,
                                  ),
                                  Colors.black.withValues(
                                    alpha: isDark ? 0.26 : 0.18,
                                  ),
                                  Colors.black.withValues(
                                    alpha: isDark ? 0.76 : 0.58,
                                  ),
                                ]
                              : [
                                  Colors.white.withValues(
                                    alpha: isDark ? 0 : 0.52,
                                  ),
                                  Colors.black.withValues(
                                    alpha: isDark ? 0.14 : 0.04,
                                  ),
                                  Colors.black.withValues(
                                    alpha: isDark ? 0.74 : 0.12,
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(narrow ? 20 : 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkEyebrow(label: eyebrow),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@${post.authorName} | ${PostInsights.estimatedReadLabel(post.content)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: supportingColor,
                                        shadows: supportingShadows,
                                      ),
                                ),
                                SizedBox(height: narrow ? 12 : 14),
                                Text(
                                  post.title,
                                  maxLines: narrow ? 2 : 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        fontSize: narrow ? 28 : 32,
                                        color: titleColor,
                                        shadows: titleShadows,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  PostInsights.excerpt(post.content),
                                  maxLines: narrow ? 2 : 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: supportingColor,
                                        shadows: supportingShadows,
                                      ),
                                ),
                                SizedBox(height: narrow ? 14 : 18),
                                narrow
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          FilledButton(
                                            onPressed: onTap,
                                            child: const Text('Read story'),
                                          ),
                                          if (onAuthorTap != null) ...[
                                            const SizedBox(height: 10),
                                            OutlinedButton.icon(
                                              onPressed: onAuthorTap,
                                              icon: const Icon(
                                                Icons.person_outline_rounded,
                                              ),
                                              label: const Text('View author'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    useOnImageContrast
                                                        ? Colors.white
                                                        : colorScheme.onSurface,
                                                backgroundColor:
                                                    useOnImageContrast
                                                        ? Colors.black
                                                            .withValues(
                                                            alpha: 0.18,
                                                          )
                                                        : null,
                                                side: BorderSide(
                                                  color: useOnImageContrast
                                                      ? Colors.white.withValues(
                                                          alpha: 0.22)
                                                      : colorScheme.outline,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      )
                                    : Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          FilledButton(
                                            onPressed: onTap,
                                            child: const Text('Read story'),
                                          ),
                                          if (onAuthorTap != null)
                                            OutlinedButton.icon(
                                              onPressed: onAuthorTap,
                                              icon: const Icon(
                                                Icons.person_outline_rounded,
                                              ),
                                              label: const Text('View author'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    useOnImageContrast
                                                        ? Colors.white
                                                        : colorScheme.onSurface,
                                                backgroundColor:
                                                    useOnImageContrast
                                                        ? Colors.black
                                                            .withValues(
                                                            alpha: 0.18,
                                                          )
                                                        : null,
                                                side: BorderSide(
                                                  color: useOnImageContrast
                                                      ? Colors.white.withValues(
                                                          alpha: 0.22)
                                                      : colorScheme.outline,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                              ],
                            ),
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
      },
    );
  }
}
