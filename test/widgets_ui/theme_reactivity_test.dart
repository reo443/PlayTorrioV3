import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/ui/app_card.dart';
import 'package:playtorrio/widgets/ui/app_chip.dart';
import 'package:playtorrio/widgets/ui/app_error_state.dart';
import 'package:playtorrio/widgets/ui/app_sheet.dart';
import 'package:playtorrio/widgets/ui/app_text_field.dart';
import 'package:playtorrio/widgets/ui/poster_image.dart';
import 'package:playtorrio/widgets/ui/skeleton_box.dart';

import 'host.dart';

/// The first and last palettes differ in every derived surface token, so a
/// component that recolors must resolve to two different colours under them.
AppThemePalette get _first => AppThemeService.palettes.first;
AppThemePalette get _last => AppThemeService.palettes.last;

PlayTorrioTokens _tokens(AppThemePalette palette) =>
    PlayTorrioTokens.fromPalette(palette);

/// The colour a [Container]'s decoration resolves to - the shape used by
/// components that paint a fill rather than sitting on a [Material].
Color? _decorationColor(WidgetTester tester, Finder finder) {
  final container = tester.widget<Container>(
    find.descendant(of: finder, matching: find.byType(Container)).first,
  );
  return (container.decoration as BoxDecoration?)?.color;
}

void main() {
  testWidgets('AppButton recolors when the palette changes', (tester) async {
    await tester.pumpWidget(
      host(AppButton(label: 'Play', onPressed: () {}), palette: _first),
    );
    final a = materialColorOf(tester, find.byType(AppButton));
    await tester.pumpWidget(
      host(AppButton(label: 'Play', onPressed: () {}), palette: _last),
    );
    final b = materialColorOf(tester, find.byType(AppButton));
    expect(a, isNot(b));
    expect(b, _tokens(_last).accent);
  });

  testWidgets('AppChip recolors when the palette changes', (tester) async {
    await tester.pumpWidget(
      host(const AppChip(label: 'Action', selected: true), palette: _first),
    );
    final a = materialColorOf(tester, find.byType(AppChip));
    await tester.pumpWidget(
      host(const AppChip(label: 'Action', selected: true), palette: _last),
    );
    final b = materialColorOf(tester, find.byType(AppChip));
    expect(a, isNot(b));
    expect(b, _tokens(_last).surfaceSelected);
  });

  testWidgets('AppCard recolors when the palette changes', (tester) async {
    await tester.pumpWidget(
      host(const AppCard(child: Text('x')), palette: _first),
    );
    final a = materialColorOf(tester, find.byType(AppCard));
    await tester.pumpWidget(
      host(const AppCard(child: Text('x')), palette: _last),
    );
    final b = materialColorOf(tester, find.byType(AppCard));
    expect(a, isNot(b));
    expect(b, _tokens(_last).surface);
  });

  testWidgets('AppSearchField recolors when the palette changes', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AppSearchField(), palette: _first));
    final a = tester.widget<TextField>(find.byType(TextField)).decoration?.fillColor;
    await tester.pumpWidget(host(const AppSearchField(), palette: _last));
    final b = tester.widget<TextField>(find.byType(TextField)).decoration?.fillColor;
    expect(a, isNot(b));
    expect(b, _tokens(_last).surface);
  });

  testWidgets('SkeletonBox recolors when the palette changes', (tester) async {
    await tester.pumpWidget(
      host(const SkeletonBox(width: 100, height: 150), palette: _first),
    );
    final a = _decorationColor(tester, find.byType(SkeletonBox));
    await tester.pumpWidget(
      host(const SkeletonBox(width: 100, height: 150), palette: _last),
    );
    final b = _decorationColor(tester, find.byType(SkeletonBox));
    final tokens = _tokens(_last);
    expect(a, isNot(b));
    expect(
      b,
      Color.alphaBlend(
        tokens.surface.withValues(alpha: 0.5),
        tokens.bgSecondary,
      ),
    );
  });

  testWidgets('PosterImage fallback recolors when the palette changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const PosterImage(imageUrl: null), palette: _first),
    );
    final a = tester
        .widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(PosterImage),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;
    await tester.pumpWidget(
      host(const PosterImage(imageUrl: null), palette: _last),
    );
    final b = tester
        .widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(PosterImage),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;
    expect(a, isNot(b));
    expect(b, _tokens(_last).bgSecondary);
  });

  testWidgets('AppSheet recolors when the palette changes', (tester) async {
    await tester.pumpWidget(
      host(const AppSheet(child: Text('body')), palette: _first),
    );
    final a = materialColorOf(tester, find.byType(AppSheet));
    await tester.pumpWidget(
      host(const AppSheet(child: Text('body')), palette: _last),
    );
    final b = materialColorOf(tester, find.byType(AppSheet));
    expect(a, isNot(b));
    expect(b, _tokens(_last).surfaceElevated);
  });

  testWidgets('AppErrorState recolors via its retry button', (tester) async {
    await tester.pumpWidget(
      host(AppErrorState(onRetry: () {}), palette: _first),
    );
    final retry = find.ancestor(
      of: find.text('Try again'),
      matching: find.byType(AppButton),
    );
    final a = materialColorOf(tester, retry);
    await tester.pumpWidget(
      host(AppErrorState(onRetry: () {}), palette: _last),
    );
    final b = materialColorOf(tester, retry);
    expect(a, isNot(b));
    expect(b, _tokens(_last).accent);
  });

  testWidgets('AppBadge label recolors when the palette changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const AppBadge(label: 'HDR', tone: AppBadgeTone.accent),
        palette: _first,
      ),
    );
    final a = tester.widget<Text>(find.text('HDR')).style?.color;
    await tester.pumpWidget(
      host(
        const AppBadge(label: 'HDR', tone: AppBadgeTone.accent),
        palette: _last,
      ),
    );
    final b = tester.widget<Text>(find.text('HDR')).style?.color;
    expect(a, isNot(b));
    expect(b, _tokens(_last).accent);
  });
}
