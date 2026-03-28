class AppValidators {
  const AppValidators._();

  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9_.]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!email.contains('@') || email.startsWith('@') || email.endsWith('@')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < minLength) {
      return 'Use at least $minLength characters.';
    }
    return null;
  }

  static String? fullName(String? value) {
    final fullName = value?.trim() ?? '';
    if (fullName.isEmpty) {
      return 'Full name is required.';
    }
    if (fullName.length < 2) {
      return 'Enter the name readers should recognize.';
    }
    return null;
  }

  static String? username(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) {
      return 'Username is required.';
    }
    if (username.length < 3) {
      return 'Use at least 3 characters.';
    }
    if (!_usernamePattern.hasMatch(username)) {
      return 'Use letters, numbers, underscores, or periods only.';
    }
    return null;
  }
}
