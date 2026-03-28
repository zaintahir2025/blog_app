import 'package:flutter/material.dart';

import 'package:blog_app/features/blog/utils/post_insights.dart';
import 'package:blog_app/theme/app_theme.dart';

class EditorInsightsPanel extends StatelessWidget {
  const EditorInsightsPanel({
    super.key,
    required this.title,
    required this.content,
    required this.isPublished,
    this.fontPresetLabel,
    this.statusLabel,
  });

  final String title;
  final String content;
  final bool isPublished;
  final String? fontPresetLabel;
  final String? statusLabel;

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
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Writing insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isPublished
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPublished ? 'Ready to publish' : 'Draft mode',
                  style: TextStyle(
                    color:
                        isPublished ? colorScheme.primary : Colors.deepOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (statusLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              statusLabel!,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InsightChip(
                icon: Icons.title_rounded,
                label: safeTitle(title),
              ),
              _InsightChip(
                icon: Icons.notes_rounded,
                label: '${PostInsights.wordCount(content)} words',
              ),
              _InsightChip(
                icon: Icons.schedule_rounded,
                label: PostInsights.estimatedReadLabel(content),
              ),
              _InsightChip(
                icon: Icons.segment_rounded,
                label: '${PostInsights.paragraphCount(content)} paragraphs',
              ),
              if (fontPresetLabel != null)
                _InsightChip(
                  icon: Icons.text_fields_rounded,
                  label: fontPresetLabel!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String safeTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Untitled story';
    }
    return trimmed.length > 22
        ? '${trimmed.substring(0, 22).trimRight()}...'
        : trimmed;
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
