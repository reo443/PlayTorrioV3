import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';

ColorScheme _schemeOf(AppThemePalette p) =>
    AppThemeService.createThemeData(p).colorScheme;

void main() {
  final amethyst = AppThemeService.palettes[0];
  final amethystTokens = PlayTorrioTokens.fromPalette(amethyst);

  test('every widget-facing role is available and palette-derived', () {
    final cs = _schemeOf(amethyst);
    final tokens = amethystTokens;

    expect(cs.surface, amethyst.cardBackgroundColor);
    expect(cs.onSurface, tokens.onSurface);
    expect(cs.onSurfaceVariant, tokens.textSecondary);
    expect(cs.surfaceContainerLowest, amethyst.scaffoldBackgroundColor);
    expect(cs.surfaceContainerLow, amethyst.appBarBackgroundColor);
    expect(cs.surfaceContainer, amethyst.cardBackgroundColor);
    expect(cs.surfaceContainerHigh, amethyst.surfaceElevatedColor);
    expect(cs.surfaceContainerHighest, amethyst.surfaceElevatedColor);
    expect(cs.outline, tokens.borderStrong);
    expect(cs.outlineVariant, tokens.borderSubtle);
    expect(cs.inverseSurface, amethyst.surfaceElevatedColor);
    expect(cs.onInverseSurface, tokens.textPrimary);
    expect(cs.inversePrimary, amethyst.primaryColor);
    expect(cs.error, tokens.error);
    // M3 tints elevated surfaces with primary unless this is transparent, which
    // would hide palette.surfaceElevatedColor entirely.
    expect(cs.surfaceTint, Colors.transparent);
  });

  test('palette-derived roles do not come from a seed', () {
    // A seed would tint these with primary; the palette says otherwise.
    // Note: tokens.borderStrong/borderSubtle are white alphas, identical on
    // every palette, so `outline` is deliberately *not* compared here.
    for (final p in AppThemeService.palettes) {
      final cs = _schemeOf(p);
      final blend = Color.alphaBlend(
        p.accentColor.withValues(alpha: 0.20),
        p.cardBackgroundColor,
      );
      expect(cs.surfaceContainerHigh, p.surfaceElevatedColor, reason: p.id);
      expect(cs.secondaryContainer, blend, reason: p.id);
    }

    // Two palettes with different accents cannot share a container tint.
    final amber = AppThemeService.palettes.firstWhere((p) => p.id == 'amber');
    expect(
      _schemeOf(amethyst).secondaryContainer,
      isNot(_schemeOf(amber).secondaryContainer),
    );
  });

  test('a bright palette gets a palette-consistent scheme', () {
    for (final p in AppThemeService.palettes) {
      final cs = _schemeOf(p);
      final tokens = PlayTorrioTokens.fromPalette(p);
      expect(cs.primary, p.primaryColor, reason: p.id);
      expect(cs.secondary, p.accentColor, reason: p.id);
      expect(cs.surface, p.cardBackgroundColor, reason: p.id);
      expect(cs.surfaceContainerHigh, p.surfaceElevatedColor, reason: p.id);
      expect(cs.onSurface, tokens.onSurface, reason: p.id);
    }
  });

  test('a palette with only the required fields still builds', () {
    const bare = AppThemePalette(
      id: 'bare',
      name: 'Bare',
      primaryColor: Color(0xFF7C5CFF),
      accentColor: Color(0xFF00E5FF),
    );
    final cs = _schemeOf(bare);
    final tokens = PlayTorrioTokens.fromPalette(bare);

    expect(cs.surface, bare.cardBackgroundColor);
    expect(cs.surfaceContainerHigh, bare.surfaceElevatedColor);
    expect(cs.onSurface, tokens.onSurface);
    expect(cs.surfaceTint, Colors.transparent);
  });

  test('a light surface inverts the on-colours', () {
    const light = AppThemePalette(
      id: 'light',
      name: 'Light',
      primaryColor: Color(0xFF7C5CFF),
      accentColor: Color(0xFF00E5FF),
      cardBackgroundColor: Color(0xFFF5F5F7),
      scaffoldBackgroundColor: Color(0xFFFFFFFF),
      surfaceElevatedColor: Color(0xFFFFFFFF),
      appBarBackgroundColor: Color(0xFFEFEFF2),
    );
    final cs = _schemeOf(light);
    final tokens = PlayTorrioTokens.fromPalette(light);

    // onSurface is chosen by luminance, so a light card must read dark.
    expect(tokens.onSurface, Colors.black);
    expect(cs.onSurface, Colors.black);
    expect(cs.onSurface, isNot(tokens.textPrimary));
  });
}
