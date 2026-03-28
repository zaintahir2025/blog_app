import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/widgets/ink_surfaces.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _routeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _routeTimer = Timer(const Duration(milliseconds: 180), _routeUser);
    });
  }

  @override
  void dispose() {
    _routeTimer?.cancel();
    super.dispose();
  }

  void _routeUser() {
    if (!mounted) {
      return;
    }

    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      session = null;
    }

    if (session != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accentSurface = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : colorScheme.primary.withValues(alpha: 0.12);
    final accentForeground = isDark ? Colors.white : colorScheme.primary;
    final secondaryText =
        isDark ? Colors.white70 : colorScheme.onSurfaceVariant;

    return Scaffold(
      body: InkBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: InkHeroCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InkEyebrow(
                    label: 'Launching Inkwell',
                    icon: Icons.auto_stories_rounded,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: accentSurface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.draw_rounded,
                      size: 56,
                      color: accentForeground,
                    ),
                  )
                      .animate()
                      .scale(duration: 800.ms, curve: Curves.easeOutBack)
                      .then(delay: 150.ms)
                      .shimmer(
                        duration: 1000.ms,
                        color: accentForeground.withValues(alpha: 0.16),
                      ),
                  const SizedBox(height: 28),
                  Text(
                    'Inkwell',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ).animate().fade(delay: 320.ms, duration: 520.ms).slideY(
                        begin: 0.12,
                        end: 0,
                        duration: 520.ms,
                        curve: Curves.easeOutQuart,
                      ),
                  const SizedBox(height: 12),
                  Text(
                    'A more polished reading and writing studio is getting ready.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: secondaryText,
                        ),
                  ).animate().fade(delay: 620.ms, duration: 700.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
