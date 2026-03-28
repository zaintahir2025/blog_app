class ArchiveLinks {
  const ArchiveLinks._();

  static const String _fallbackHost = 'archive.inkwell.local';

  static String get host {
    const configuredHost = String.fromEnvironment('INKWELL_SHARE_HOST');
    if (configuredHost.isNotEmpty) {
      return configuredHost;
    }

    final runtimeHost = Uri.base.host;
    if (runtimeHost.isNotEmpty &&
        runtimeHost != 'localhost' &&
        runtimeHost != '127.0.0.1') {
      return runtimeHost;
    }

    return _fallbackHost;
  }

  static String postPath(
    String postId, {
    String? shareId,
    String? sharedByUserId,
  }) {
    return Uri(
      path: '/posts/$postId',
      queryParameters: _postQueryParameters(
        shareId: shareId,
        sharedByUserId: sharedByUserId,
      ),
    ).toString();
  }

  static Uri postUri(
    String postId, {
    String? shareId,
    String? sharedByUserId,
  }) {
    return Uri.https(
      host,
      '/posts/$postId',
      _postQueryParameters(
        shareId: shareId,
        sharedByUserId: sharedByUserId,
      ),
    );
  }

  static String discoverPath({String? query}) {
    final trimmed = query?.trim() ?? '';
    return Uri(
      path: '/discover',
      queryParameters: trimmed.isEmpty ? null : {'q': trimmed},
    ).toString();
  }

  static Uri discoverUri({String? query}) {
    final trimmed = query?.trim() ?? '';
    return Uri.https(
      host,
      '/discover',
      trimmed.isEmpty ? null : {'q': trimmed},
    );
  }

  static String display(Uri uri) {
    final buffer = StringBuffer()
      ..write(uri.host)
      ..write(uri.path);

    if (uri.hasQuery) {
      buffer
        ..write('?')
        ..write(uri.query);
    }

    return buffer.toString();
  }

  static Map<String, String>? _postQueryParameters({
    String? shareId,
    String? sharedByUserId,
  }) {
    final queryParameters = <String, String>{};
    final trimmedShareId = shareId?.trim() ?? '';
    final trimmedSharedByUserId = sharedByUserId?.trim() ?? '';

    if (trimmedShareId.isNotEmpty) {
      queryParameters['share_id'] = trimmedShareId;
    }
    if (trimmedSharedByUserId.isNotEmpty) {
      queryParameters['shared_by'] = trimmedSharedByUserId;
    }

    return queryParameters.isEmpty ? null : queryParameters;
  }
}
