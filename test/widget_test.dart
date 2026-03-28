import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blog_app/main.dart';

import 'test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await ensureTestStorageReady();
  });

  tearDownAll(() async {
    await closeTestStorage();
  });

  testWidgets('App boots up successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: InkwellApp()));
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
