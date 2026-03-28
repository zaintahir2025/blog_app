import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blog_app/features/blog/models/post_model.dart';

class BlogFeedNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  BlogFeedNotifier() : super(const AsyncValue.loading()) {
    fetchPosts();
  }

  static Box<dynamic> get _postsBox => Hive.box<dynamic>('posts_box');

  Future<void> _persistPosts(List<PostModel> posts) async {
    await _postsBox.clear();
    await _postsBox.addAll(posts);
  }

  Future<String> uploadStoryImage({
    File? imageFile,
    Uint8List? webImageBytes,
    String prefix = 'story_assets',
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw 'Not logged in';
    }

    if (imageFile == null && webImageBytes == null) {
      throw 'No image selected';
    }

    final filePath =
        '$prefix/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (kIsWeb && webImageBytes != null) {
      await Supabase.instance.client.storage.from('blog_images').uploadBinary(
            filePath,
            webImageBytes,
            fileOptions: const FileOptions(
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );
    } else if (imageFile != null) {
      await Supabase.instance.client.storage.from('blog_images').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );
    }

    return Supabase.instance.client.storage
        .from('blog_images')
        .getPublicUrl(filePath);
  }

  Future<void> fetchPosts() async {
    try {
      final box = _postsBox;
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

      if (box.isNotEmpty) {
        final cachedPosts = sortPosts(
          box.values
              .whereType<PostModel>()
              .where((post) => canAccessPost(post, currentUserId)),
        );
        if (cachedPosts.isNotEmpty) {
          state = AsyncValue.data(cachedPosts);
        }
      }

      final response = await Supabase.instance.client
          .from('posts')
          .select('*, profiles(username), likes(user_id), bookmarks(user_id)')
          .order('created_at', ascending: false);

      final List<PostModel> freshPosts = sortPosts(
        response.map((json) => PostModel.fromJson(json, currentUserId)),
      );

      await _persistPosts(freshPosts);
      state = AsyncValue.data(freshPosts);
    } catch (e, stackTrace) {
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<PostModel?> fetchPostById(String postId) async {
    final localPosts = state.value ?? const [];
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final localMatch = localPosts.cast<PostModel?>().firstWhere(
          (post) => post?.id == postId,
          orElse: () => null,
        );
    if (localMatch != null) {
      return canAccessPost(localMatch, currentUserId) ? localMatch : null;
    }

    final response = await Supabase.instance.client
        .from('posts')
        .select('*, profiles(username), likes(user_id), bookmarks(user_id)')
        .eq('id', postId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final post = PostModel.fromJson(
      Map<String, dynamic>.from(response),
      currentUserId,
    );
    if (!canAccessPost(post, currentUserId)) {
      return null;
    }

    final updatedPosts = mergePostIntoFeed(localPosts, post);
    state = AsyncValue.data(updatedPosts);
    await _persistPosts(updatedPosts);
    return post;
  }

  Future<void> toggleLike(String postId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final currentPosts = state.value ?? [];
    final postIndex = currentPosts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentPosts[postIndex];
    final wasLiked = post.isLikedByMe;

    final updatedPosts = List<PostModel>.from(currentPosts);
    updatedPosts[postIndex] = post.copyWith(
      isLikedByMe: !wasLiked,
      likesCount: post.likesCount + (wasLiked ? -1 : 1),
    );
    state = AsyncValue.data(updatedPosts);

    try {
      if (wasLiked) {
        await Supabase.instance.client
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        await Supabase.instance.client
            .from('likes')
            .insert({'post_id': postId, 'user_id': user.id});
      }

      await _persistPosts(updatedPosts);
    } catch (e) {
      state = AsyncValue.data(currentPosts);
    }
  }

  Future<void> toggleBookmark(String postId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final currentPosts = state.value ?? [];
    final postIndex = currentPosts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentPosts[postIndex];
    final wasBookmarked = post.isBookmarkedByMe;

    final updatedPosts = List<PostModel>.from(currentPosts);
    updatedPosts[postIndex] = post.copyWith(isBookmarkedByMe: !wasBookmarked);
    state = AsyncValue.data(updatedPosts);

    try {
      if (wasBookmarked) {
        await Supabase.instance.client
            .from('bookmarks')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        await Supabase.instance.client
            .from('bookmarks')
            .insert({'post_id': postId, 'user_id': user.id});
      }

      await _persistPosts(updatedPosts);
    } catch (e) {
      state = AsyncValue.data(currentPosts);
    }
  }

  Future<void> addPost(
      {required String title,
      required String content,
      required bool isPublished,
      File? imageFile,
      Uint8List? webImageBytes}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'Not logged in';

      String? imageUrl;
      if (imageFile != null || webImageBytes != null) {
        imageUrl = await uploadStoryImage(
          imageFile: imageFile,
          webImageBytes: webImageBytes,
          prefix: 'covers',
        );
      }

      await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'title': title.trim(),
        'content': content.trim(),
        'cover_image_url': imageUrl,
        'is_published': isPublished,
      });
      await fetchPosts();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> editPost(
      {required String postId,
      required String title,
      required String content,
      required bool isPublished,
      bool removeCoverImage = false,
      File? newImageFile,
      Uint8List? webImageBytes,
      String? existingImageUrl}) async {
    try {
      String? finalImageUrl = removeCoverImage ? null : existingImageUrl;

      if (newImageFile != null || webImageBytes != null) {
        finalImageUrl = await uploadStoryImage(
          imageFile: newImageFile,
          webImageBytes: webImageBytes,
          prefix: 'covers',
        );
      }

      await Supabase.instance.client.from('posts').update({
        'title': title.trim(),
        'content': content.trim(),
        'cover_image_url': finalImageUrl,
        'is_published': isPublished,
      }).eq('id', postId);

      await fetchPosts();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> togglePublish(String postId, bool currentStatus) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .update({'is_published': !currentStatus}).eq('id', postId);
      await fetchPosts();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await Supabase.instance.client.from('posts').delete().eq('id', postId);
      await fetchPosts();
    } catch (e) {
      throw e.toString();
    }
  }
}

final blogFeedProvider =
    StateNotifierProvider<BlogFeedNotifier, AsyncValue<List<PostModel>>>((ref) {
  return BlogFeedNotifier();
});

final postByIdProvider = FutureProvider.family<PostModel?, String>((
  ref,
  postId,
) async {
  final feedState = ref.watch(blogFeedProvider);
  final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final localPost = feedState.valueOrNull?.cast<PostModel?>().firstWhere(
        (post) => post?.id == postId,
        orElse: () => null,
      );
  if (localPost != null) {
    return canAccessPost(localPost, currentUserId) ? localPost : null;
  }

  return ref.read(blogFeedProvider.notifier).fetchPostById(postId);
});

@visibleForTesting
bool canAccessPost(PostModel post, String currentUserId) {
  return post.isPublished ||
      (currentUserId.isNotEmpty && post.userId == currentUserId);
}

@visibleForTesting
List<PostModel> mergePostIntoFeed(List<PostModel> posts, PostModel post) {
  return sortPosts([
    post,
    ...posts.where((existingPost) => existingPost.id != post.id),
  ]);
}

@visibleForTesting
List<PostModel> sortPosts(Iterable<PostModel> posts) {
  final sorted = posts.toList()
    ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
  return sorted;
}
