import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blog_app/core/utils/app_error_mapper.dart';
import 'package:blog_app/core/utils/app_feedback.dart';
import 'package:blog_app/core/utils/app_layout.dart';
import 'package:blog_app/core/widgets/ink_surfaces.dart';
import 'package:blog_app/features/profile/providers/profile_provider.dart';
import 'package:blog_app/features/profile/widgets/profile_avatar.dart';
import 'package:blog_app/features/social/providers/social_notifications_provider.dart';
import 'package:blog_app/features/social/providers/social_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  late final SocialNotificationsNotifier _socialNotificationsNotifier;
  late final SocialRepository _socialRepository;
  Timer? _refreshTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _socialNotificationsNotifier =
        ref.read(socialNotificationsProvider.notifier);
    _socialRepository = ref.read(socialRepositoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _socialNotificationsNotifier.markThreadRead(widget.userId);
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) {
        return;
      }
      ref.invalidate(chatMessagesProvider(widget.userId));
      ref.invalidate(chatThreadsProvider);
      _socialNotificationsNotifier.refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await _socialRepository.sendMessage(
        recipientId: widget.userId,
        content: content,
      );
      if (!mounted) {
        return;
      }
      _messageController.clear();
      ref.invalidate(chatMessagesProvider(widget.userId));
      ref.invalidate(chatThreadsProvider);
      await _socialNotificationsNotifier.markThreadRead(widget.userId);
      await _socialNotificationsNotifier.refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, AppErrorMapper.readable(error));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backendAsync = ref.watch(socialBackendProvider);
    final profileAsync = ref.watch(publicProfileProvider(widget.userId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.userId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          loading: () => const Text('Conversation'),
          error: (_, __) => const Text('Conversation'),
          data: (profile) => Row(
            children: [
              ProfileAvatar(
                userId: widget.userId,
                fallbackLabel: _initial(profile?.displayName ?? 'Writer'),
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.displayName ?? 'Writer'),
                    Text(
                      '@${profile?.username ?? 'writer'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'View profile',
            onPressed: () => context.push('/user/${widget.userId}'),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: backendAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (backend) {
          if (!backend.isConfigured) {
            return _ChatSetupState(message: backend.message ?? '');
          }

          return InkBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: AppLayout.contentMaxWidth(context)),
                child: Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(chatMessagesProvider(widget.userId));
                          ref.invalidate(chatThreadsProvider);
                          await _socialNotificationsNotifier.refresh();
                        },
                        child: messagesAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => ListView(
                            padding: AppLayout.pagePadding(context),
                            children: [
                              Text('Could not load messages.\n$error')
                            ],
                          ),
                          data: (messages) {
                            if (messages.isEmpty) {
                              return ListView(
                                padding: AppLayout.pagePadding(context),
                                children: [
                                  const SizedBox(height: 100),
                                  _ChatEmptyState(
                                    title: 'Start the conversation',
                                    body:
                                        'Writers often connect around drafts, ideas, and feedback. Say hello and break the ice.',
                                    userId: widget.userId,
                                    fallbackLabel: profileAsync.maybeWhen(
                                      data: (profile) =>
                                          _initial(profile?.displayName ?? 'W'),
                                      orElse: () => 'W',
                                    ),
                                  ),
                                ],
                              );
                            }

                            return ListView.builder(
                              reverse: true,
                              padding: AppLayout.pagePadding(context)
                                  .copyWith(top: 16, bottom: 12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message =
                                    messages[messages.length - 1 - index];
                                final isMine =
                                    message.sender.id == currentUserId;

                                return Align(
                                  alignment: isMine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 560,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? colorScheme.primary
                                          : colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isMine
                                              ? 'You'
                                              : message.sender.displayName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isMine
                                                ? Colors.white
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          message.content,
                                          style: TextStyle(
                                            color: isMine
                                                ? Colors.white
                                                : colorScheme.onSurface,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _timestamp(message.createdAt),
                                          style: TextStyle(
                                            color: isMine
                                                ? Colors.white70
                                                : colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: AppLayout.pagePadding(context)
                            .copyWith(top: 12, bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.92),
                          border: Border(
                            top: BorderSide(color: colorScheme.outlineVariant),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                onSubmitted: (_) => _sendMessage(),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                minLines: 1,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: 'Send a message...',
                                  filled: true,
                                  fillColor:
                                      colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: _isSending ? null : _sendMessage,
                              style: FilledButton.styleFrom(
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                              ),
                              child: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatSetupState extends StatelessWidget {
  const _ChatSetupState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 72,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.24),
              ),
              const SizedBox(height: 16),
              Text(
                'Chat is almost ready',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({
    required this.title,
    required this.body,
    required this.userId,
    required this.fallbackLabel,
  });

  final String title;
  final String body;
  final String userId;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          ProfileAvatar(
            userId: userId,
            fallbackLabel: fallbackLabel,
            radius: 34,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

String _timestamp(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}
