class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String authorName;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.authorName,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    final username = _readString(profileData?['username']);
    final fullName = _readString(profileData?['full_name']);

    return CommentModel(
      id: _readString(json['id']) ?? '',
      postId: _readString(json['post_id']) ?? '',
      userId: _readString(json['user_id']) ?? '',
      content: _readString(json['text_content']) ??
          _readString(json['content']) ??
          '',
      createdAt: DateTime.tryParse(_readString(json['created_at']) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      authorName: username ?? fullName ?? 'Unknown Writer',
    );
  }
}

String? _readString(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  return text;
}
