import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/features/social/models/direct_message_model.dart';
import 'package:blog_app/features/social/models/friendship_model.dart';
import 'package:blog_app/features/social/providers/social_provider.dart';

class SocialNotificationSnapshot {
  const SocialNotificationSnapshot({
    required this.pendingRequests,
    required this.unreadThreads,
  });

  const SocialNotificationSnapshot.empty()
      : pendingRequests = const [],
        unreadThreads = const [];

  final List<FriendshipModel> pendingRequests;
  final List<ChatThreadModel> unreadThreads;

  int get pendingRequestCount => pendingRequests.length;
  int get unreadMessageCount => unreadThreads.length;
  int get totalCount => pendingRequestCount + unreadMessageCount;

  Set<String> get pendingRequestIds =>
      pendingRequests.map((request) => request.id).toSet();

  Set<String> get unreadThreadUserIds =>
      unreadThreads.map((thread) => thread.otherUser.id).toSet();

  FriendshipModel? requestById(String id) {
    for (final request in pendingRequests) {
      if (request.id == id) {
        return request;
      }
    }
    return null;
  }

  ChatThreadModel? threadByUserId(String userId) {
    for (final thread in unreadThreads) {
      if (thread.otherUser.id == userId) {
        return thread;
      }
    }
    return null;
  }
}

class SocialNotificationsNotifier
    extends StateNotifier<AsyncValue<SocialNotificationSnapshot>> {
  SocialNotificationsNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _loadReadMarkers();
    unawaited(refresh());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(refresh()),
    );
  }

  static const String _boxName = 'settings_box';
  static const String _threadReadMarkersKey = 'social_thread_read_markers';

  final SocialRepository _repository;
  final Map<String, DateTime> _threadReadMarkers = {};
  Timer? _refreshTimer;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  void _loadReadMarkers() {
    final box = Hive.box<dynamic>(_boxName);
    final raw = box.get(_threadReadMarkersKey);
    if (raw is! Map) {
      return;
    }

    for (final entry in raw.entries) {
      final key = entry.key?.toString();
      final value = entry.value?.toString();
      if (key == null || key.isEmpty || value == null || value.isEmpty) {
        continue;
      }
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        _threadReadMarkers[key] = parsed.toUtc();
      }
    }
  }

  Future<void> _persistReadMarkers() async {
    final box = Hive.box<dynamic>(_boxName);
    await box.put(
      _threadReadMarkersKey,
      {
        for (final entry in _threadReadMarkers.entries)
          entry.key: entry.value.toIso8601String(),
      },
    );
  }

  Future<void> refresh() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      if (mounted) {
        state = const AsyncValue.data(SocialNotificationSnapshot.empty());
      }
      return;
    }

    try {
      final backend = await _repository.checkBackend();
      if (!mounted) {
        return;
      }
      if (!backend.isConfigured) {
        state = const AsyncValue.data(SocialNotificationSnapshot.empty());
        return;
      }

      final friendships = await _repository.fetchFriendships();
      final threads = await _repository.fetchChatThreads();
      if (!mounted) {
        return;
      }

      final pendingRequests = friendships
          .where((friendship) => friendship.isPendingFor(currentUserId))
          .toList();
      final unreadThreads = threads.where((thread) {
        final lastMessage = thread.lastMessage;
        if (lastMessage.recipientId != currentUserId) {
          return false;
        }

        final lastReadAt = _threadReadMarkers[thread.otherUser.id];
        if (lastReadAt == null) {
          return true;
        }
        return lastMessage.createdAt.isAfter(lastReadAt);
      }).toList();

      state = AsyncValue.data(
        SocialNotificationSnapshot(
          pendingRequests: pendingRequests,
          unreadThreads: unreadThreads,
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markThreadRead(String otherUserId) async {
    if (otherUserId.isEmpty) {
      return;
    }

    _threadReadMarkers[otherUserId] = DateTime.now().toUtc();
    await _persistReadMarkers();
    if (!mounted) {
      return;
    }

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        SocialNotificationSnapshot(
          pendingRequests: current.pendingRequests,
          unreadThreads: current.unreadThreads
              .where((thread) => thread.otherUser.id != otherUserId)
              .toList(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final socialNotificationsProvider = StateNotifierProvider<
    SocialNotificationsNotifier, AsyncValue<SocialNotificationSnapshot>>((ref) {
  return SocialNotificationsNotifier(
    ref.read(socialRepositoryProvider),
  );
});
