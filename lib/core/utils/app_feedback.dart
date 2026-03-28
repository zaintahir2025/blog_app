import 'package:flutter/material.dart';

import 'package:blog_app/theme/app_theme.dart';

class AppFeedback {
  const AppFeedback._();

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _show(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
      action: action,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppTheme.secondaryColor,
      foregroundColor: Colors.white,
      action: action,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _show(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.error,
      foregroundColor: Theme.of(context).colorScheme.onError,
      action: action,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Color foregroundColor,
    SnackBarAction? action,
  }) {
    final snackBarTheme = Theme.of(context).snackBarTheme;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: snackBarTheme.contentTextStyle?.copyWith(
                  color: foregroundColor,
                ) ??
                TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          backgroundColor: backgroundColor,
          action: action,
        ),
      );
  }
}
