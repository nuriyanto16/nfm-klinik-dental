import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeColor { blue, pink, emerald, violet }

class ThemeState {
  final AppThemeColor colorTheme;
  final bool isDarkMode;
  final String fontFamily;

  ThemeState({
    required this.colorTheme,
    required this.isDarkMode,
    required this.fontFamily,
  });

  ThemeState copyWith({
    AppThemeColor? colorTheme,
    bool? isDarkMode,
    String? fontFamily,
  }) {
    return ThemeState(
      colorTheme: colorTheme ?? this.colorTheme,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const _themeColorKey = 'theme_color';
  static const _darkModeKey = 'dark_mode';
  static const _fontFamilyKey = 'font_family';

  ThemeNotifier()
      : super(ThemeState(
          colorTheme: AppThemeColor.blue,
          isDarkMode: false,
          fontFamily: 'Inter',
        )) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorIndex = prefs.getInt(_themeColorKey) ?? 0;
    final isDark = prefs.getBool(_darkModeKey) ?? false;
    final font = prefs.getString(_fontFamilyKey) ?? 'Inter';

    state = ThemeState(
      colorTheme: AppThemeColor.values.elementAt(colorIndex.clamp(0, AppThemeColor.values.length - 1)),
      isDarkMode: isDark,
      fontFamily: font,
    );
  }

  Future<void> setColorTheme(AppThemeColor color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColorKey, color.index);
    state = state.copyWith(colorTheme: color);
  }

  Future<void> toggleDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDark);
    state = state.copyWith(isDarkMode: isDark);
  }

  Future<void> setFontFamily(String font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, font);
    state = state.copyWith(fontFamily: font);
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
