import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';

void main() {
  test('createThemeData exposes PlayTorrioTokens via extensions', () {
    final palette = AppThemeService.palettes.first;
    final theme = AppThemeService.createThemeData(palette);

    final tokens = theme.extension<PlayTorrioTokens>();
    expect(tokens, isNotNull);
    expect(tokens!.accent, palette.primaryColor);
  });

  test('createThemeData builds explicit colorscheme', () {
    final palette = AppThemeService.palettes.first;
    final theme = AppThemeService.createThemeData(palette);

    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, palette.primaryColor);
    expect(theme.colorScheme.secondary, palette.accentColor);
    expect(theme.colorScheme.surface, palette.cardBackgroundColor);
  });
}
