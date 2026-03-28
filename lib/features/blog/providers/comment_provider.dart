import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blog_app/features/blog/models/comment_model.dart';

const _modernContentColumn = 'text_content';
const _legacyContentColumn = 'content';

final commentsProvider = StateNotifierProvider.family<CommentsNotifier,
    AsyncValue<List<CommentModel>>, String>((ref, postId) {
  return CommentsNotifier(postId: postId);
});

class CommentsNotifier extends StateNotifier<AsyncValue<List<CommentModel>>> {
  final String postId;
  RealtimeChannel? _channel;
  String _contentColumn = _modernContentColumn;

  CommentsNotifier({required this.postId}) : super(const AsyncValue.loading()) {
    _fetchComments();
    _setupRealtime();
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await _fetchCommentsForColumn(_contentColumn);
      if (mounted) {
        state = AsyncValue.data(comments);
      }
    } on PostgrestException catch (error, stackTrace) {
      final fallbackColumn = _alternateColumn(_contentColumn);
      if (_isMissingColumn(error, _contentColumn) &&
          fallbackColumn != _contentColumn) {
        try {
          final comments = await _fetchCommentsForColumn(fallbackColumn);
          _contentColumn = fallbackColumn;
          if (mounted) {
            state = AsyncValue.data(comments);
          }
          return;
        } catch (fallbackError, fallbackStackTrace) {
          if (mounted) {
            state = AsyncValue.error(fallbackError, fallbackStackTrace);
          }
          return;
        }
      }

      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<List<CommentModel>> _fetchCommentsForColumn(
      String contentColumn) async {
    final response = await Supabase.instance.client
        .from('comments')
        .select(
          'id, post_id, user_id, $contentColumn, created_at, profiles(username, full_name)',
        )
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    return response
        .map((json) => CommentModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  void _setupRealtime() {
    _channel = Supabase.instance.client
        .channel('public:comments:post_$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: postId,
          ),
          callback: (payload) {
            _fetchComments();
          },
        )
        .subscribe();
  }

  Future<void> addComment(String content) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw 'You must be logged in to comment.';

    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return;

    try {
      await _insertComment(_contentColumn, user.id, trimmedContent);
      await _fetchComments();
    } on PostgrestException catch (error) {
      final fallbackColumn = _alternateColumn(_contentColumn);
      if (_isMissingColumn(error, _contentColumn) &&
          fallbackColumn != _contentColumn) {
        await _insertComment(fallbackColumn, user.id, trimmedContent);
        _contentColumn = fallbackColumn;
        await _fetchComments();
        return;
      }
      throw error.toString();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> _insertComment(
    String contentColumn,
    String userId,
    String content,
  ) {
    return Supabase.instance.client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      contentColumn: content,
    });
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await Supabase.instance.client
          .from('comments')
          .delete()
          .eq('id', commentId);
      await _fetchComments();
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

String _alternateColumn(String column) {
  return column == _modernContentColumn
      ? _legacyContentColumn
      : _modernContentColumn;
}

bool _isMissingColumn(PostgrestException error, String column) {
  final normalized = error.message.toLowerCase();
  return normalized.contains(column.toLowerCase()) &&
      normalized.contains('schema cache');
}
