import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/utils/post_insights.dart';

class ReadingHistoryEntry {
  const ReadingHistoryEntry({
    required this.postId,
    required this.title,
    required this.authorName,
    required this.excerpt,
    required this.viewedAt,
    required this.progress,
    required this.readMinutes,
    this.coverImageUrl,
  });

  factory ReadingHistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return ReadingHistoryEntry(
      postId: map['post_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      authorName: map['author_name'] as String? ?? 'Unknown',
      excerpt: map['excerpt'] as String? ?? '',
      viewedAt: DateTime.tryParse(map['viewed_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      progress: ((map['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      readMinutes: map['read_minutes'] as int? ?? 1,
      coverImageUrl: map['cover_image_url'] as String?,
    );
  }

  factory ReadingHistoryEntry.fromPost(
    PostModel post, {
    required double progress,
    required DateTime viewedAt,
  }) {
    return ReadingHistoryEntry(
      postId: post.id,
      title: post.title,
      authorName: post.authorName,
      excerpt: PostInsights.excerpt(post.content),
      viewedAt: viewedAt,
      progress: progress.clamp(0.0, 1.0),
      readMinutes: PostInsights.estimatedReadMinutes(post.content),
      coverImageUrl: post.coverImageUrl,
    );
  }

  final String postId;
  final String title;
  final String authorName;
  final String excerpt;
  final DateTime viewedAt;
  final double progress;
  final int readMinutes;
  final String? coverImageUrl;

  bool get isCompleted => progress >= 0.98;

  String get progressLabel {
    final percentage = (progress * 100).round();
    if (percentage <= 0) {
      return 'Start reading';
    }
    if (percentage >= 98) {
      return 'Completed';
    }
    return '$percentage% complete';
  }

  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'title': title,
      'author_name': authorName,
      'excerpt': excerpt,
      'viewed_at': viewedAt.toIso8601String(),
      'progress': progress,
      'read_minutes': readMinutes,
      'cover_image_url': coverImageUrl,
    };
  }
}

class ReadingHistoryNotifier extends StateNotifier<List<ReadingHistoryEntry>> {
  ReadingHistoryNotifier() : super(_load());

  static const String _boxName = 'history_box';

  static Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  static List<ReadingHistoryEntry> _load() {
    final entries = _box.values
        .whereType<Map>()
        .map((map) => ReadingHistoryEntry.fromMap(map))
        .toList()
      ..sort((first, second) => second.viewedAt.compareTo(first.viewedAt));
    return entries;
  }

  Future<void> trackOpen(PostModel post) async {
    final existing = state.cast<ReadingHistoryEntry?>().firstWhere(
          (entry) => entry?.postId == post.id,
          orElse: () => null,
        );
    final progress = existing?.progress ?? 0;
    await _saveEntry(
      ReadingHistoryEntry.fromPost(
        post,
        progress: progress,
        viewedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateProgress(PostModel post, double progress) async {
    await _saveEntry(
      ReadingHistoryEntry.fromPost(
        post,
        progress: progress,
        viewedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeEntry(String postId) async {
    await _box.delete(postId);
    state = state.where((entry) => entry.postId != postId).toList();
  }

  Future<void> clearHistory() async {
    await _box.clear();
    state = const [];
  }

  Future<void> _saveEntry(ReadingHistoryEntry entry) async {
    await _box.put(entry.postId, entry.toMap());
    final items = [
      entry,
      ...state.where((item) => item.postId != entry.postId),
    ]..sort((first, second) => second.viewedAt.compareTo(first.viewedAt));
    state = items;
  }
}

final readingHistoryProvider =
    StateNotifierProvider<ReadingHistoryNotifier, List<ReadingHistoryEntry>>(
        (ref) {
  return ReadingHistoryNotifier();
});

final continueReadingProvider = Provider<List<ReadingHistoryEntry>>((ref) {
  return ref
      .watch(readingHistoryProvider)
      .where((entry) => entry.progress > 0 && !entry.isCompleted)
      .take(6)
      .toList();
});

final recentReadingProvider = Provider<List<ReadingHistoryEntry>>((ref) {
  return ref.watch(readingHistoryProvider).take(8).toList();
});

final readingHistoryEntryProvider =
    Provider.family<ReadingHistoryEntry?, String>((ref, postId) {
  return ref.watch(
    readingHistoryProvider.select(
      (entries) => entries.cast<ReadingHistoryEntry?>().firstWhere(
            (entry) => entry?.postId == postId,
            orElse: () => null,
          ),
    ),
  );
});
