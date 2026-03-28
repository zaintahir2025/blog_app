import 'package:flutter_test/flutter_test.dart';

import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';

void main() {
  group('blog feed helpers', () {
    test('mergePostIntoFeed keeps posts sorted by publish date', () {
      final newest = _post(
        id: 'newest',
        title: 'Newest story',
        createdAt: DateTime(2026, 3, 28, 12),
      );
      final older = _post(
        id: 'older',
        title: 'Older story',
        createdAt: DateTime(2026, 3, 20, 12),
      );
      final refreshedOlder = older.copyWith(title: 'Older story updated');

      final merged = mergePostIntoFeed([newest, older], refreshedOlder);

      expect(merged.map((post) => post.id), ['newest', 'older']);
      expect(merged.where((post) => post.id == 'older'), hasLength(1));
      expect(merged.last.title, 'Older story updated');
    });

    test('canAccessPost only exposes drafts to their author', () {
      final draft = _post(
        id: 'draft',
        title: 'Private draft',
        userId: 'author-1',
        isPublished: false,
      );
      final published = _post(
        id: 'published',
        title: 'Public story',
        userId: 'author-1',
      );

      expect(canAccessPost(draft, 'author-1'), isTrue);
      expect(canAccessPost(draft, 'reader-2'), isFalse);
      expect(canAccessPost(published, 'reader-2'), isTrue);
    });
  });
}

PostModel _post({
  required String id,
  required String title,
  String userId = 'author-1',
  bool isPublished = true,
  DateTime? createdAt,
}) {
  return PostModel(
    id: id,
    title: title,
    content: 'Body for $title',
    createdAt: createdAt ?? DateTime(2026, 3, 28),
    authorName: 'writer',
    userId: userId,
    isPublished: isPublished,
  );
}
