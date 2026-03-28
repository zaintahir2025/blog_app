import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// --- Screen Imports ---
import 'package:blog_app/features/auth/screens/splash_screen.dart';
import 'package:blog_app/features/auth/screens/login_screen.dart';
import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/screens/create_post_screen.dart';
import 'package:blog_app/features/blog/screens/edit_post_screen.dart';
import 'package:blog_app/features/blog/screens/post_detail_entry_screen.dart';
import 'package:blog_app/features/blog/screens/post_detail_screen.dart';
import 'package:blog_app/features/settings/screens/settings_screen.dart';
import 'package:blog_app/features/auth/screens/signup_screen.dart';
import 'package:blog_app/features/home/screens/main_layout.dart';
import 'package:blog_app/features/profile/screens/edit_profile_screen.dart';
import 'package:blog_app/features/profile/screens/public_profile_screen.dart';
import 'package:blog_app/features/search/screens/search_screen.dart';
import 'package:blog_app/features/social/screens/chat_screen.dart';
import 'package:blog_app/core/providers/app_preferences_provider.dart';
import 'package:blog_app/core/utils/app_scroll_behavior.dart';

import 'package:blog_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(PostModelAdapter().typeId)) {
    Hive.registerAdapter(PostModelAdapter());
  }

  await Future.wait([
    Hive.openBox('posts_box'),
    Hive.openBox('editor_box'),
    Hive.openBox('settings_box'),
    Hive.openBox('history_box'),
    Supabase.initialize(
      url: 'https://yffcigiiwcxavctvwbui.supabase.co',
      anonKey: 'sb_publishable_zF4HlT9oKAJGZ1WaNS5oqA_ijeUQKVR',
    ),
  ]);

  runApp(
    const ProviderScope(
      child: InkwellApp(),
    ),
  );
}

class InkwellApp extends ConsumerWidget {
  const InkwellApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);

    return MaterialApp.router(
      title: 'Inkwell',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'inkwell_app',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: preferences.themeMode,
      themeAnimationCurve: Curves.easeOutCubic,
      themeAnimationDuration: const Duration(milliseconds: 220),
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations:
                mediaQuery.disableAnimations || preferences.reducedMotion,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainLayout(),
    ),
    GoRoute(
      path: '/create_post',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/post_detail',
      builder: (context, state) {
        final post = state.extra;
        if (post is! PostModel) {
          return const _RouteErrorScreen(message: 'Story data was not found.');
        }
        return PostDetailScreen(post: post);
      },
    ),
    GoRoute(
      path: '/posts/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId'];
        if (postId == null || postId.isEmpty) {
          return const _RouteErrorScreen(message: 'Story data was not found.');
        }

        final initialPost =
            state.extra is PostModel ? state.extra as PostModel : null;
        return PostDetailEntryScreen(
          postId: postId,
          initialPost: initialPost?.id == postId ? initialPost : null,
          shareId: state.uri.queryParameters['share_id'],
          sharedByUserId: state.uri.queryParameters['shared_by'],
        );
      },
    ),
    GoRoute(
      path: '/discover',
      builder: (context, state) => SearchScreen(
        initialQuery: state.uri.queryParameters['q'],
      ),
    ),
    GoRoute(
      path: '/edit_post',
      builder: (context, state) {
        final post = state.extra;
        if (post is! PostModel) {
          return const _RouteErrorScreen(message: 'Post data was not found.');
        }
        return EditPostScreen(post: post);
      },
    ),
    GoRoute(
      path: '/edit_profile',
      builder: (context, state) {
        final profileData = state.extra;
        if (profileData is! Map<String, dynamic>) {
          return const _RouteErrorScreen(
              message: 'Profile data was not found.');
        }
        return EditProfileScreen(profileData: profileData);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/user/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        if (userId == null || userId.isEmpty) {
          return const _RouteErrorScreen(
              message: 'User profile was not found.');
        }
        return PublicProfileScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/chat/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        if (userId == null || userId.isEmpty) {
          return const _RouteErrorScreen(
            message: 'Conversation data was not found.',
          );
        }
        return ChatScreen(userId: userId);
      },
    ),
  ],
);

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_off_rounded,
                  size: 72,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This page is not available right now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Go to start'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Go back'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
