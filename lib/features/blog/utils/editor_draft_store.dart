import 'package:hive_flutter/hive_flutter.dart';

class EditorDraftStore {
  static const String boxName = 'editor_box';
  static const String createDraftKey = 'create_post_draft';

  static Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  static Map<String, dynamic>? readDraft(String key) {
    final data = _box.get(key);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> saveDraft({
    required String key,
    required String title,
    required String content,
    required bool isPublished,
  }) {
    return _box.put(key, {
      'title': title,
      'content': content,
      'isPublished': isPublished,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> clearDraft(String key) {
    return _box.delete(key);
  }
}
