import 'package:hive/hive.dart';

part 'post_model.g.dart';

@HiveType(typeId: 0)
class PostModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String content;
  @HiveField(3)
  final String? coverImageUrl;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final String authorName;
  @HiveField(6)
  final String userId;
  @HiveField(7)
  final bool isPublished;

  @HiveField(8)
  final int likesCount;
  @HiveField(9)
  final bool isLikedByMe;
  @HiveField(10)
  final bool isBookmarkedByMe;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.coverImageUrl,
    required this.createdAt,
    required this.authorName,
    required this.userId,
    required this.isPublished,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.isBookmarkedByMe = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final likesList = json['likes'] as List<dynamic>? ?? [];
    final bookmarksList = json['bookmarks'] as List<dynamic>? ?? [];
    final profileData = json['profiles'] as Map<String, dynamic>?;

    return PostModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      coverImageUrl: json['cover_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      authorName: profileData?['username'] ?? 'Unknown',
      userId: json['user_id'] ?? '',
      isPublished: json['is_published'] ?? true,
      likesCount: likesList.length,
      isLikedByMe: likesList.any((like) => like['user_id'] == currentUserId),
      isBookmarkedByMe:
          bookmarksList.any((bookmark) => bookmark['user_id'] == currentUserId),
    );
  }

  PostModel copyWith({
    String? title,
    String? content,
    String? coverImageUrl,
    bool? isPublished,
    int? likesCount,
    bool? isLikedByMe,
    bool? isBookmarkedByMe,
  }) {
    return PostModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt,
      authorName: authorName,
      userId: userId,
      isPublished: isPublished ?? this.isPublished,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isBookmarkedByMe: isBookmarkedByMe ?? this.isBookmarkedByMe,
    );
  }
}
