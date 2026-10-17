import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';

const _home = SizedBox(width: 300, height: 300);

Widget _app(Widget child, AppThemePalette palette) => MaterialApp(
  theme: AppThemeService.createThemeData(palette),
  home: Scaffold(body: Builder(builder: (_) => child)),
);

/// The colour of the first [Material] inside [finder]'s subtree.
Color? _fillOf(WidgetTester tester, Finder finder) => tester
    .widget<Material>(
      find.descendant(of: finder, matching: find.byType(Material)).first,
    )
    .color;

void main() {
  final amethyst = AppThemeService.palettes[0];
  final cs = AppThemeService.createThemeData(amethyst).colorScheme;

  testWidgets('a dialog paints the elevated surface', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const Dialog(child: _home),
            ),
            child: const Text('open'),
          ),
        ),
        amethyst,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(_fillOf(tester, find.byType(Dialog)), amethyst.surfaceElevatedColor);
  });

  testWidgets('a snackbar paints the inverse surface', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('hi'))),
            child: const Text('show'),
          ),
        ),
        amethyst,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(_fillOf(tester, find.byType(SnackBar)), cs.inverseSurface);
  });

  testWidgets('a bottom sheet paints the low container', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => _home,
            ),
            child: const Text('open'),
          ),
        ),
        amethyst,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(_fillOf(tester, find.byType(BottomSheet)), cs.surfaceContainerLow);
  });

  testWidgets('a dialog recolours when the palette changes', (tester) async {
    final original = AppThemeService.currentPalette.value;
    addTearDown(() => AppThemeService.currentPalette.value = original);
    AppThemeService.currentPalette.value = amethyst;

    await tester.pumpWidget(
      ValueListenableBuilder<AppThemePalette>(
        valueListenable: AppThemeService.currentPalette,
        builder: (context, palette, _) => MaterialApp(
          theme: AppThemeService.createThemeData(palette),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const Dialog(child: _home),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final amber = AppThemeService.palettes.firstWhere((p) => p.id == 'amber');
    AppThemeService.currentPalette.value = amber;
    await tester.pumpAndSettle();

    expect(_fillOf(tester, find.byType(Dialog)), amber.surfaceElevatedColor);
    expect(
      _fillOf(tester, find.byType(Dialog)),
      isNot(amethyst.surfaceElevatedColor),
    );
  });
}
