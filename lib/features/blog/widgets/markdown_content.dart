import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:blog_app/features/blog/utils/story_markup.dart';

class MarkdownContent extends StatelessWidget {
  const MarkdownContent({
    super.key,
    required this.content,
    this.textScale = 1,
  });

  final String content;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = StoryMarkup.fontPreset(content);
    final body = StoryMarkup.normalizedBody(content);
    final baseTextStyle = _bodyStyle(theme, preset).copyWith(
      fontSize: 18 * textScale,
      height: 1.9,
    );
    final headingColor = theme.colorScheme.onSurface;
    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: baseTextStyle,
      h1: _headingStyle(theme, preset, 34).copyWith(color: headingColor),
      h2: _headingStyle(theme, preset, 28).copyWith(color: headingColor),
      h3: _headingStyle(theme, preset, 24).copyWith(color: headingColor),
      blockquote: baseTextStyle.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      blockSpacing: 20,
      listBullet: baseTextStyle.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      strong: baseTextStyle.copyWith(fontWeight: FontWeight.w800),
      em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      code: GoogleFonts.sourceCodePro(
        textStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          fontSize: 15 * textScale,
        ),
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
    );

    return MarkdownBody(
      data: body,
      selectable: true,
      styleSheet: styleSheet,
      sizedImageBuilder: (config) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.network(
              config.uri.toString(),
              fit: BoxFit.cover,
              width: config.width,
              height: config.height,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  TextStyle _bodyStyle(ThemeData theme, StoryFontPreset preset) {
    return switch (preset) {
      StoryFontPreset.serif => GoogleFonts.lora(
          textStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.94),
          ),
        ),
      StoryFontPreset.editorial => GoogleFonts.playfairDisplay(
          textStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.94),
          ),
        ),
      StoryFontPreset.mono => GoogleFonts.ibmPlexMono(
          textStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.94),
          ),
        ),
      StoryFontPreset.clean => GoogleFonts.plusJakartaSans(
          textStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.94),
          ),
        ),
    };
  }

  TextStyle _headingStyle(
    ThemeData theme,
    StoryFontPreset preset,
    double size,
  ) {
    final base = switch (preset) {
      StoryFontPreset.serif => GoogleFonts.lora(),
      StoryFontPreset.editorial => GoogleFonts.playfairDisplay(),
      StoryFontPreset.mono => GoogleFonts.ibmPlexMono(),
      StoryFontPreset.clean => GoogleFonts.plusJakartaSans(),
    };

    return base.copyWith(
      fontSize: size * textScale,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.4,
    );
  }
}
