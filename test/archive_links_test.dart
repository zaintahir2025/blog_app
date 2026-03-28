import 'package:blog_app/core/utils/archive_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveLinks', () {
    test('builds canonical story links', () {
      expect(ArchiveLinks.postPath('post-123'), '/posts/post-123');

      final uri = ArchiveLinks.postUri('post-123');
      expect(uri.host, ArchiveLinks.host);
      expect(uri.path, '/posts/post-123');
    });

    test('builds discover links with optional query', () {
      expect(ArchiveLinks.discoverPath(), '/discover');

      final uri = ArchiveLinks.discoverUri(query: 'Deep work');
      expect(uri.host, ArchiveLinks.host);
      expect(uri.path, '/discover');
      expect(uri.queryParameters['q'], 'Deep work');
      expect(
        ArchiveLinks.display(uri),
        '${ArchiveLinks.host}/discover?${uri.query}',
      );
    });
  });
}
