import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/utils/archive_links.dart';
import 'package:blog_app/features/blog/models/post_model.dart';

class StoryShareLink {
  const StoryShareLink({
    required this.uri,
    this.shareId,
  });

  final Uri uri;
  final String? shareId;

  bool get trackingEnabled => (shareId?.isNotEmpty ?? false);

  String messageFor(PostModel post) {
    return '"${post.title}" by @${post.authorName}\nRead it on Inkwell: $uri';
  }
}

class StoryShareMetrics {
  const StoryShareMetrics({
    this.shareCount = 0,
    this.openCount = 0,
  });

  final int shareCount;
  final int openCount;
}

class StoryShareRepository {
  StoryShareRepository(this._client);

  final SupabaseClient _client;

  Future<StoryShareLink> createShareLink(PostModel post) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return StoryShareLink(uri: ArchiveLinks.postUri(post.id));
    }

    try {
      final response = await _client
          .from('story_share_events')
          .insert({
            'post_id': post.id,
            'shared_by': user.id,
            'channel': 'clipboard',
          })
          .select('id')
          .single();

      final shareId = response['id'] as String?;
      if (shareId == null || shareId.isEmpty) {
        return StoryShareLink(uri: ArchiveLinks.postUri(post.id));
      }

      return StoryShareLink(
        uri: ArchiveLinks.postUri(
          post.id,
          shareId: shareId,
          sharedByUserId: user.id,
        ),
        shareId: shareId,
      );
    } catch (_) {
      return StoryShareLink(uri: ArchiveLinks.postUri(post.id));
    }
  }

  Future<void> recordShareOpen({
    required String shareId,
    required String postId,
  }) async {
    final trimmedShareId = shareId.trim();
    final trimmedPostId = postId.trim();
    if (trimmedShareId.isEmpty || trimmedPostId.isEmpty) {
      return;
    }

    try {
      await _client.rpc(
        'record_story_share_open',
        params: {
          'share_event_id': trimmedShareId,
          'opened_post_id': trimmedPostId,
        },
      );
    } catch (_) {
      // Sharing should degrade gracefully when metrics are unavailable.
    }
  }

  Future<StoryShareMetrics> fetchMetrics(String postId) async {
    try {
      final response = await _client
          .from('story_share_events')
          .select('id, opened_at')
          .eq('post_id', postId);

      final rows = (response as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      final openCount = rows.where((row) => row['opened_at'] != null).length;

      return StoryShareMetrics(
        shareCount: rows.length,
        openCount: openCount,
      );
    } catch (_) {
      return const StoryShareMetrics();
    }
  }
}

final storyShareRepositoryProvider = Provider<StoryShareRepository>((ref) {
  return StoryShareRepository(Supabase.instance.client);
});

final storyShareMetricsProvider =
    FutureProvider.family<StoryShareMetrics, String>((ref, postId) async {
  return ref.read(storyShareRepositoryProvider).fetchMetrics(postId);
});
