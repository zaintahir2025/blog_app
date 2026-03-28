import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blog_app/features/blog/utils/story_markup.dart';
import 'package:blog_app/features/blog/widgets/markdown_content.dart';

void main() {
  test('normalizedBody cleans common malformed markdown', () {
    const raw = '<!-- inkwell:font=clean -->\r\n\r\n#Title\r\n'
        'my name is ** zain ** and _ writer _';

    final normalized = StoryMarkup.normalizedBody(raw);

    expect(
      normalized,
      '# Title\nmy name is **zain** and _writer_',
    );
  });

  test('wrapSelection keeps outer whitespace but trims styled content', () {
    final controller = TextEditingController(text: 'hello  zain  world');
    controller.selection = const TextSelection(baseOffset: 5, extentOffset: 13);

    StoryMarkup.wrapSelection(
      controller,
      prefix: '**',
      suffix: '**',
      placeholder: 'bold text',
    );

    expect(controller.text, 'hello  **zain**  world');
  });

  test('prependSelectionLines inserts a clean heading block', () {
    final controller = TextEditingController(text: 'Body text');
    controller.selection = const TextSelection.collapsed(offset: 0);

    StoryMarkup.prependSelectionLines(
      controller,
      prefix: '# ',
    );

    expect(controller.text, '# Heading\nBody text');
  });

  testWidgets('MarkdownContent renders normalized markdown without raw markers',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownContent(
            content:
                '<!-- inkwell:font=clean -->\n\n#My Introduction\nmy name is ** zain ** and _ writer _',
          ),
        ),
      ),
    );

    expect(find.textContaining('#My'), findsNothing);
    expect(find.textContaining('** zain **'), findsNothing);
    expect(find.textContaining('_ writer _'), findsNothing);
    expect(find.textContaining('My Introduction'), findsOneWidget);
    expect(find.textContaining('my name is zain and writer'), findsOneWidget);
  });
}
