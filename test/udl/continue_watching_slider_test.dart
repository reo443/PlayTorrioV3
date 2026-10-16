import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/continue_watching/continue_watching_item.dart';
import 'package:playtorrio/services/continue_watching/continue_watching_service.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/home/continue_watching_slider.dart';

import '../widgets_ui/host.dart';

ContinueWatchingItem _item() => ContinueWatchingItem(
  id: 'tt1',
  title: 'Dune',
  type: 'movie',
  year: '2021',
  positionSeconds: 600,
  totalDurationSeconds: 1200,
  lastWatchedAt: DateTime(2026, 1, 1),
  isTorrent: false,
  addonName: 'Stream',
);

void _withItems(List<ContinueWatchingItem> items) {
  final previous = ContinueWatchingService.activeItems.value;
  ContinueWatchingService.activeItems.value = items;
  addTearDown(() => ContinueWatchingService.activeItems.value = previous);
}

/// The accent bar is the only 4x18 container in the header.
BoxDecoration _accentBar(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere(
        (c) => c.constraints?.maxWidth == 4 && c.constraints?.maxHeight == 18,
      );
  return container.decoration! as BoxDecoration;
}

/// flutter_test's fallback font is ~1em per glyph, so "Continue Watching"
/// measures ~306px instead of ~175px with Poppins. The header Row gives the
/// title no flex, so 360px is not a representative width for it.
Widget _host({AppThemePalette? palette}) =>
    host(const ContinueWatchingSlider(), palette: palette, width: 700);

void main() {
  testWidgets('renders nothing when there is nothing to continue', (tester) async {
    _withItems(const []);
    await tester.pumpWidget(_host());

    expect(find.text('Continue Watching'), findsNothing);
  });

  testWidgets('the accent bar uses the palette accent', (tester) async {
    final last = AppThemeService.palettes.last;
    _withItems([_item()]);
    await tester.pumpWidget(_host(palette: last));

    expect(_accentBar(tester).color, PlayTorrioTokens.fromPalette(last).accent);
    expect(
      _accentBar(tester).color,
      isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).accent),
    );
  });

  testWidgets('renders the title, count and card', (tester) async {
    _withItems([_item()]);
    await tester.pumpWidget(_host());

    expect(find.text('Continue Watching'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card body uses a token surface', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    _withItems([_item()]);
    await tester.pumpWidget(_host());

    final card = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, tokens.surface.withValues(alpha: 0.75));
    expect((decoration.border! as Border).top.color, tokens.borderSubtle);
  });
}
