import 'package:flutter/material.dart';

import 'package:blog_app/features/blog/utils/story_markup.dart';

class MarkdownToolbar extends StatelessWidget {
  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.fontPreset,
    required this.onFontPresetChanged,
    required this.onInsertImage,
    this.compact = false,
  });

  final TextEditingController controller;
  final StoryFontPreset fontPreset;
  final ValueChanged<StoryFontPreset> onFontPresetChanged;
  final Future<String?> Function() onInsertImage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          compact
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildActions()
                        .map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: action,
                          ),
                        )
                        .toList(),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildActions(),
                ),
          const SizedBox(height: 14),
          compact
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildFontChips()
                        .map(
                          (chip) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: chip,
                          ),
                        )
                        .toList(),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildFontChips(),
                ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      _ToolbarAction(
        icon: Icons.title_rounded,
        label: 'H1',
        compact: compact,
        onTap: () => StoryMarkup.prependSelectionLines(
          controller,
          prefix: '# ',
        ),
      ),
      _ToolbarAction(
        icon: Icons.format_size_rounded,
        label: 'H2',
        compact: compact,
        onTap: () => StoryMarkup.prependSelectionLines(
          controller,
          prefix: '## ',
        ),
      ),
      _ToolbarAction(
        icon: Icons.format_bold_rounded,
        label: 'Bold',
        compact: compact,
        onTap: () => StoryMarkup.wrapSelection(
          controller,
          prefix: '**',
          suffix: '**',
          placeholder: 'bold text',
        ),
      ),
      _ToolbarAction(
        icon: Icons.format_italic_rounded,
        label: 'Italic',
        compact: compact,
        onTap: () => StoryMarkup.wrapSelection(
          controller,
          prefix: '_',
          suffix: '_',
          placeholder: 'italic text',
        ),
      ),
      _ToolbarAction(
        icon: Icons.format_quote_rounded,
        label: 'Quote',
        compact: compact,
        onTap: () => StoryMarkup.prependSelectionLines(
          controller,
          prefix: '> ',
        ),
      ),
      _ToolbarAction(
        icon: Icons.format_list_bulleted_rounded,
        label: 'List',
        compact: compact,
        onTap: () => StoryMarkup.prependSelectionLines(
          controller,
          prefix: '- ',
        ),
      ),
      _ToolbarAction(
        icon: Icons.horizontal_rule_rounded,
        label: 'Divider',
        compact: compact,
        onTap: () => StoryMarkup.insertAtCursor(controller, '---'),
      ),
      _ToolbarAction(
        icon: Icons.image_outlined,
        label: 'Image',
        compact: compact,
        onTap: () async {
          final url = await onInsertImage();
          if (url == null || url.isEmpty) {
            return;
          }
          StoryMarkup.insertAtCursor(
            controller,
            '![Story image]($url)',
          );
        },
      ),
    ];
  }

  List<Widget> _buildFontChips() {
    return StoryFontPreset.values
        .map(
          (preset) => ChoiceChip(
            label: Text(StoryMarkup.fontLabel(preset)),
            selected: preset == fontPreset,
            onSelected: (_) => onFontPresetChanged(preset),
          ),
        )
        .toList();
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      onPressed: onTap,
    );
  }
}
