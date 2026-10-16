import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/theme/app_semantic_colors.dart';

/// WCAG contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final amethyst = AppThemeService.palettes[0]; // primary 0xFF7C5CFF
  final amber = AppThemeService.palettes.firstWhere((p) => p.id == 'amber');

  test('derives surfaces/accents from the palette', () {
    final t = PlayTorrioTokens.fromPalette(amethyst);
    expect(t.bgPrimary, amethyst.scaffoldBackgroundColor);
    expect(t.surface, amethyst.cardBackgroundColor);
    expect(t.accent, amethyst.primaryColor);
    expect(t.accentSecondary, amethyst.accentColor);
    expect(t.borderSubtle.a, closeTo(0.06, 0.01));
    expect(t.error, AppSemanticColors.error);
    expect(t.success, AppSemanticColors.success);
  });

  test('onAccent picks a readable foreground on every palette', () {
    for (final p in AppThemeService.palettes) {
      final t = PlayTorrioTokens.fromPalette(p);
      final luminance = t.accent.computeLuminance();
      final expected = luminance > 0.2 ? Colors.black : Colors.white;
      expect(t.onAccent, expected, reason: 'palette ${p.id}');
      expect(
        _contrast(t.onAccent, t.accent),
        greaterThanOrEqualTo(4.0),
        reason: 'palette ${p.id} foreground must stay legible on its accent',
      );
    }
    expect(PlayTorrioTokens.fromPalette(amber).onAccent, Colors.black);
    expect(PlayTorrioTokens.fromPalette(amethyst).onAccent, Colors.white);
  });

  test('two palettes yield different tokens (no shared cache)', () {
    expect(
      PlayTorrioTokens.fromPalette(amethyst).surface,
      isNot(PlayTorrioTokens.fromPalette(amber).surface),
    );
  });

  test('lerp interpolates between two token sets', () {
    final a = PlayTorrioTokens.fromPalette(amethyst);
    final b = PlayTorrioTokens.fromPalette(amber);
    final mid = a.lerp(b, 0.5);
    expect(mid.accent, Color.lerp(a.accent, b.accent, 0.5));
  });
}
