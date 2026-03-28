import 'package:flutter_test/flutter_test.dart';

import 'package:blog_app/features/blog/models/comment_model.dart';

void main() {
  test('CommentModel reads modern text_content schema safely', () {
    final comment = CommentModel.fromJson({
      'id': 'comment-1',
      'post_id': 'post-1',
      'user_id': 'user-1',
      'text_content': 'Hello from the new schema',
      'created_at': '2026-03-25T12:00:00.000Z',
      'profiles': {
        'username': 'admin',
        'full_name': 'Admin',
      },
    });

    expect(comment.content, 'Hello from the new schema');
    expect(comment.authorName, 'admin');
  });

  test('CommentModel falls back when profile names are missing', () {
    final comment = CommentModel.fromJson({
      'id': 'comment-2',
      'post_id': 'post-2',
      'user_id': 'user-2',
      'content': 'Legacy comment body',
      'created_at': '2026-03-25T12:00:00.000Z',
      'profiles': {
        'username': null,
        'full_name': 'Zain Tahir',
      },
    });

    expect(comment.content, 'Legacy comment body');
    expect(comment.authorName, 'Zain Tahir');
  });
}
