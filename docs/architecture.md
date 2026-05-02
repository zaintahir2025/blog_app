# Inkwell Architecture

This document explains how the app is put together from the codebase level.

## App Startup

The app starts in `lib/main.dart`.

Startup does four important things:

1. Initializes Flutter bindings.
2. Initializes Hive local storage.
3. Initializes Supabase.
4. Wraps the app in Riverpod's `ProviderScope`.

After that, `InkwellApp` creates a `MaterialApp.router` with app themes,
scroll behavior, restoration support, and GoRouter routes.

## Routing

Navigation is handled with GoRouter.

Important routes:

- `/` opens the splash screen.
- `/login` and `/signup` handle authentication.
- `/home` opens the main app shell.
- `/create_post` opens the writing studio.
- `/posts/:postId` opens a story by id.
- `/discover` opens search.
- `/user/:userId` opens a public profile.
- `/chat/:userId` opens direct messages.

The app uses both path parameters and `extra` route data. For example, a story
card can pass the full `PostModel` through `extra`, while shared links can open
the same story using only `/posts/:postId`.

## Feature Structure

The `lib/features` folder is organized by product area:

- `auth`: login, signup, splash, and auth repository.
- `blog`: post models, feed provider, editor screens, reader screen, comments,
  markdown utilities, and story widgets.
- `home`: main feed and shell navigation.
- `profile`: current profile, public profiles, avatars, and edit profile flow.
- `search`: discover/search experience.
- `settings`: local preferences and maintenance tools.
- `social`: optional friends, notifications, and direct messaging.

Shared app code lives in `lib/core`, and theme code lives in `lib/theme`.

## State Management

Riverpod is the state layer.

The main mutable providers are:

- `blogFeedProvider`: posts, likes, bookmarks, publishing, image uploads.
- `commentsProvider`: comments per post with realtime refresh.
- `appPreferencesProvider`: theme, card density, reader text size, motion.
- `readingHistoryProvider`: reading progress and continue-reading data.
- `socialNotificationsProvider`: friend request and unread chat counts.

The app also has derived providers in `blog_insights_provider.dart`. These turn
the raw post feed into useful views such as published posts, drafts, saved
posts, trending stories, recommended stories, topics, authors, and dashboard
stats.

## Persistence

The app uses both remote and local persistence.

Supabase stores shared backend data:

- users and auth sessions
- profiles
- posts
- likes
- bookmarks
- comments
- optional friendships and direct messages
- optional story share events
- images in the `blog_images` storage bucket

Hive stores local device data:

- `posts_box`: cached feed posts
- `editor_box`: local draft recovery
- `settings_box`: preferences, recent searches, social read markers
- `history_box`: reading history and progress

This split keeps important shared data online while making the app faster and
more resilient for personal local state.

## Content Flow

A story goes through this path:

1. The writer opens the story studio.
2. The editor writes markdown and optionally adds images.
3. The app saves a local draft to Hive while typing.
4. On publish or save draft, the app inserts or updates a Supabase `posts` row.
5. The feed provider refreshes the post list.
6. Home, search, profile, and reader screens rebuild from the updated provider.

The reader screen renders markdown with `MarkdownContent`, tracks scroll
progress, saves reading history, and exposes actions like comments, likes,
bookmarks, share links, and text-size controls.

## Optional Backend Features

The repo includes optional Supabase schemas:

- `supabase/social_features_schema.sql`
- `supabase/story_share_schema.sql`

The code checks whether optional social tables exist. If they are missing, the
social screens show a setup state instead of crashing. Share tracking also
falls back to normal story links if the tracking table or function is missing.

