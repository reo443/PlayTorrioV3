import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/services/theme/glass_settings.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/floating_page_actions.dart';

import 'host.dart';

void main() {
  tearDown(() => GlassSettings.enabled.value = false);

  testWidgets('renders the search disc and fires it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(FloatingPageActions(topInset: 0, onSearchTap: () => taps++)),
    );

    await tester.tap(find.byTooltip('Search'));

    expect(taps, 1);
  });

  testWidgets('has no search disc without a callback', (tester) async {
    await tester.pumpWidget(host(const FloatingPageActions(topInset: 0)));

    expect(find.byTooltip('Search'), findsNothing);
  });

  testWidgets('renders extra actions in order and fires each one', (tester) async {
    var calendar = 0;
    var fullscreen = 0;

    await tester.pumpWidget(
      host(
        FloatingPageActions(
          topInset: 0,
          onSearchTap: () {},
          actions: [
            FloatingPageAction(
              icon: Icons.calendar_month_rounded,
              tooltip: 'TV Airing Calendar',
              onTap: () => calendar++,
            ),
            FloatingPageAction(
              icon: Icons.fullscreen_rounded,
              tooltip: 'Fullscreen',
              onTap: () => fullscreen++,
            ),
          ],
        ),
      ),
    );

    final searchY = tester.getTopLeft(find.byTooltip('Search')).dy;
    final calendarY = tester.getTopLeft(find.byTooltip('TV Airing Calendar')).dy;
    final fullscreenY = tester.getTopLeft(find.byTooltip('Fullscreen')).dy;
    expect(searchY, lessThan(calendarY));
    expect(calendarY, lessThan(fullscreenY));

    await tester.tap(find.byTooltip('TV Airing Calendar'));
    await tester.tap(find.byTooltip('Fullscreen'));
    expect(calendar, 1);
    expect(fullscreen, 1);
  });

  testWidgets('starts below the status bar inset', (tester) async {
    await tester.pumpWidget(
      host(const FloatingPageActions(topInset: 24, onSearchTap: _noop)),
    );

    expect(tester.getTopLeft(find.byTooltip('Search')).dy, greaterThanOrEqualTo(24));
  });

  testWidgets('an active action uses the palette accent', (tester) async {
    final palette = AppThemeService.palettes.last;
    final tokens = PlayTorrioTokens.fromPalette(palette);

    await tester.pumpWidget(
      host(
        const FloatingPageActions(
          topInset: 0,
          actions: [
            FloatingPageAction(
              icon: Icons.fullscreen_exit_rounded,
              tooltip: 'Exit Fullscreen',
              onTap: _noop,
              isActive: true,
            ),
          ],
        ),
        palette: palette,
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.fullscreen_exit_rounded));
    expect(icon.color, tokens.accent);
  });

  testWidgets('paints a solid disc when glass effects are disabled', (tester) async {
    await tester.pumpWidget(
      host(const FloatingPageActions(topInset: 0, onSearchTap: _noop)),
    );

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('blurs behind the disc when glass effects are enabled', (tester) async {
    GlassSettings.enabled.value = true;

    await tester.pumpWidget(
      host(const FloatingPageActions(topInset: 0, onSearchTap: _noop)),
    );

    expect(find.byType(BackdropFilter), findsWidgets);
  });
}

void _noop() {}
