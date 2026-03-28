import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 0;
    final showDesktopScrollbar = width >= 900;

    return Scrollbar(
      controller: details.controller,
      thumbVisibility: switch (getPlatform(context)) {
        TargetPlatform.macOS ||
        TargetPlatform.linux ||
        TargetPlatform.windows => showDesktopScrollbar,
        _ => false,
      },
      interactive: true,
      child: child,
    );
  }
}
