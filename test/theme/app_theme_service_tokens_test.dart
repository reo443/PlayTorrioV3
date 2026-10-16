import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';

void main() {
  final amethyst = AppThemeService.palettes[0];
  final amber = AppThemeService.palettes.firstWhere((p) => p.id == 'amber');

  test('createThemeData registers the token extension', () {
    final theme = AppThemeService.createThemeData(amethyst);
    expect(theme.extension<PlayTorrioTokens>(), isNotNull);
    expect(theme.extension<PlayTorrioTokens>()!.accent, amethyst.primaryColor);
  });

  test('colorScheme roles come from the palette, not a blind seed', () {
    final theme = AppThemeService.createThemeData(amethyst);
    expect(theme.colorScheme.primary, amethyst.primaryColor);
    expect(theme.colorScheme.secondary, amethyst.accentColor);
    expect(theme.colorScheme.surface, amethyst.cardBackgroundColor);
    expect(
      theme.colorScheme.onPrimary,
      PlayTorrioTokens.fromPalette(amethyst).onAccent,
    );
  });

  test('existing behavior is preserved', () {
    final theme = AppThemeService.createThemeData(amethyst);
    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, amethyst.scaffoldBackgroundColor);
    expect(theme.appBarTheme.backgroundColor, amethyst.appBarBackgroundColor);
    expect(
      theme.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<FadeUpwardsPageTransitionsBuilder>(),
    );
  });

  test('a palette with only required fields still builds tokens', () {
    const bare = AppThemePalette(
      id: 'x',
      name: 'X',
      primaryColor: Color(0xFF7C5CFF),
      accentColor: Color(0xFF00E5FF),
    );
    final t = PlayTorrioTokens.fromPalette(bare);
    expect(t.surfaceElevated, const Color(0xFF171A23));
    expect(
      AppThemeService.createThemeData(bare).extension<PlayTorrioTokens>(),
      isNotNull,
    );
  });

  testWidgets('tokens are reachable via Theme.of(context)', (tester) async {
    late PlayTorrioTokens tokens;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeService.createThemeData(amber),
        home: Builder(
          builder: (context) {
            tokens = PlayTorrioTokens.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tokens.accent, amber.primaryColor);
  });

  testWidgets('changing the palette recolors tokens through the tree', (
    tester,
  ) async {
    final original = AppThemeService.currentPalette.value;
    addTearDown(() => AppThemeService.currentPalette.value = original);

    AppThemeService.currentPalette.value = amethyst;
    late PlayTorrioTokens tokens;
    await tester.pumpWidget(
      ValueListenableBuilder<AppThemePalette>(
        valueListenable: AppThemeService.currentPalette,
        builder: (context, palette, _) => MaterialApp(
          theme: AppThemeService.createThemeData(palette),
          home: Builder(
            builder: (context) {
              tokens = PlayTorrioTokens.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(tokens.accent, amethyst.primaryColor);

    AppThemeService.currentPalette.value = amber;
    await tester.pumpAndSettle();
    expect(tokens.accent, amber.primaryColor);
    expect(tokens.surface, amber.cardBackgroundColor);
  });
}
