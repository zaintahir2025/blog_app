# Development Checklist

Use this checklist when setting up, running, or changing the project.

## First Run

1. Install Flutter.
2. Run `flutter pub get`.
3. Confirm Supabase credentials in `lib/main.dart`.
4. Make sure the base Supabase tables exist:
   - `profiles`
   - `posts`
   - `likes`
   - `bookmarks`
   - `comments`
5. Make sure the `blog_images` storage bucket exists.
6. Run the app with `flutter run -d edge` or `flutter run -d chrome`.

## Optional Supabase Setup

Run these SQL files in Supabase if you want the full feature set:

- `supabase/social_features_schema.sql`
- `supabase/story_share_schema.sql`

Social features include friends, friend requests, chat threads, direct
messages, and notification badges.

Share tracking includes generated share events, attributed opens, and simple
share/open metrics for story authors.

## Before Committing

Run these commands:

```bash
flutter analyze
flutter test
```

If generated platform files change unexpectedly after a Flutter tool command,
review the diff before committing. Build output such as `.dart_tool/` and
`build/` should stay uncommitted.

## Useful Files

- `lib/main.dart`: app startup and routes
- `lib/theme/app_theme.dart`: light and dark theme system
- `lib/features/blog/providers/blog_provider.dart`: post feed and mutations
- `lib/features/blog/providers/blog_insights_provider.dart`: derived feed data
- `lib/core/providers/app_preferences_provider.dart`: local settings state
- `lib/core/providers/reading_history_provider.dart`: reading history state
- `lib/features/social/providers/social_provider.dart`: optional social backend

## Common Tasks

Create a story:

1. Open the app.
2. Go to the Write action.
3. Add a title, story body, and optional cover image.
4. Choose Draft or Publish.
5. Save.

Test reading flow:

1. Open a published story.
2. Scroll through the article.
3. Return home or discover.
4. Confirm continue-reading appears.

Test social flow:

1. Apply the social schema.
2. Sign in as two different users.
3. Send a friend request from one public profile.
4. Accept the request from the other user.
5. Open chat and send a message.

