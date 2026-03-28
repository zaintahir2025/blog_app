import 'package:blog_app/features/profile/models/user_profile_model.dart';

enum FriendshipStatus { pending, accepted, blocked }

class FriendshipModel {
  const FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.requester,
    required this.addressee,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfileModel requester;
  final UserProfileModel addressee;

  bool isPendingFor(String userId) =>
      status == FriendshipStatus.pending && addresseeId == userId;

  bool isOutgoingFor(String userId) =>
      status == FriendshipStatus.pending && requesterId == userId;

  bool isFriendFor(String userId) =>
      status == FriendshipStatus.accepted &&
      (requesterId == userId || addresseeId == userId);

  UserProfileModel otherUser(String currentUserId) {
    return requesterId == currentUserId ? addressee : requester;
  }

  factory FriendshipModel.fromJson(
    Map<String, dynamic> json, {
    required UserProfileModel requester,
    required UserProfileModel addressee,
  }) {
    return FriendshipModel(
      id: json['id'] as String? ?? '',
      requesterId: json['requester_id'] as String? ?? '',
      addresseeId: json['addressee_id'] as String? ?? '',
      status: switch (json['status'] as String? ?? 'pending') {
        'accepted' => FriendshipStatus.accepted,
        'blocked' => FriendshipStatus.blocked,
        _ => FriendshipStatus.pending,
      },
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      requester: requester,
      addressee: addressee,
    );
  }
}
