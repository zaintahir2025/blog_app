import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppPreferences {
  const AppPreferences({
    required this.themeMode,
    required this.compactCards,
    required this.readerTextScale,
    required this.reducedMotion,
  });

  factory AppPreferences.defaults() {
    return const AppPreferences(
      themeMode: ThemeMode.system,
      compactCards: false,
      readerTextScale: 1,
      reducedMotion: false,
    );
  }

  final ThemeMode themeMode;
  final bool compactCards;
  final double readerTextScale;
  final bool reducedMotion;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    bool? compactCards,
    double? readerTextScale,
    bool? reducedMotion,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      compactCards: compactCards ?? this.compactCards,
      readerTextScale: readerTextScale ?? this.readerTextScale,
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }
}

class AppPreferencesNotifier extends StateNotifier<AppPreferences> {
  AppPreferencesNotifier() : super(_loadPreferences());

  static const String _boxName = 'settings_box';

  static Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  static AppPreferences _loadPreferences() {
    final storedTheme = _box.get('theme_mode') as String?;
    final storedCompactCards = _box.get('compact_cards') as bool?;
    final storedReaderTextScale =
        (_box.get('reader_text_scale') as num?)?.toDouble();
    final storedReducedMotion = _box.get('reduced_motion') as bool?;

    return AppPreferences(
      themeMode: switch (storedTheme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      compactCards: storedCompactCards ?? false,
      readerTextScale: storedReaderTextScale?.clamp(0.9, 1.3) ?? 1,
      reducedMotion: storedReducedMotion ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _box.put(
        'theme_mode',
        switch (themeMode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        });
  }

  Future<void> setCompactCards(bool value) async {
    state = state.copyWith(compactCards: value);
    await _box.put('compact_cards', value);
  }

  Future<void> setReaderTextScale(double value) async {
    final normalized = value.clamp(0.9, 1.3);
    state = state.copyWith(readerTextScale: normalized);
    await _box.put('reader_text_scale', normalized);
  }

  Future<void> setReducedMotion(bool value) async {
    state = state.copyWith(reducedMotion: value);
    await _box.put('reduced_motion', value);
  }

  Future<void> reset() async {
    state = AppPreferences.defaults();
    await _box.putAll({
      'theme_mode': 'system',
      'compact_cards': false,
      'reader_text_scale': 1.0,
      'reduced_motion': false,
    });
  }
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>((ref) {
  return AppPreferencesNotifier();
});
