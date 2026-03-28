class AppErrorMapper {
  const AppErrorMapper._();

  static String readable(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty || raw == 'null') {
      return fallback;
    }

    final normalized = raw.toLowerCase();

    if (normalized.contains('invalid login credentials')) {
      return 'The email or password looks incorrect. Please try again.';
    }
    if (normalized.contains('email not confirmed') ||
        normalized.contains('email_not_confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    if (normalized.contains('user already registered') ||
        normalized.contains('already registered')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (normalized.contains('username is already taken') ||
        (normalized.contains('duplicate key') &&
            normalized.contains('username')) ||
        normalized.contains('profiles_username_key')) {
      return 'That username is already taken. Try another one.';
    }
    if (normalized.contains('not logged in') ||
        normalized.contains('jwt') ||
        normalized.contains('auth session missing') ||
        normalized.contains('permission denied') ||
        normalized.contains('row-level security')) {
      return 'Your session is no longer valid for this action. Please sign in again and retry.';
    }
    if (normalized.contains('network') ||
        normalized.contains('socket') ||
        normalized.contains('connection') ||
        normalized.contains('failed host lookup')) {
      return 'Your connection looks unstable. Check your internet and try again.';
    }
    if (normalized.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }
    if (normalized.contains('no image selected')) {
      return 'Please choose an image first.';
    }

    return raw[0].toUpperCase() + raw.substring(1);
  }
}
