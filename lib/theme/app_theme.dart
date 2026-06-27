import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Theme Palette
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color accentColor = Color(0xFFD4AF37); // Gold
  static const Color secondaryColor = Color(0xFF334155); // Slate
  static const Color backgroundColor = Color(0xFFF8FAFC); // Clean Off-white
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color inkColor = Color(0xFF020617);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: Color(0xFF1E3A8A),
    secondary: secondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFF1F5F9),
    onSecondaryContainer: Color(0xFF0F172A),
    tertiary: accentColor,
    onTertiary: Colors.black,
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF92400E),
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: surfaceColor,
    onSurface: textPrimary,
    surfaceContainerHighest: Color(0xFFF1F5F9),
    onSurfaceVariant: textSecondary,
    outline: Color(0xFFCBD5E1),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0x140F172A),
    scrim: Color(0x330F172A),
    inverseSurface: inkColor,
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFF93C5FD),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF60A5FA),
    onPrimary: Color(0xFF1E3A8A),
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary: Color(0xFF94A3B8),
    onSecondary: Color(0xFF0F172A),
    secondaryContainer: Color(0xFF1E293B),
    onSecondaryContainer: Color(0xFFF1F5F9),
    tertiary: accentColor,
    onTertiary: Colors.black,
    tertiaryContainer: Color(0xFF78350F),
    onTertiaryContainer: Color(0xFFFEF3C7),
    error: Color(0xFFF87171),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF0F172A),
    onSurface: Color(0xFFF8FAFC),
    surfaceContainerHighest: Color(0xFF1E293B),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF475569),
    outlineVariant: Color(0xFF334155),
    shadow: Color(0x66000000),
    scrim: Color(0x88000000),
    inverseSurface: Color(0xFFF8FAFC),
    onInverseSurface: inkColor,
    inversePrimary: primaryColor,
  );

  static ThemeData get lightTheme => _buildTheme(_lightScheme);

  static ThemeData get darkTheme => _buildTheme(_darkScheme);

  static LinearGradient heroGradient(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F172A),
          Color(0xFF020617),
          Color(0xFF000000),
        ],
        stops: [0, 0.58, 1],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF8FAFC),
        Color(0xFFF1F5F9),
      ],
      stops: [0, 0.58, 1],
    );
  }

  static LinearGradient backgroundGradient(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF020617),
          Color(0xFF040A1F),
          Color(0xFF000000),
        ],
        stops: [0, 0.5, 1],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF8FAFC),
        Color(0xFFF1F5F9),
        Color(0xFFE2E8F0),
      ],
      stops: [0, 0.55, 1],
    );
  }

  static LinearGradient panelGradient(
      Brightness brightness, ColorScheme scheme) {
    if (brightness == Brightness.dark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.surface.withValues(alpha: 0.98),
          const Color(0xFF0B1121).withValues(alpha: 0.98),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.98),
        const Color(0xFFF8FAFC).withValues(alpha: 0.98),
      ],
    );
  }

  static Color panelBorder(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.light
        ? colorScheme.outlineVariant.withValues(alpha: 0.88)
        : colorScheme.outline.withValues(alpha: 0.42);
  }

  static List<BoxShadow> panelShadows(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ];
    }

    return const [
      BoxShadow(
        color: Color(0x0A0F172A),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ];
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final sansTextTheme = GoogleFonts.manropeTextTheme();
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      canvasColor: colorScheme.surface,
      scaffoldBackgroundColor: colorScheme.brightness == Brightness.light
          ? backgroundColor
          : const Color(0xFF111111),
      textTheme: sansTextTheme.copyWith(
        displayLarge: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 42,
          height: 1.04,
          letterSpacing: -1.2,
        ),
        displayMedium: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 34,
          height: 1.06,
          letterSpacing: -0.9,
        ),
        displaySmall: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 28,
          height: 1.08,
          letterSpacing: -0.7,
        ),
        headlineLarge: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineSmall: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 21,
          letterSpacing: -0.4,
        ),
        titleMedium: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: -0.2,
        ),
        titleSmall: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontSize: 15,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.manrope(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.55,
        ),
        bodySmall: GoogleFonts.manrope(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12.5,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.manrope(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        labelSmall: GoogleFonts.manrope(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: panelBorder(colorScheme)),
        ),
      ),
      dividerColor: colorScheme.outlineVariant,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: colorScheme.brightness == Brightness.light ? 0.58 : 0.94,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: panelBorder(colorScheme)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
        hintStyle: GoogleFonts.manrope(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
          height: 1.45,
        ),
        labelStyle: GoogleFonts.manrope(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: GoogleFonts.manrope(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        helperStyle: GoogleFonts.manrope(
          color: colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
        errorStyle: GoogleFonts.manrope(
          color: colorScheme.error,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 44),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          backgroundColor: Colors.transparent,
          minimumSize: const Size(44, 44),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: panelBorder(colorScheme)),
        backgroundColor: colorScheme.surface.withValues(alpha: 0.88),
        selectedColor: colorScheme.primary.withValues(alpha: 0.16),
        labelStyle: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.manrope(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.manrope(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return GoogleFonts.manrope(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: GoogleFonts.manrope(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: GoogleFonts.manrope(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(
            BorderSide(color: panelBorder(colorScheme)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.manrope(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        subtitleTextStyle: GoogleFonts.manrope(
          color: colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.22),
        selectionHandleColor: colorScheme.primary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.manrope(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: panelBorder(colorScheme)),
        ),
        textStyle: GoogleFonts.manrope(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return isDark ? colorScheme.onSurfaceVariant : colorScheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStatePropertyAll(
          colorScheme.outline.withValues(alpha: isDark ? 0.72 : 0.52),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return colorScheme.primary.withValues(alpha: 0.92);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.72);
          }
          return colorScheme.onSurfaceVariant.withValues(alpha: 0.46);
        }),
        trackColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        ),
        radius: const Radius.circular(999),
        thickness: const WidgetStatePropertyAll(8),
      ),
    );
  }
}
