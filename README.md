# Inkwell

Inkwell is a cross-platform Flutter blogging app focused on polished reading and writing experiences across mobile, web, and desktop. It combines content creation, discovery, profile management, reading continuity, and optional social features in a single product that aims to feel modern, readable, and responsive on every screen size.

This repository reflects an updated version of the project with stronger UI polish, better theme consistency, improved mobile web behavior, and more production-style workflows for drafting, publishing, reading, and engagement.

## Project goals

- Build a blog platform that feels intentional and professional instead of looking like a basic CRUD demo.
- Keep the experience readable and visually balanced in both light and dark themes.
- Support mobile, web, and desktop layouts from one Flutter codebase.
- Combine writer tools and reader tools in the same product.
- Use scalable state management and feature-based organization for maintainability.

## What the app includes

- Email/password authentication with Supabase Auth.
- A responsive home feed with featured stories, latest stories, recommendations, topic chips, and reading continuity sections.
- A discover/search flow for stories, writers, and topics.
- A writing studio for creating and editing posts with autosave, draft recovery, cover images, inline images, markdown formatting, live preview, and publishing checks.
- Published and draft story workflows.
- Post detail pages with markdown rendering, reading progress tracking, adjustable text scale, related stories, copy/share actions, likes, bookmarks, and comments.
- Profile and public profile screens with author information, story stats, and editable account details.
- Local reading history with continue-reading and recent-reading experiences.
- Settings for theme mode, compact cards, reader text scale, reduced motion, and local maintenance actions.
- Optional social features including friend requests, accepted friendships, chat threads, direct messaging, and social notification badges.
- Optional tracked story sharing with open metrics and share-link attribution.

## Core concepts used in this project

- Flutter cross-platform development for Android, iOS, web, Windows, Linux, and macOS targets from one codebase.
- Riverpod-based state management for app preferences, reading history, social state, and content flows.
- Feature-first architecture to keep UI, models, providers, and utilities grouped by domain.
- Responsive and adaptive layout patterns for phone, tablet, desktop, and browser widths.
- Local-first behavior using Hive for caching, draft recovery, settings persistence, and reading continuity.
- Supabase backend integration for auth, database tables, storage, and realtime comment updates.
- Markdown-based authoring and rendering with cleanup/normalization helpers for cleaner story output.
- Graceful degradation for optional backend features such as social tables and tracked share events.
- Theme and readability tuning for light mode, dark mode, contrast, spacing, and text scaling.
- Widget and provider testing for regressions, formatting behavior, and responsive UI stability.

## Tech stack

| Layer | Technology |
| --- | --- |
| UI framework | Flutter |
| Language | Dart |
| State management | `flutter_riverpod` |
| Routing | `go_router` |
| Backend | Supabase |
| Database access | `supabase_flutter` |
| Local persistence | `hive`, `hive_flutter` |
| Image handling | `image_picker`, `cached_network_image` |
| Typography | `google_fonts` |
| Animation | `flutter_animate` |
| Markdown rendering | `flutter_markdown` |
| Testing | `flutter_test` |

## High-level architecture

The project follows a feature-based structure rather than putting all screens, state, and models into shared global folders.

```text
lib/
  core/
    providers/
    utils/
    widgets/
  features/
    auth/
    blog/
    home/
    profile/
    search/
    settings/
    social/
  theme/
  main.dart

supabase/
  social_features_schema.sql
  story_share_schema.sql

test/
  archive_links_test.dart
  blog_provider_test.dart
  comment_model_test.dart
  responsive_ui_test.dart
  story_markup_test.dart
  story_spotlight_card_test.dart
  widget_test.dart
```

### Architectural notes

- `core/` contains shared layout helpers, preferences providers, reading history, feedback utilities, and reusable visual surfaces.
- `features/` contains self-contained domains such as auth, blog, profile, and social.
- `theme/` centralizes the design language for light and dark themes.
- `main.dart` initializes Hive, Supabase, theming, and app routing.

## Main feature areas

### Authentication

- Sign up with email, password, username, and full name.
- Sign in and sign out through Supabase Auth.
- Password reset support.
- Profile creation is tied to signup and stored in the `profiles` table.

### Feed and discovery

- Featured story spotlight.
- Latest stories sorted by publish time.
- Topic extraction and topic-based discovery.
- Recommendation and trending logic based on likes, freshness, and user activity.
- Search with filters and responsive layouts.

### Writing studio

- Create and edit stories.
- Cover image upload.
- Inline story image upload.
- Markdown toolbar for faster formatting.
- Font presets embedded in content metadata.
- Live preview and writing insights.
- Publishing checklist.
- Draft or publish mode.
- Local draft autosave and restoration through Hive.

### Reader experience

- Markdown story rendering.
- Reader text scale controls.
- Reading progress indicator.
- Continue-reading and recent-reading tracking.
- Related stories.
- Likes, bookmarks, and comments.
- Share, copy-title, copy-story, and copy-summary actions.

### Profile and creator tools

- Editable personal profile.
- Public profile view for other writers.
- Writer metrics such as likes, words written, saved posts, draft count, and top story.
- Reading activity surfaces and saved-story management.

### Settings and UX controls

- Light, dark, and system theme modes.
- Compact story cards.
- Reduced motion.
- Default reader text size.
- Reset local display preferences.
- Clear reading history.

### Social layer

- Friend request flow.
- Accepted friends and pending invites.
- Direct messaging between writers.
- Social notification badges.
- Suggested writers generated from feed authors.

