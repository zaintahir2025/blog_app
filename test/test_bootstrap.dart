import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:blog_app/features/blog/models/post_model.dart';

bool _storageReady = false;

Future<void> ensureTestStorageReady() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (_storageReady) {
    return;
  }

  final tempDir = await Directory.systemTemp.createTemp('blog_app_test');
  Hive.init(tempDir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PostModelAdapter());
  }

  for (final boxName in const [
    'posts_box',
    'editor_box',
    'settings_box',
    'history_box',
  ]) {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  _storageReady = true;
}

Future<void> closeTestStorage() async {
  if (!_storageReady) {
    return;
  }

  await Hive.close();
  _storageReady = false;
}
