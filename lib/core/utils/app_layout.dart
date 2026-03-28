import 'package:flutter/material.dart';

class AppLayout {
  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 700;
  }

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 700 && width < 1100;
  }

  static bool isExpanded(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1100;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1440;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1440) {
      return const EdgeInsets.symmetric(horizontal: 44, vertical: 24);
    }
    if (width >= 1100) {
      return const EdgeInsets.symmetric(horizontal: 34, vertical: 22);
    }
    if (width >= 700) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 18);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1440) {
      return 1240;
    }
    if (width >= 1100) {
      return 1080;
    }
    if (width >= 700) {
      return 880;
    }
    return width;
  }

  static double sectionGap(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) {
      return 28;
    }
    if (width >= 700) {
      return 24;
    }
    return 20;
  }

  static double panelGap(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) {
      return 18;
    }
    if (width >= 700) {
      return 16;
    }
    return 14;
  }

  static double bottomNavigationClearance(BuildContext context) {
    if (isExpanded(context)) {
      return 32;
    }
    return 116;
  }
}
