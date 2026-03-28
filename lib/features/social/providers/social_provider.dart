import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/features/profile/providers/profile_provider.dart';
import 'package:blog_app/features/social/models/direct_message_model.dart';
import 'package:blog_app/features/social/models/friendship_model.dart';

class SocialBackendStatus {
  const SocialBackendStatus({
    required this.isConfigured,
    this.message,
  });

  final bool isConfigured;
  final String? message;
}

class SocialRepository {
  SocialRepository(
    this._client,
    this._profileRepository,
  );

  final SupabaseClient _client;
  final ProfileRepository _profileRepository;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<SocialBackendStatus> checkBackend() async {
    try {
      await _client.from('friendships').select('id').limit(1);
      await _client.from('direct_messages').select('id').limit(1);
      return const SocialBackendStatus(isConfigured: true);
    } catch (_) {
      return const SocialBackendStatus(
        isConfigured: false,
        message:
            'Social tables are not configured yet. Apply supabase/social_features_schema.sql to enable friends and chat.',
      );
    }
  }

  Future<List<FriendshipModel>> fetchFriendships() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return const [];
    }

    final List<dynamic> response = await _client
        .from('friendships')
        .select()
        .or('requester_id.eq.$currentUserId,addressee_id.eq.$currentUserId')
        .order('updated_at', ascending: false);

    if (response.isEmpty) {
      return const [];
    }

    final userIds = <String>{
      for (final row in response) (row as Map)['requester_id'] as String? ?? '',
      for (final row in response) (row as Map)['addressee_id'] as String? ?? '',
    }..remove('');

    final profiles = await _profileRepository.fetchUsersByIds(userIds.toList());
    final profilesById = {for (final profile in profiles) profile.id: profile};

    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .where(
          (row) =>
              profilesById.containsKey(row['requester_id']) &&
              profilesById.containsKey(row['addressee_id']),
        )
        .map(
          (row) => FriendshipModel.fromJson(
            row,
            requester: profilesById[row['requester_id']]!,
            addressee: profilesById[row['addressee_id']]!,
          ),
        )
        .toList();
  }

  Future<FriendshipModel?> fetchFriendshipWithUser(String otherUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return null;
    }

    final List<dynamic> response = await _client
        .from('friendships')
        .select()
        .or(
          'and(requester_id.eq.$currentUserId,addressee_id.eq.$otherUserId),and(requester_id.eq.$otherUserId,addressee_id.eq.$currentUserId)',
        )
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    final row = Map<String, dynamic>.from(response.first as Map);
    final profiles = await _profileRepository.fetchUsersByIds([
      row['requester_id'] as String? ?? '',
      row['addressee_id'] as String? ?? '',
    ]);
    final profilesById = {for (final profile in profiles) profile.id: profile};
    if (!profilesById.containsKey(row['requester_id']) ||
        !profilesById.containsKey(row['addressee_id'])) {
      return null;
    }

    return FriendshipModel.fromJson(
      row,
      requester: profilesById[row['requester_id']]!,
      addressee: profilesById[row['addressee_id']]!,
    );
  }

  Future<void> sendFriendRequest(String otherUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw 'You must be logged in to add friends.';
    }
    if (currentUserId == otherUserId) {
      throw 'You cannot add yourself.';
    }

    final existing = await fetchFriendshipWithUser(otherUserId);
    if (existing != null) {
      throw 'A friendship already exists for this user.';
    }

    await _client.from('friendships').insert({
      'requester_id': currentUserId,
      'addressee_id': otherUserId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await _client
        .from('friendships')
        .update({'status': 'accepted'}).eq('id', friendshipId);
  }

  Future<void> declineFriendRequest(String friendshipId) async {
    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  Future<void> removeFriend(String friendshipId) async {
    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  Future<List<FriendshipModel>> fetchAcceptedFriendshipsForUser(
    String userId,
  ) async {
    if (userId.isEmpty) {
      return const [];
    }

    final List<dynamic> response = await _client
        .from('friendships')
        .select()
        .eq('status', 'accepted')
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .order('updated_at', ascending: false);

    if (response.isEmpty) {
      return const [];
    }

    final userIds = <String>{
      for (final row in response) (row as Map)['requester_id'] as String? ?? '',
      for (final row in response) (row as Map)['addressee_id'] as String? ?? '',
    }..remove('');

    final profiles = await _profileRepository.fetchUsersByIds(userIds.toList());
    final profilesById = {for (final profile in profiles) profile.id: profile};

    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .where(
          (row) =>
              profilesById.containsKey(row['requester_id']) &&
              profilesById.containsKey(row['addressee_id']),
        )
        .map(
          (row) => FriendshipModel.fromJson(
            row,
            requester: profilesById[row['requester_id']]!,
            addressee: profilesById[row['addressee_id']]!,
          ),
        )
        .toList();
  }

  Future<List<DirectMessageModel>> fetchMessages(String otherUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return const [];
    }

    final List<dynamic> response = await _client
        .from('direct_messages')
        .select()
        .or(
          'and(sender_id.eq.$currentUserId,recipient_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,recipient_id.eq.$currentUserId)',
        )
        .order('created_at', ascending: true);

    if (response.isEmpty) {
      return const [];
    }

    final senderIds = response
        .map((row) => (row as Map)['sender_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final profiles = await _profileRepository.fetchUsersByIds(senderIds);
    final profilesById = {for (final profile in profiles) profile.id: profile};

    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .where((row) => profilesById.containsKey(row['sender_id']))
        .map(
          (row) => DirectMessageModel.fromJson(
            row,
            sender: profilesById[row['sender_id']]!,
          ),
        )
        .toList();
  }

  Future<List<ChatThreadModel>> fetchChatThreads() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return const [];
    }

    final List<dynamic> response = await _client
        .from('direct_messages')
        .select()
        .or('sender_id.eq.$currentUserId,recipient_id.eq.$currentUserId')
        .order('created_at', ascending: false);

    if (response.isEmpty) {
      return const [];
    }

    final allMessages =
        response.map((row) => Map<String, dynamic>.from(row as Map));
    final profileIds = <String>{
      for (final row in allMessages) row['sender_id'] as String? ?? '',
      for (final row in allMessages) row['recipient_id'] as String? ?? '',
    }..remove('');
    final profiles =
        await _profileRepository.fetchUsersByIds(profileIds.toList());
    final profilesById = {for (final profile in profiles) profile.id: profile};

    final threadsByUser = <String, ChatThreadModel>{};
    for (final row in allMessages) {
      final senderId = row['sender_id'] as String? ?? '';
      final recipientId = row['recipient_id'] as String? ?? '';
      final otherUserId = senderId == currentUserId ? recipientId : senderId;
      if (otherUserId.isEmpty ||
          !profilesById.containsKey(otherUserId) ||
          !profilesById.containsKey(senderId) ||
          threadsByUser.containsKey(otherUserId)) {
        continue;
      }

      final message = DirectMessageModel.fromJson(
        row,
        sender: profilesById[senderId]!,
      );
      threadsByUser[otherUserId] = ChatThreadModel(
        otherUser: profilesById[otherUserId]!,
        lastMessage: message,
      );
    }

    return threadsByUser.values.toList();
  }

  Future<void> sendMessage({
    required String recipientId,
    required String content,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw 'You must be logged in to send a message.';
    }
    if (content.trim().isEmpty) {
      return;
    }

    await _client.from('direct_messages').insert({
      'sender_id': currentUserId,
      'recipient_id': recipientId,
      'content': content.trim(),
    });
  }
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(
    Supabase.instance.client,
    ref.read(profileRepositoryProvider),
  );
});

