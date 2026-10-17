import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_glass_colors.dart';
import 'package:playtorrio/widgets/common/liquid_dock.dart';

import '../widgets_ui/host.dart';

List<DockItem> _items(int count) => [
  for (var i = 0; i < count; i++)
    DockItem(
      icon: i == 0 ? Icons.home_rounded : Icons.podcasts_rounded,
      label: 'Item $i',
      onTap: () {},
    ),
];

Future<void> _pump(WidgetTester tester, {int items = 2, double width = 360}) =>
    tester.pumpWidget(
      host(
        SizedBox(height: 140, child: LiquidDock(items: _items(items))),
        width: width,
      ),
    );

/// The dock tiles are the containers carrying both a gradient and a border;
/// the lens' own fallback surface has a gradient but no border.
List<BoxDecoration> _tiles(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .where((d) => d.gradient is LinearGradient && d.border != null)
    .toList();

void main() {
  testWidgets('the glass palette is pinned to its fixed literals', (
    tester,
  ) async {
    // Glass is white light refracted through a surface, so these values are
    // palette-independent by construction and must not drift.
    expect(AppGlassColors.shadow, const Color(0x66000000));
    expect(AppGlassColors.glyph, const Color(0xF2FFFFFF));
    expect(AppGlassColors.glyphMuted, const Color(0xB3FFFFFF));
    expect(AppGlassColors.edge, const Color(0x24FFFFFF));
    expect(AppGlassColors.fallbackRest, const [
      Color(0x24FFFFFF),
      Color(0x12FFFFFF),
    ]);
    expect(AppGlassColors.fallbackHover, const [
      Color(0x38FFFFFF),
      Color(0x1FFFFFFF),
    ]);
    expect(AppGlassColors.fallbackBorder, const Color(0x26FFFFFF));
  });

  testWidgets('the dock renders with glass effects disabled', (tester) async {
    await _pump(tester);

    expect(find.byType(LiquidDock), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the non-glass tiles use the glass palette', (tester) async {
    await _pump(tester);

    final tiles = _tiles(tester);
    expect(tiles, hasLength(2));
    expect(
      (tiles.first.gradient! as LinearGradient).colors,
      AppGlassColors.fallbackRest,
    );
    expect(
      (tiles.first.border! as Border).top.color,
      AppGlassColors.fallbackBorder,
    );

    // The glyph is the glass glyph colour, not a literal.
    expect(
      tester.widget<Icon>(find.byIcon(Icons.home_rounded)).color,
      AppGlassColors.glyph,
    );
  });

  testWidgets('a hovered tile uses the hover gradient', (tester) async {
    await _pump(tester);

    await tester.pumpAndSettle();
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.home_rounded)));
    await tester.pumpAndSettle();

    expect(
      (_tiles(tester).first.gradient! as LinearGradient).colors,
      AppGlassColors.fallbackHover,
    );
  });

  testWidgets('the dock casts its shadow from the glass palette', (
    tester,
  ) async {
    await _pump(tester);

    final shadows = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .expand((d) => d.boxShadow ?? const <BoxShadow>[])
        .map((s) => s.color)
        .toList();

    expect(shadows, contains(AppGlassColors.shadow));
  });

  testWidgets('the scroll arrows use the muted glass glyph colour', (
    tester,
  ) async {
    // 12 items overflow the available width, so the arrows appear. The dock
    // sizes itself from the screen width, so the harness box has to match the
    // test surface (800) or the dock overflows its own container.
    await _pump(tester, items: 12, width: 800);

    expect(
      tester.widget<Icon>(find.byIcon(Icons.chevron_left_rounded)).color,
      AppGlassColors.glyphMuted,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.chevron_right_rounded)).color,
      AppGlassColors.glyphMuted,
    );
  });

  testWidgets('the tiles do not follow the palette', (tester) async {
    await _pump(tester);

    final tile = _tiles(tester).first;
    expect(
      (tile.gradient! as LinearGradient).colors,
      AppGlassColors.fallbackRest,
    );
    expect(tile.color, isNull);
  });
}
