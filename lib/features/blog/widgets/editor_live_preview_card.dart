import 'package:flutter/material.dart';

import 'package:blog_app/features/blog/utils/story_markup.dart';
import 'package:blog_app/features/blog/widgets/markdown_content.dart';

class EditorLivePreviewCard extends StatelessWidget {
  const EditorLivePreviewCard({
    super.key,
    required this.title,
    required this.content,
    this.previewImage,
    this.fullPreview = false,
  });

  final String title;
  final String content;
  final Widget? previewImage;
  final bool fullPreview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeTitle = title.trim().isEmpty ? 'Untitled story' : title.trim();
    final hasBody = StoryMarkup.normalizedBody(content).trim().isNotEmpty;
    final previewContent = fullPreview
        ? content
        : StoryMarkup.previewContent(
            content,
            maxParagraphs: 3,
            maxCharacters: 520,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fullPreview ? 'Live preview' : 'Reader preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fullPreview
                ? 'Review the story exactly as readers will experience it.'
                : 'A quick preview of the opening experience your readers will see first.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (previewImage != null)
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: previewImage,
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safeTitle,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                      ),
                      const SizedBox(height: 16),
                      if (hasBody)
                        MarkdownContent(
                          content: previewContent,
                          textScale: fullPreview ? 0.96 : 0.88,
                        )
                      else
                        Text(
                          'Start writing to see a live preview with headings, emphasis, lists, quotes, and images.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
