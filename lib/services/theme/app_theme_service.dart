import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/playtorrio_tokens.dart';

class AppThemePalette {
  final String id;
  final String name;
  final Color primaryColor;
  final Color accentColor;
  final Color scaffoldBackgroundColor;
  final Color cardBackgroundColor;
  final Color appBarBackgroundColor;
  final Color backgroundSecondaryColor;
  final Color surfaceElevatedColor;

  const AppThemePalette({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    this.scaffoldBackgroundColor = const Color(0xFF080A0F),
    this.cardBackgroundColor = const Color(0xFF12151E),
    this.appBarBackgroundColor = const Color(0xFF0D1017),
    this.backgroundSecondaryColor = const Color(0xFF0D1017),
    this.surfaceElevatedColor = const Color(0xFF171A23),
  });
}

abstract final class AppThemeService {
  static const _storageKey = 'app_theme_id';

  static const List<AppThemePalette> palettes = [
    AppThemePalette(
      id: 'amethyst',
      name: 'Amethyst Violet',
      primaryColor: Color(0xFF7C5CFF),
      accentColor: Color(0xFF00E5FF),
      scaffoldBackgroundColor: Color(0xFF080A0F),
      cardBackgroundColor: Color(0xFF12151E),
      appBarBackgroundColor: Color(0xFF0D1017),
      backgroundSecondaryColor: Color(0xFF0C0F16),
      surfaceElevatedColor: Color(0xFF171A23),
    ),
    AppThemePalette(
      id: 'cyberpunk',
      name: 'Cyberpunk Neon',
      primaryColor: Color(0xFFFF2A85),
      accentColor: Color(0xFF00F0FF),
      scaffoldBackgroundColor: Color(0xFF0C0812),
      cardBackgroundColor: Color(0xFF160E1E),
      appBarBackgroundColor: Color(0xFF100A17),
      backgroundSecondaryColor: Color(0xFF100B18),
      surfaceElevatedColor: Color(0xFF1C1226),
    ),
    AppThemePalette(
      id: 'emerald',
      name: 'Emerald Aurora',
      primaryColor: Color(0xFF10B981),
      accentColor: Color(0xFF34D399),
      scaffoldBackgroundColor: Color(0xFF060F0B),
      cardBackgroundColor: Color(0xFF0E1A14),
      appBarBackgroundColor: Color(0xFF09140F),
      backgroundSecondaryColor: Color(0xFF0A140F),
      surfaceElevatedColor: Color(0xFF14241B),
    ),
    AppThemePalette(
      id: 'sunset',
      name: 'Sunset Crimson',
      primaryColor: Color(0xFFFF3366),
      accentColor: Color(0xFFFF9900),
      scaffoldBackgroundColor: Color(0xFF0F080B),
      cardBackgroundColor: Color(0xFF1A0E13),
      appBarBackgroundColor: Color(0xFF130A0E),
      backgroundSecondaryColor: Color(0xFF140A0E),
      surfaceElevatedColor: Color(0xFF24141B),
    ),
    AppThemePalette(
      id: 'sapphire',
      name: 'Midnight Sapphire',
      primaryColor: Color(0xFF3B82F6),
      accentColor: Color(0xFF60A5FA),
      scaffoldBackgroundColor: Color(0xFF060B14),
      cardBackgroundColor: Color(0xFF0E1726),
      appBarBackgroundColor: Color(0xFF09101C),
      backgroundSecondaryColor: Color(0xFF0A1220),
      surfaceElevatedColor: Color(0xFF141F31),
    ),
    AppThemePalette(
      id: 'amber',
      name: 'Golden Amber',
      primaryColor: Color(0xFFF59E0B),
      accentColor: Color(0xFFFCD34D),
      scaffoldBackgroundColor: Color(0xFF0F0C06),
      cardBackgroundColor: Color(0xFF1A160E),
      appBarBackgroundColor: Color(0xFF141009),
      backgroundSecondaryColor: Color(0xFF140F09),
      surfaceElevatedColor: Color(0xFF241E14),
    ),
    AppThemePalette(
      id: 'vampire',
      name: 'Vampire Red',
      primaryColor: Color(0xFFE50914),
      accentColor: Color(0xFFFF4D4D),
      scaffoldBackgroundColor: Color(0xFF0E0607),
      cardBackgroundColor: Color(0xFF1A0C0E),
      appBarBackgroundColor: Color(0xFF14080A),
      backgroundSecondaryColor: Color(0xFF130809),
      surfaceElevatedColor: Color(0xFF241014),
    ),
    AppThemePalette(
      id: 'barbie',
      name: 'Pink Barbie',
      primaryColor: Color(0xFFFF1493),
      accentColor: Color(0xFFFF80BF),
      scaffoldBackgroundColor: Color(0xFF14050E),
      cardBackgroundColor: Color(0xFF220A18),
      appBarBackgroundColor: Color(0xFF1A0713),
      backgroundSecondaryColor: Color(0xFF190611),
      surfaceElevatedColor: Color(0xFF2C0E20),
    ),
  ];

  static final ValueNotifier<AppThemePalette> currentPalette =
      ValueNotifier<AppThemePalette>(palettes[0]);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_storageKey);
    if (id != null) {
      final found = palettes.firstWhere(
        (p) => p.id == id,
        orElse: () => palettes[0],
      );
      currentPalette.value = found;
    }
  }

  static Future<void> setPalette(AppThemePalette palette) async {
    currentPalette.value = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, palette.id);
  }

  static ThemeData createThemeData(AppThemePalette palette) {
    final tokens = PlayTorrioTokens.fromPalette(palette);
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: palette.scaffoldBackgroundColor,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primaryColor,
        brightness: Brightness.dark,
      ).copyWith(
        primary: palette.primaryColor,
        onPrimary: tokens.onAccent,
        secondary: palette.accentColor,
        onSecondary: tokens.onAccent,
        surface: palette.cardBackgroundColor,
        onSurface: tokens.onSurface,
        surfaceTint: Colors.transparent,
        error: tokens.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.appBarBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: palette.cardBackgroundColor,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      extensions: [tokens],
    );
  }
}
