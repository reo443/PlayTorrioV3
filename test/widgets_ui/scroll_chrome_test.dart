import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/custom_scroll_track.dart';
import 'package:playtorrio/widgets/common/flag_icon.dart';

import 'host.dart';

AppThemePalette get _amethyst => AppThemeService.palettes.first;
AppThemePalette get _barbie =>
    AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');
PlayTorrioTokens _tokens(AppThemePalette p) => PlayTorrioTokens.fromPalette(p);

/// Every decoration colour inside the track, in tree order. The thumb is the
/// one that used to be the literal #7C5CFF.
List<Color?> _decorationColours(WidgetTester tester, Finder finder) => tester
    .widgetList<Container>(
      find.descendant(of: finder, matching: find.byType(Container)),
    )
    .map((c) => (c.decoration as BoxDecoration?)?.color)
    .toList();

void main() {
  testWidgets('the scroll thumb is the palette accent, not a fixed violet', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    // barbie, because the literal this replaces was amethyst's accent: on
    // amethyst the old code would pass this assertion by accident.
    await tester.pumpWidget(
      host(
        CustomScrollTrack(controller: controller),
        palette: _barbie,
        disableAnimations: true,
      ),
    );

    final colours = _decorationColours(tester, find.byType(CustomScrollTrack));
    expect(colours, contains(_tokens(_barbie).accent));
    expect(colours, isNot(contains(const Color(0xFF7C5CFF))));
  });

  testWidgets('the scroll track recolours with the palette', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      host(
        CustomScrollTrack(controller: controller),
        palette: _amethyst,
        disableAnimations: true,
      ),
    );
    final a = _decorationColours(tester, find.byType(CustomScrollTrack));

    await tester.pumpWidget(
      host(
        CustomScrollTrack(controller: controller),
        palette: _barbie,
        disableAnimations: true,
      ),
    );
    final b = _decorationColours(tester, find.byType(CustomScrollTrack));

    expect(a, isNot(b));
  });

  testWidgets('the flag fallback globe uses the muted text token', (
    tester,
  ) async {
    // An unknown language renders the placeholder globe rather than a network
    // image, which is the only branch that paints a colour of its own.
    //
    // The text ramp is palette-independent by design (every palette is dark, so
    // text stays white at three alphas), so this asserts the *role* it now
    // reads rather than a palette delta - the delta assertion belonged to the
    // accent, and the guard is what catches a return to a raw white alpha.
    await tester.pumpWidget(
      host(const FlagIcon(language: 'klingon'), palette: _amethyst),
    );
    final a = tester.widget<Icon>(find.byType(Icon)).color;

    await tester.pumpWidget(
      host(const FlagIcon(language: 'klingon'), palette: _barbie),
    );
    final b = tester.widget<Icon>(find.byType(Icon)).color;

    expect(a, _tokens(_amethyst).textTertiary);
    expect(b, _tokens(_barbie).textTertiary);
    expect(b, isNot(Colors.white54));
  });
}
