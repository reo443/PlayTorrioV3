import 'package:flutter/material.dart';

import '../services/theme/app_theme_service.dart';
import 'app_semantic_colors.dart';

/// The theme-driven design tokens exposed as a [ThemeExtension].
///
/// Every surface/text/accent value derives from the active [AppThemePalette],
/// so reading them through [PlayTorrioTokens.of] recolors live when the user
/// changes theme. Fixed semantic colors come from [AppSemanticColors].
@immutable
class PlayTorrioTokens extends ThemeExtension<PlayTorrioTokens> {
  const PlayTorrioTokens({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSelected,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentSecondary,
    required this.focusRing,
    required this.destructive,
    required this.success,
    required this.warning,
    required this.error,
    required this.onAccent,
    required this.onSurface,
  });

  final Color bgPrimary;
  final Color bgSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSelected;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentSecondary;
  final Color focusRing;
  final Color destructive;
  final Color success;
  final Color warning;
  final Color error;
  final Color onAccent;
  final Color onSurface;

  factory PlayTorrioTokens.fromPalette(AppThemePalette palette) {
    final onAccent = palette.primaryColor.computeLuminance() > 0.2
        ? Colors.black
        : Colors.white;
    final onSurface = palette.cardBackgroundColor.computeLuminance() > 0.2
        ? Colors.black
        : Colors.white;
    return PlayTorrioTokens(
      bgPrimary: palette.scaffoldBackgroundColor,
      bgSecondary: palette.backgroundSecondaryColor,
      surface: palette.cardBackgroundColor,
      surfaceElevated: palette.surfaceElevatedColor,
      surfaceSelected: Color.alphaBlend(
        palette.primaryColor.withValues(alpha: 0.20),
        palette.cardBackgroundColor,
      ),
      borderSubtle: Colors.white.withValues(alpha: 0.06),
      borderStrong: Colors.white.withValues(alpha: 0.12),
      textPrimary: Colors.white.withValues(alpha: 0.95),
      textSecondary: Colors.white.withValues(alpha: 0.62),
      textTertiary: Colors.white.withValues(alpha: 0.42),
      accent: palette.primaryColor,
      accentSecondary: palette.accentColor,
      focusRing: palette.primaryColor,
      destructive: AppSemanticColors.destructive,
      success: AppSemanticColors.success,
      warning: AppSemanticColors.warning,
      error: AppSemanticColors.error,
      onAccent: onAccent,
      onSurface: onSurface,
    );
  }

  /// Reads the tokens from the ambient theme, falling back to the current
  /// palette when used outside a themed subtree (e.g. tests, overlays).
  static PlayTorrioTokens of(BuildContext context) {
    return Theme.of(context).extension<PlayTorrioTokens>() ??
        PlayTorrioTokens.fromPalette(AppThemeService.currentPalette.value);
  }

  @override
  PlayTorrioTokens copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSelected,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentSecondary,
    Color? focusRing,
    Color? destructive,
    Color? success,
    Color? warning,
    Color? error,
    Color? onAccent,
    Color? onSurface,
  }) {
    return PlayTorrioTokens(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      focusRing: focusRing ?? this.focusRing,
      destructive: destructive ?? this.destructive,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      onAccent: onAccent ?? this.onAccent,
      onSurface: onSurface ?? this.onSurface,
    );
  }

  @override
  PlayTorrioTokens lerp(covariant PlayTorrioTokens? other, double t) {
    if (other == null) return this;
    return PlayTorrioTokens(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary:
          Color.lerp(accentSecondary, other.accentSecondary, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
    );
  }
}
