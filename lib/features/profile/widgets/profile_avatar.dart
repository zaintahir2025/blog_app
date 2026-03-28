import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String profileAvatarUrl(String userId, {String? cacheBuster}) {
  try {
    final path = 'avatars/$userId/avatar.jpg';
    final url =
        Supabase.instance.client.storage.from('blog_images').getPublicUrl(path);
    if (cacheBuster == null || cacheBuster.isEmpty) {
      return url;
    }
    return '$url?v=$cacheBuster';
  } catch (_) {
    return '';
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.userId,
    required this.fallbackLabel,
    this.radius = 18,
    this.cacheBuster,
  });

  final String userId;
  final String fallbackLabel;
  final double radius;
  final String? cacheBuster;

  @override
  Widget build(BuildContext context) {
    final url = profileAvatarUrl(userId, cacheBuster: cacheBuster);
    if (url.isEmpty) {
      return _FallbackAvatar(
        radius: radius,
        label: fallbackLabel,
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, __) => _FallbackAvatar(
          radius: radius,
          label: fallbackLabel,
        ),
        errorWidget: (_, __, ___) => _FallbackAvatar(
          radius: radius,
          label: fallbackLabel,
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.radius,
    required this.label,
  });

  final double radius;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