These social features are optional and become fully available when the schema in `supabase/social_features_schema.sql` is applied.

### Share tracking

- Generates share links for stories.
- Supports attributed opens through query parameters.
- Tracks share count and open count for authors.

This tracking is optional and becomes available when `supabase/story_share_schema.sql` is applied.

## Data flow and persistence

The app uses a combination of remote backend data and local cached state.

### Supabase responsibilities

- Authentication.
- Storing profiles, posts, likes, bookmarks, comments, friendships, direct messages, and share tracking data.
- Public image delivery for avatars, cover images, and inline story images.
- Realtime updates for comments.

### Hive responsibilities

- `posts_box`: cached post feed data.
- `editor_box`: local editor draft recovery.
- `settings_box`: theme mode, reduced motion, compact cards, and reader text scale.
- `history_box`: reading history, progress, and continue-reading state.

## Supabase backend requirements

This codebase expects a Supabase project. Two extension schemas are included in the repository, but the full base blogging schema is not included as a single SQL file. Based on the implementation, the app expects the following backend resources.

### Required base tables

- `profiles`
- `posts`
- `likes`
- `bookmarks`
- `comments`

### Expected base table fields

At minimum, the code expects the following columns to exist:

- `profiles`: `id`, `username`, `full_name`
- `posts`: `id`, `user_id`, `title`, `content`, `cover_image_url`, `is_published`, `created_at`
- `likes`: `post_id`, `user_id`
- `bookmarks`: `post_id`, `user_id`
- `comments`: `id`, `post_id`, `user_id`, `created_at`, and either `text_content` or legacy `content`

### Required storage bucket

- `blog_images`

This bucket is used for:

- profile avatars
- story cover images
- inline story images

The app assumes uploaded files can be read publicly through Supabase Storage public URLs.

### Optional schema files included in this repo

- `supabase/social_features_schema.sql`
  - Adds `friendships`
  - Adds `direct_messages`
  - Configures indexes, triggers, and row-level security policies

- `supabase/story_share_schema.sql`
  - Adds `story_share_events`
  - Adds share-open tracking function `record_story_share_open`
  - Configures indexes and row-level security policies

### Backend behavior notes

- Comments gracefully support either a modern `text_content` column or a legacy `content` column.
- If the social schema is missing, the app shows a setup state instead of crashing.
- If share tracking is missing, story sharing falls back to a normal link without metrics.

## Share host configuration

Tracked share links use a host that can be configured at build time.

```bash
flutter run --dart-define=INKWELL_SHARE_HOST=your-domain.com
```

If no host is provided, the app falls back to the current runtime host or a local archive host value.

## Getting started

### Prerequisites

- Flutter SDK 3.0 or newer
- Dart SDK compatible with the Flutter version in use
- A Supabase project
- Platform toolchains for the targets you want to run

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Supabase

The current app initializes Supabase directly in `lib/main.dart`.

Replace the existing project URL and anon key there with your own values if you are connecting this app to a different backend:

```dart
Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
)
```

### 3. Prepare your database

Ensure your base blogging tables and `blog_images` storage bucket exist.

Then, if you want the optional features:

1. Run `supabase/social_features_schema.sql` in the Supabase SQL editor to enable friendships and direct messages.
2. Run `supabase/story_share_schema.sql` in the Supabase SQL editor to enable tracked share events.

### 4. Run the app

```bash
flutter run
```

Examples:

```bash
flutter run -d chrome
flutter run -d android
flutter run -d windows
```

## Useful commands

```bash
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

If you change Hive models or generated files in the future, regenerate adapters with:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Testing strategy

The repository already includes tests for behavior that matters to this app's product quality.

- Provider and model tests for blog state and comment handling.
- Story markup tests for markdown normalization and editor formatting helpers.
- Responsive UI smoke tests for light/dark themes and narrow/wide viewports.
- Widget tests for app bootstrapping and spotlight card readability.

Run all tests with:

```bash
flutter test
```

## Design and UX focus

This project pays special attention to:

- strong readability in both light and dark themes
- clean spacing and contrast
- responsive layout behavior on mobile web and desktop
- polished card surfaces and navigation chrome
- writing-first and reading-first workflows
- local recovery for drafts and reading continuity

## Current scope of the project

Inkwell currently covers the scope of a modern content platform prototype:

- authentication
- author profiles
- story publishing
- markdown reading
- local continuity features
- engagement through likes, bookmarks, and comments
- optional social networking and chat
- optional share analytics

This makes it a strong portfolio project for demonstrating product thinking, full-stack Flutter integration, UI/UX polish, and cross-platform delivery.

## Notes and limitations

- Supabase credentials are currently initialized directly in `lib/main.dart`. For production, moving them into a safer configuration strategy is recommended.
- The repository includes optional extension schemas for social and share tracking, but not a single all-in-one SQL file for the full base blog schema.
- Native desktop builds still require the correct Flutter desktop toolchains on the local machine.

## Future improvement ideas

- push notifications for social activity
- richer editor capabilities such as drafts syncing between devices
- image upload progress and media management
- stronger moderation and reporting workflows
- richer analytics for authors
- offline sync instead of local-only recovery for some flows

## Summary

Inkwell is a polished Flutter blogging application that demonstrates:

- Riverpod state management
- Supabase backend integration
- Hive local persistence
- markdown authoring and rendering
- responsive cross-platform UI
- optional social and sharing systems


