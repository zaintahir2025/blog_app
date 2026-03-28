import 'package:blog_app/features/profile/models/user_profile_model.dart';

class DirectMessageModel {
  const DirectMessageModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
    required this.sender,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime createdAt;
  final UserProfileModel sender;

  bool isMine(String currentUserId) => senderId == currentUserId;

  factory DirectMessageModel.fromJson(
    Map<String, dynamic> json, {
    required UserProfileModel sender,
  }) {
    return DirectMessageModel(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sender: sender,
    );
  }
}

class ChatThreadModel {
  const ChatThreadModel({
    required this.otherUser,
    required this.lastMessage,
  });

  final UserProfileModel otherUser;
  final DirectMessageModel lastMessage;
}
