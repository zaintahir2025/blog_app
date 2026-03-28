import 'dart:math';

import 'package:blog_app/core/providers/reading_history_provider.dart';
import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/utils/post_insights.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReadingResumeItem {
  const ReadingResumeItem({
    required this.post,
    required this.historyEntry,
  });

  final PostModel post;
  final ReadingHistoryEntry historyEntry;
}

final allPostsProvider = Provider<List<PostModel>>((ref) {
  final feedState = ref.watch(blogFeedProvider);
  return feedState.maybeWhen(
    data: (posts) => posts,
    orElse: () => const [],
  );
});

final publishedPostsProvider = Provider<List<PostModel>>((ref) {
  return ref.watch(allPostsProvider).where((post) => post.isPublished).toList();
});

final myPostsProvider = Provider<List<PostModel>>((ref) {
  final userId = _safeCurrentUserId();
  if (userId == null) {
    return const [];
  }

  return ref
      .watch(allPostsProvider)
      .where((post) => post.userId == userId)
      .toList();
});

final bookmarkedPostsProvider = Provider<List<PostModel>>((ref) {
  return ref
      .watch(allPostsProvider)
      .where((post) => post.isBookmarkedByMe)
      .toList();
});

final draftPostsProvider = Provider<List<PostModel>>((ref) {
  return ref.watch(myPostsProvider).where((post) => !post.isPublished).toList();
});

final trendingPostsProvider = Provider<List<PostModel>>((ref) {
  final posts = [...ref.watch(publishedPostsProvider)];
  posts.sort(
      (first, second) => _trendScore(second).compareTo(_trendScore(first)));
  return posts.take(10).toList();
});

final recommendedPostsProvider = Provider<List<PostModel>>((ref) {
  final posts = ref.watch(publishedPostsProvider);
  if (posts.isEmpty) {
    return const [];
  }

  final preferenceSeed =
      posts.where((post) => post.isBookmarkedByMe || post.isLikedByMe).toList();

  if (preferenceSeed.isEmpty) {
    return ref.watch(trendingPostsProvider);
  }

  final favoriteAuthors = preferenceSeed.map((post) => post.authorName).toSet();
  final favoriteTopics = preferenceSeed
      .expand((post) => PostInsights.extractTopics(post))
      .map((topic) => topic.toLowerCase())
      .toSet();

  final ranked = [...posts]..sort((first, second) {
      final firstScore = _recommendationScore(
        post: first,
        favoriteAuthors: favoriteAuthors,
        favoriteTopics: favoriteTopics,
      );
      final secondScore = _recommendationScore(
        post: second,
        favoriteAuthors: favoriteAuthors,
        favoriteTopics: favoriteTopics,
      );
      return secondScore.compareTo(firstScore);
    });

  return ranked.take(10).toList();
});

final featuredPostProvider = Provider<PostModel?>((ref) {
  final recommended = ref.watch(recommendedPostsProvider);
  if (recommended.isNotEmpty) {
    return recommended.first;
  }

  final trending = ref.watch(trendingPostsProvider);
  if (trending.isNotEmpty) {
    return trending.first;
  }

  final posts = ref.watch(publishedPostsProvider);
  return posts.isNotEmpty ? posts.first : null;
});

final relatedPostsProvider =
    Provider.family<List<PostModel>, String>((ref, postId) {
  final posts = ref.watch(publishedPostsProvider);
  final currentPost = posts.cast<PostModel?>().firstWhere(
        (post) => post?.id == postId,
        orElse: () => null,
      );

  if (currentPost == null) {
    return const [];
  }

  final candidates = posts.where((post) => post.id != postId).toList();
  candidates.sort((first, second) {
    final firstScore = _relatedScore(currentPost, first);
    final secondScore = _relatedScore(currentPost, second);
    return secondScore.compareTo(firstScore);
  });

  return candidates.take(3).toList();
});

final topTopicsProvider = Provider<List<TopicInsight>>((ref) {
  final posts = ref.watch(publishedPostsProvider);
  final counts = <String, int>{};

  for (final post in posts) {
    for (final topic in PostInsights.extractTopics(post)) {
      counts.update(topic, (value) => value + 1, ifAbsent: () => 1);
    }
  }

  final topics = counts.entries
      .map((entry) => TopicInsight(label: entry.key, mentions: entry.value))
      .toList()
    ..sort((first, second) {
      final byMentions = second.mentions.compareTo(first.mentions);
      return byMentions != 0 ? byMentions : first.label.compareTo(second.label);
    });

  return topics.take(8).toList();
});

