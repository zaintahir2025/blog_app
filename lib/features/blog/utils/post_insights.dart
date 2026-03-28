import 'dart:math';

import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/utils/story_markup.dart';

class TopicInsight {
  const TopicInsight({
    required this.label,
    required this.mentions,
  });

  final String label;
  final int mentions;
}

class AuthorInsight {
  const AuthorInsight({
    required this.userId,
    required this.name,
    required this.storyCount,
    required this.totalLikes,
  });

  final String userId;
  final String name;
  final int storyCount;
  final int totalLikes;
}

class WriterDashboardStats {
  const WriterDashboardStats({
    required this.publishedCount,
    required this.draftCount,
    required this.savedCount,
    required this.totalLikes,
    required this.totalWords,
    required this.currentStreak,
    this.topStory,
  });

  final int publishedCount;
  final int draftCount;
  final int savedCount;
  final int totalLikes;
  final int totalWords;
  final int currentStreak;
  final PostModel? topStory;
}

class PostInsights {
  static const Set<String> _stopWords = {
    'about',
    'after',
    'again',
    'also',
    'always',
    'among',
    'because',
    'being',
    'between',
    'could',
    'every',
    'first',
    'from',
    'into',
    'just',
    'more',
    'most',
    'much',
    'only',
    'other',
    'over',
    'really',
    'some',
    'such',
    'than',
    'that',
    'their',
    'there',
    'these',
    'they',
    'this',
    'through',
    'today',
    'very',
    'what',
    'when',
    'where',
    'which',
    'while',
    'with',
    'would',
    'your',
    'story',
    'stories',
    'write',
    'writer',
  };

  static int wordCount(String text) {
    final words = plainText(text)
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    return words;
  }

  static int paragraphCount(String text) {
    return plainText(text)
        .split(RegExp(r'\n\s*\n'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .length;
  }

  static int estimatedReadMinutes(String text) {
    return max(1, (wordCount(text) / 180).ceil());
  }

  static String estimatedReadLabel(String text) {
    final minutes = estimatedReadMinutes(text);
    return '$minutes min read';
  }

  static String excerpt(String text, {int maxLength = 150}) {
    final normalized = plainText(text).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }

    return '${normalized.substring(0, maxLength).trimRight()}...';
  }

  static String plainText(String text) {
    return StoryMarkup.plainText(text);
  }

  static List<String> extractTopics(PostModel post, {int limit = 4}) {
    final scores = <String, int>{};

    void scoreText(String text, int weight) {
      for (final word in _tokenize(text)) {
        scores.update(word, (value) => value + weight, ifAbsent: () => weight);
      }
    }

    scoreText(post.title, 3);
    scoreText(post.content, 1);

    final sorted = scores.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    return sorted.take(limit).map((entry) => _toTitleCase(entry.key)).toList();
  }

  static int sharedTopicCount(PostModel first, PostModel second) {
    final firstTopics =
        extractTopics(first).map((topic) => topic.toLowerCase()).toSet();
    final secondTopics =
        extractTopics(second).map((topic) => topic.toLowerCase()).toSet();

    return firstTopics.intersection(secondTopics).length;
  }

  static String shortDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  static String relativeRecencyLabel(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 24) {
      return 'Today';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }

    return shortDate(dateTime);
  }

  static List<String> _tokenize(String text) {
    return plainText(text)
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) =>
            word.length > 3 && !_stopWords.contains(word) && word.isNotEmpty)
        .toList();
  }

  static String _toTitleCase(String input) {
    if (input.isEmpty) {
      return input;
    }
    return '${input[0].toUpperCase()}${input.substring(1)}';
  }
}