final socialBackendProvider = FutureProvider<SocialBackendStatus>((ref) async {
  return ref.read(socialRepositoryProvider).checkBackend();
});

final friendshipsProvider = FutureProvider<List<FriendshipModel>>((ref) async {
  final backend = await ref.watch(socialBackendProvider.future);
  if (!backend.isConfigured) {
    return const [];
  }
  return ref.read(socialRepositoryProvider).fetchFriendships();
});

final friendshipWithUserProvider =
    FutureProvider.family<FriendshipModel?, String>((ref, otherUserId) async {
  final backend = await ref.watch(socialBackendProvider.future);
  if (!backend.isConfigured) {
    return null;
  }
  return ref
      .read(socialRepositoryProvider)
      .fetchFriendshipWithUser(otherUserId);
});

final chatThreadsProvider = FutureProvider<List<ChatThreadModel>>((ref) async {
  final backend = await ref.watch(socialBackendProvider.future);
  if (!backend.isConfigured) {
    return const [];
  }
  return ref.read(socialRepositoryProvider).fetchChatThreads();
});

final chatMessagesProvider =
    FutureProvider.family<List<DirectMessageModel>, String>(
        (ref, otherUserId) async {
  final backend = await ref.watch(socialBackendProvider.future);
  if (!backend.isConfigured) {
    return const [];
  }
  return ref.read(socialRepositoryProvider).fetchMessages(otherUserId);
});

final publicFriendshipsProvider =
    FutureProvider.family<List<FriendshipModel>, String>((ref, userId) async {
  final backend = await ref.watch(socialBackendProvider.future);
  if (!backend.isConfigured) {
    return const [];
  }
  return ref
      .read(socialRepositoryProvider)
      .fetchAcceptedFriendshipsForUser(userId);
});
