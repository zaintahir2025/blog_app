import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/features/profile/models/user_profile_model.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<UserProfileModel?> fetchUserProfile(String userId) async {
    final List<dynamic> response = await _client
        .from('profiles')
        .select('id, username, full_name')
        .eq('id', userId)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return UserProfileModel.fromJson(
      Map<String, dynamic>.from(response.first as Map),
      avatarUrl: profileAvatarUrl(userId),
    );
  }

  Future<List<UserProfileModel>> fetchUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const [];
    }

    final List<dynamic> response = await _client
        .from('profiles')
        .select('id, username, full_name')
        .inFilter('id', userIds);

    final users = response
        .map(
          (row) => UserProfileModel.fromJson(
            Map<String, dynamic>.from(row as Map),
            avatarUrl: profileAvatarUrl((row)['id'] as String? ?? ''),
          ),
        )
        .toList();

    users.sort(
      (first, second) => first.displayName.compareTo(second.displayName),
    );
    return users;
  }

  Future<Map<String, dynamic>?> fetchCurrentProfileData() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final List<dynamic> response = await _client
        .from('profiles')
        .select('id, username, full_name')
        .eq('id', user.id)
        .limit(1);

    if (response.isEmpty) {
      return {
        'id': user.id,
        'username': (user.email ?? 'writer').split('@').first,
        'full_name': user.userMetadata?['full_name'] ?? '',
      };
    }

    return Map<String, dynamic>.from(response.first as Map);
  }

  Future<String> uploadAvatar({
    required String userId,
    File? imageFile,
    Uint8List? webImageBytes,
  }) async {
    final path = 'avatars/$userId/avatar.jpg';

    if (kIsWeb && webImageBytes != null) {
      await _client.storage.from('blog_images').uploadBinary(
            path,
            webImageBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
    } else if (imageFile != null) {
      await _client.storage.from('blog_images').upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
    } else {
      throw 'No image selected.';
    }

    return profileAvatarUrl(
      userId,
      cacheBuster: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final currentUserProfileDataProvider = FutureProvider<Map<String, dynamic>?>(
  (ref) async {
    return ref.read(profileRepositoryProvider).fetchCurrentProfileData();
  },
);

final publicProfileProvider =
    FutureProvider.family<UserProfileModel?, String>((ref, userId) async {
  return ref.read(profileRepositoryProvider).fetchUserProfile(userId);
});
