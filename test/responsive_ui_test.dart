import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blog_app/features/blog/models/post_model.dart';
import 'package:blog_app/features/blog/providers/blog_provider.dart';
import 'package:blog_app/features/blog/screens/create_post_screen.dart';
import 'package:blog_app/features/home/screens/home_screen.dart';
import 'package:blog_app/features/search/screens/search_screen.dart';
import 'package:blog_app/features/settings/screens/settings_screen.dart';
import 'package:blog_app/theme/app_theme.dart';

import 'test_bootstrap.dart';

class _StaticBlogFeedNotifier extends BlogFeedNotifier {
  _StaticBlogFeedNotifier(this.posts) : super() {
    state = AsyncValue.data(posts);
  }

  final List<PostModel> posts;

  @override
  Future<void> fetchPosts() async {
    state = AsyncValue.data(posts);
  }
}

void main() {
  setUpAll(() async {
    await ensureTestStorageReady();
  });

  tearDownAll(() async {
    await closeTestStorage();
  });

  testWidgets('Home screen stays stable on a narrow light phone',
      (tester) async {
    await _pumpScreen(
      tester,
      const HomeScreen(),
      size: const Size(390, 844),
      themeMode: ThemeMode.light,
      overrides: [
        blogFeedProvider.overrideWith(
          (ref) => _StaticBlogFeedNotifier(_samplePosts),
        ),
      ],
    );

    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Inkwell'), findsOneWidget);
    expect(find.text('A calmer reading desk for your daily feed.'),
        findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search screen responds cleanly on a dark desktop',
      (tester) async {
    await _pumpScreen(
      tester,
      const SearchScreen(),
      size: const Size(1440, 960),
      themeMode: ThemeMode.dark,
      overrides: [
        blogFeedProvider.overrideWith(
          (ref) => _StaticBlogFeedNotifier(_samplePosts),
        ),
      ],
    );

    await tester.enterText(find.byType(TextField).first, 'riverpod');
    await tester.pump(const Duration(milliseconds: 240));
    await tester.pumpAndSettle();

    expect(
      find.text('Riverpod patterns for calmer Flutter state'),
      findsOneWidget,
    );
    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings screen remains readable on a compact viewport',
      (tester) async {
    await _pumpScreen(
      tester,
      const SettingsScreen(),
      size: const Size(360, 780),
      themeMode: ThemeMode.light,
      overrides: [
        blogFeedProvider.overrideWith(
          (ref) => _StaticBlogFeedNotifier(_samplePosts),
        ),
      ],
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(find.text('Appearance'), 300);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Default reading size'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create post studio lays out correctly on wide desktop',
      (tester) async {
    await _pumpScreen(
      tester,
      const CreatePostScreen(),
      size: const Size(1366, 900),
      themeMode: ThemeMode.dark,
    );

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Story Studio'), findsOneWidget);
    expect(find.text('Publishing mode'), findsOneWidget);
    expect(find.text('Writing insights'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget child, {
  required Size size,
  required ThemeMode themeMode,
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: child,
      ),
    ),
  );

  await tester.pump();
}

final _samplePosts = <PostModel>[
  PostModel(
    id: 'post-riverpod',
    title: 'Riverpod patterns for calmer Flutter state',
    content: '''
# Riverpod

Riverpod helps keep state clear across mobile and desktop layouts.

Use providers to keep screens predictable and easier to test.

This story also mentions responsive layouts, dark mode, and clean navigation.
''',
    createdAt: DateTime(2026, 3, 28, 10, 30),
    authorName: 'zain',
    userId: 'writer-1',
    isPublished: true,
    likesCount: 16,
    isBookmarkedByMe: true,
  ),
  PostModel(
    id: 'post-design',
    title: 'Designing a blog experience for every screen',
    content: '''
Responsive design starts with readable spacing, clear contrast, and predictable controls.

Desktop readers need structure while phone readers need fast scanning.

Dark theme and light theme should both feel deliberate and comfortable.
''',
    createdAt: DateTime(2026, 3, 27, 14, 10),
    authorName: 'maria',
    userId: 'writer-2',
    isPublished: true,
    likesCount: 8,
  ),
];
