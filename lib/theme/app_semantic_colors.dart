import 'package:flutter/material.dart';

/// The allowlist of fixed semantic colors.
///
/// These are the ONLY literal colors permitted outside the theme token layer
/// (spec §13). They do not follow [AppThemePalette] because they carry meaning
/// the user must read the same way on every palette: success/good, warning,
/// error/destructive, rating gold, peer/seed health, download state, and
/// stream quality. Everything else (surfaces, text, accents, borders) must come
/// from [PlayTorrioTokens] so it recolors with the theme.
abstract final class AppSemanticColors {
  static const Color success = Color(0xFF30A46C);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE5484D);
  static const Color destructive = Color(0xFFE5484D);
  static const Color rating = Color(0xFFFFB800);

  static const Color healthGood = Color(0xFF30A46C);
  static const Color healthMid = Color(0xFFF5A623);
  static const Color healthBad = Color(0xFFE5484D);

  static const Color downloadQueued = Color(0xFF9AA6B8);
  static const Color downloadActive = Color(0xFF3B82F6);
  static const Color downloadDone = Color(0xFF30A46C);
  static const Color downloadFailed = Color(0xFFE5484D);

  static const Color quality4k = Color(0xFF7C5CFF);
  static const Color qualityHd = Color(0xFF3B82F6);
  static const Color qualitySd = Color(0xFF9AA6B8);
}
