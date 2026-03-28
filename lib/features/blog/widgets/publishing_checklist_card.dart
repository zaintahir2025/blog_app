import 'package:flutter/material.dart';

import 'package:blog_app/features/blog/utils/post_insights.dart';
import 'package:blog_app/theme/app_theme.dart';

class PublishingChecklistCard extends StatelessWidget {
  const PublishingChecklistCard({
    super.key,
    required this.title,
    required this.content,
    required this.hasCoverImage,
  });

  final String title;
  final String content;
  final bool hasCoverImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final checks = [
      _ChecklistItem(
        label: 'Headline feels complete',
        description: 'Use at least 8 characters so the story has a clear hook.',
        passed: title.trim().length >= 8,
      ),
      _ChecklistItem(
        label: 'Body has enough depth',
        description: 'Aim for at least 120 words before publishing.',
        passed: PostInsights.wordCount(content) >= 120,
      ),
      _ChecklistItem(
        label: 'Structure is easy to scan',
        description: 'Three or more paragraphs usually read better on mobile.',
        passed: PostInsights.paragraphCount(content) >= 3,
      ),
      _ChecklistItem(
        label: 'Cover image included',
        description: 'Visuals improve feed performance and click-through rate.',
        passed: hasCoverImage,
      ),
    ];
    final completedCount = checks.where((item) => item.passed).length;
    final readiness = completedCount / checks.length;

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
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Publishing checklist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(readiness * 100).round()}%',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: readiness,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          ...checks.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.passed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: item.passed
                        ? Colors.green.shade600
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem({
    required this.label,
    required this.description,
    required this.passed,
  });

  final String label;
  final String description;
  final bool passed;
}
