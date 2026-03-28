import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/widgets/story_spotlight_card.dart';
import 'package:blog_app/theme/app_theme.dart';

void main() {
  testWidgets(
    'Story spotlight uses readable on-image text colors in light theme',
    (tester) async {
      const title = 'About me';
      const excerpt = 'I am zain tahir';
      const meta = '@zaintahir | 1 min read';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: StorySpotlightCard(
                  post: PostModel(
                    id: 'spotlight-post',
                    title: title,
                    content: excerpt,
                    coverImageUrl: 'https://example.com/cover.jpg',
                    createdAt: DateTime(2026, 3, 29),
                    authorName: 'zaintahir',
                    userId: 'writer-1',
                    isPublished: true,
                  ),
                  eyebrow: 'Top performing story',
                  onTap: () {},
                  onAuthorTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final titleWidget = tester.widget<Text>(find.text(title));
      final metaWidget = tester.widget<Text>(find.text(meta));
      final excerptWidget = tester.widget<Text>(find.text(excerpt));

      expect(titleWidget.style?.color, equals(Colors.white));
      expect(metaWidget.style?.color, equals(Colors.white.withValues(alpha: 0.86)));
      expect(
        excerptWidget.style?.color,
        equals(Colors.white.withValues(alpha: 0.86)),
      );
    },
  );
}