final topAuthorsProvider = Provider<List<AuthorInsight>>((ref) {
  final posts = ref.watch(publishedPostsProvider);
  final grouped = <String, List<PostModel>>{};

  for (final post in posts) {
    grouped.putIfAbsent(post.userId, () => []).add(post);
  }

  final authors = grouped.entries.map((entry) {
    final firstPost = entry.value.first;
    final totalLikes =
        entry.value.fold<int>(0, (sum, post) => sum + post.likesCount);
    return AuthorInsight(
      userId: entry.key,
      name: firstPost.authorName,
      storyCount: entry.value.length,
      totalLikes: totalLikes,
    );
  }).toList()
    ..sort((first, second) {
      final byLikes = second.totalLikes.compareTo(first.totalLikes);
      if (byLikes != 0) {
        return byLikes;
      }
      return second.storyCount.compareTo(first.storyCount);
    });

  return authors.take(5).toList();
});

final writerDashboardStatsProvider = Provider<WriterDashboardStats>((ref) {
  final myPosts = ref.watch(myPostsProvider);
  final savedPosts = ref.watch(bookmarkedPostsProvider);

  final publishedPosts = myPosts.where((post) => post.isPublished).toList();
  final draftPosts = myPosts.where((post) => !post.isPublished).toList();

  final totalLikes =
      publishedPosts.fold<int>(0, (sum, post) => sum + post.likesCount);
  final totalWords = myPosts.fold<int>(
      0, (sum, post) => sum + PostInsights.wordCount(post.content));

  PostModel? topStory;
  if (publishedPosts.isNotEmpty) {
    final ranked = [...publishedPosts]
      ..sort((first, second) => second.likesCount.compareTo(first.likesCount));
    topStory = ranked.first;
  }

  return WriterDashboardStats(
    publishedCount: publishedPosts.length,
    draftCount: draftPosts.length,
    savedCount: savedPosts.length,
    totalLikes: totalLikes,
    totalWords: totalWords,
    currentStreak: _publishingStreak(publishedPosts),
    topStory: topStory,
  );
});

final continueReadingItemsProvider = Provider<List<ReadingResumeItem>>((ref) {
  final posts = ref.watch(allPostsProvider);
  final history = ref.watch(continueReadingProvider);
  final postsById = {for (final post in posts) post.id: post};

  return history
      .where((entry) => postsById.containsKey(entry.postId))
      .map(
        (entry) => ReadingResumeItem(
          post: postsById[entry.postId]!,
          historyEntry: entry,
        ),
      )
      .toList();
});

final recentReadingItemsProvider = Provider<List<ReadingResumeItem>>((ref) {
  final posts = ref.watch(allPostsProvider);
  final history = ref.watch(recentReadingProvider);
  final postsById = {for (final post in posts) post.id: post};

  return history
      .where((entry) => postsById.containsKey(entry.postId))
      .map(
        (entry) => ReadingResumeItem(
          post: postsById[entry.postId]!,
          historyEntry: entry,
        ),
      )
      .toList();
});

String? _safeCurrentUserId() {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}

double _trendScore(PostModel post) {
  final hoursOld = max(1, DateTime.now().difference(post.createdAt).inHours);
  final freshnessBoost = 120 / hoursOld;
  return (post.likesCount * 8) + freshnessBoost;
}

double _recommendationScore({
  required PostModel post,
  required Set<String> favoriteAuthors,
  required Set<String> favoriteTopics,
}) {
  final postTopics = PostInsights.extractTopics(post)
      .map((topic) => topic.toLowerCase())
      .toSet();
  final sharedTopics = postTopics.intersection(favoriteTopics).length;

  return _trendScore(post) +
      (favoriteAuthors.contains(post.authorName) ? 18 : 0) +
      (sharedTopics * 6) +
      (post.isBookmarkedByMe ? -12 : 0);
}

double _relatedScore(PostModel currentPost, PostModel candidate) {
  final sharedTopics = PostInsights.sharedTopicCount(currentPost, candidate);
  final sameAuthor = currentPost.authorName == candidate.authorName ? 10 : 0;
  return sameAuthor + (sharedTopics * 5) + _trendScore(candidate);
}

int _publishingStreak(List<PostModel> posts) {
  if (posts.isEmpty) {
    return 0;
  }

  final uniqueDays = posts
      .map((post) => DateTime(
          post.createdAt.year, post.createdAt.month, post.createdAt.day))
      .toSet()
      .toList()
    ..sort((first, second) => second.compareTo(first));

  final today = DateTime.now();
  var currentDay = DateTime(today.year, today.month, today.day);
  var streak = 0;

  final firstDay = uniqueDays.first;
  final startsRecently = currentDay.difference(firstDay).inDays <= 1;
  if (!startsRecently) {
    return 0;
  }

  for (final day in uniqueDays) {
    if (currentDay.difference(day).inDays == 0) {
      streak += 1;
      currentDay = currentDay.subtract(const Duration(days: 1));
      continue;
    }

    if (currentDay.difference(day).inDays == 1 && streak == 0) {
      streak += 1;
      currentDay = day.subtract(const Duration(days: 1));
      continue;
    }

    break;
  }

  return streak;
}
