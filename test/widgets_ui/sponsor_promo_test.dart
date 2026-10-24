import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_sponsor_colors.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/home/support_dev_cards.dart';

import 'host.dart';

AppThemePalette get _barbie =>
    AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');
AppThemePalette get _amber =>
    AppThemeService.palettes.firstWhere((p) => p.id == 'amber');

void main() {
  // The promo is a branded surface: the ratified decision is that its gold is
  // fixed, not palette-derived. Asserted on Golden Amber - whose accent,
  // #F59E0B, is warm enough that a palette-driven promo would still look
  // plausible - AND on Pink Barbie, where it would obviously not.
  testWidgets('the promo keeps its gold on every palette', (tester) async {
    Future<Color?> badgeFor(AppThemePalette palette) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            height: 360,
            child: SupportSliderCard(cardWidth: 180),
          ),
          palette: palette,
          disableAnimations: true,
        ),
      );
      // Never pumpAndSettle here: the card's glow controller repeats forever.
      await tester.pump();
      return tester.widget<Text>(find.text('100% FREE')).style?.color;
    }

    final warm = await badgeFor(_amber);
    final cold = await badgeFor(_barbie);

    expect(warm, AppSponsorColors.gold);
    expect(cold, AppSponsorColors.gold);
    expect(warm, cold);
    // ...and specifically not the palette, which is what the old inline
    // literals would have been replaced by had the promo been "themed".
    expect(cold, isNot(PlayTorrioTokens.fromPalette(_barbie).accent));
  });

  testWidgets('the hero slide keeps its brand darks off the palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 800,
          height: 400,
          child: SupportHeroSlide(screenWidth: 800),
        ),
        palette: _barbie,
        disableAnimations: true,
        width: 800,
      ),
    );
    await tester.pump();

    expect(find.text('SUPPORT THE DEV • \$0 SUBSCRIPTION'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.diamond_rounded)).color?.toARGB32(),
      isNot(PlayTorrioTokens.fromPalette(_barbie).accent.toARGB32()),
    );
  });
}
