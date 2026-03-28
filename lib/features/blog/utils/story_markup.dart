import 'package:flutter/material.dart';

enum StoryFontPreset {
  clean,
  serif,
  editorial,
  mono,
}

class StoryMarkup {
  static const _metaPrefix = '<!-- inkwell:font=';
  static final _metaPattern = RegExp(
    r'^\s*<!--\s*inkwell:font=([a-z]+)\s*-->\s*',
    multiLine: false,
  );
  static final _invisibleCharacterPattern = RegExp(r'[\u200B-\u200D\uFEFF]');

  static StoryFontPreset fontPreset(String content) {
    final match = _metaPattern.firstMatch(content);
    final rawValue = match?.group(1);

    return switch (rawValue) {
      'serif' => StoryFontPreset.serif,
      'editorial' => StoryFontPreset.editorial,
      'mono' => StoryFontPreset.mono,
      _ => StoryFontPreset.clean,
    };
  }

  static String visibleBody(String content) {
    return content.replaceFirst(_metaPattern, '').trim();
  }

  static String normalizedBody(String content) {
    var body = visibleBody(content)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_invisibleCharacterPattern, '');

    body = body.replaceAllMapped(
      RegExp(r'^(\s{0,3})(#{1,6})([^\s#])', multiLine: true),
      (match) => '${match.group(1)}${match.group(2)} ${match.group(3)}',
    );

    body = body.replaceAllMapped(
      RegExp(r'\*\*\s+(.+?)\s+\*\*'),
      (match) => '**${match.group(1)?.trim() ?? ''}**',
    );

    body = body.replaceAllMapped(
      RegExp(r'(?<!\*)\*\s+(.+?)\s+\*(?!\*)'),
      (match) => '*${match.group(1)?.trim() ?? ''}*',
    );

    body = body.replaceAllMapped(
      RegExp(r'(?<!_)_\s+(.+?)\s+_(?!_)'),
      (match) => '_${match.group(1)?.trim() ?? ''}_',
    );

    body = body.replaceAllMapped(
      RegExp(r'__\s+(.+?)\s+__'),
      (match) => '__${match.group(1)?.trim() ?? ''}__',
    );

    body = body.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return body;
  }

  static String applyFontPreset(String content, StoryFontPreset preset) {
    final body = normalizedBody(content);
    return '$_metaPrefix${preset.name} -->\n\n$body'.trim();
  }

  static String previewContent(
    String content, {
    int maxParagraphs = 3,
    int maxCharacters = 520,
  }) {
    final preset = fontPreset(content);
    final body = normalizedBody(content);
    final paragraphs = body
        .split(RegExp(r'\n\s*\n'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .take(maxParagraphs)
        .toList();

    var preview = paragraphs.join('\n\n').trim();
    if (preview.length > maxCharacters) {
      preview = preview.substring(0, maxCharacters).trimRight();
      final safeBreak = preview.lastIndexOf(RegExp(r'[\s\n]'));
      if (safeBreak > maxCharacters * 0.6) {
        preview = preview.substring(0, safeBreak).trimRight();
      }
      preview = '$preview\n\n...';
    }

    return applyFontPreset(preview, preset);
  }

  static String fontLabel(StoryFontPreset preset) {
    return switch (preset) {
      StoryFontPreset.clean => 'Clean Sans',
      StoryFontPreset.serif => 'Classic Serif',
      StoryFontPreset.editorial => 'Editorial',
      StoryFontPreset.mono => 'Modern Mono',
    };
  }

  static String plainText(String content) {
    final withoutMeta = visibleBody(content);
    final withoutImages =
        withoutMeta.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), ' ');
    final withoutLinks = withoutImages.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'), (match) => match.group(1) ?? '');
    final withoutHeadings = withoutLinks.replaceAll(
        RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
    final withoutQuotes =
        withoutHeadings.replaceAll(RegExp(r'^\s*>\s?', multiLine: true), '');
    final withoutLists = withoutQuotes.replaceAll(
      RegExp(r'^\s*(?:[-*+]|\d+\.)\s+', multiLine: true),
      '',
    );
    final withoutDecorators = withoutLists
        .replaceAll(RegExp(r'[`*_~]+'), '')
        .replaceAll(RegExp(r'^---+$', multiLine: true), ' ');

    return withoutDecorators.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static void wrapSelection(
    TextEditingController controller, {
    required String prefix,
    String suffix = '',
    String placeholder = 'text',
  }) {
    final value = controller.value;
    final selection = value.selection;
    final text = value.text;

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final selectedText = start >= 0 && end >= 0 && start <= end
        ? text.substring(start, end)
        : '';
    final hasSelection = selectedText.isNotEmpty;
    final trimmed = selectedText.trim();
    final leadingWhitespace = hasSelection
        ? selectedText.substring(
            0,
            selectedText.length - selectedText.trimLeft().length,
          )
        : '';
    final trailingWhitespace = hasSelection
        ? selectedText.substring(selectedText.trimRight().length)
        : '';
    final coreText =
        hasSelection ? (trimmed.isEmpty ? placeholder : trimmed) : placeholder;
    final replacement =
        '$leadingWhitespace$prefix$coreText$suffix$trailingWhitespace';
    final updatedText = text.replaceRange(start, end, replacement);
    final cursorOffset = hasSelection
        ? start + replacement.length
        : start + prefix.length + placeholder.length;

    controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(offset: cursorOffset),
      composing: TextRange.empty,
    );
  }

  static void prependSelectionLines(
    TextEditingController controller, {
    required String prefix,
  }) {
    final value = controller.value;
    final selection = value.selection;
    final text = value.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final selectedText = start >= 0 && end >= 0 && start <= end
        ? text.substring(start, end)
        : '';
    if (selectedText.isEmpty) {
      insertAtCursor(
        controller,
        '$prefix${_placeholderForBlockPrefix(prefix)}',
      );
      return;
    }

    final content = selectedText;
    final replaced = content
        .split('\n')
        .map((line) => line.trim().isEmpty ? line : '$prefix$line')
        .join('\n');
    final needsLeadingBreak = start > 0 && text[start - 1] != '\n';
    final needsTrailingBreak = end < text.length && text[end] != '\n';
    final replacement =
        '${needsLeadingBreak ? '\n' : ''}$replaced${needsTrailingBreak ? '\n' : ''}';
    final updatedText = text.replaceRange(start, end, replacement);

    controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
      composing: TextRange.empty,
    );
  }

  static void insertAtCursor(
    TextEditingController controller,
    String value, {
    bool surroundWithBreaks = true,
  }) {
    final current = controller.value;
    final selection = current.selection;
    final text = current.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final needsLeadingBreak =
        surroundWithBreaks && start > 0 && text[start - 1] != '\n';
    final needsTrailingBreak =
        surroundWithBreaks && end < text.length && text[end] != '\n';
    final insertion = surroundWithBreaks
        ? '${needsLeadingBreak ? '\n' : ''}$value${needsTrailingBreak ? '\n' : ''}'
        : value;
    final updatedText = text.replaceRange(start, end, insertion);

    controller.value = current.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(offset: start + insertion.length),
      composing: TextRange.empty,
    );
  }

  static String _placeholderForBlockPrefix(String prefix) {
    return switch (prefix.trim()) {
      '#' || '##' || '###' => 'Heading',
      '>' => 'Quote',
      '-' || '*' || '+' => 'List item',
      _ => 'Text',
    };
  }
}
