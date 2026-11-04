import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/floating_back_button.dart';

/// A root route that can push [child] onto a second route, or show
/// [homeChild] on the root route itself.
Widget _app({
  Widget? child,
  Widget? homeChild,
  AppThemePalette? palette,
}) {
  return MaterialApp(
    themeAnimationDuration: Duration.zero,
    theme: AppThemeService.createThemeData(
      palette ?? AppThemeService.palettes.first,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: homeChild ??
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(body: Center(child: child)),
                  ),
                ),
                child: const Text('open'),
              ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('stays hidden on the root route', (tester) async {
    await tester.pumpWidget(
      _app(homeChild: const FloatingBackButton()),
    );

    expect(find.byType(FloatingBackButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('appears on a pushed route and pops it', (tester) async {
    await tester.pumpWidget(_app(child: const FloatingBackButton()));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('glyph follows the palette text colour', (tester) async {
    final palette = AppThemeService.palettes.last;
    final tokens = PlayTorrioTokens.fromPalette(palette);

    await tester.pumpWidget(
      _app(palette: palette, child: const FloatingBackButton()),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(
      find.byIcon(Icons.arrow_back_ios_new_rounded),
    );
    expect(icon.color, tokens.textPrimary);
  });

  testWidgets('a custom onPressed replaces the default pop', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(child: FloatingBackButton(onPressed: () => taps++)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();

    expect(taps, 1);
    // The route was not popped, so the button is still there.
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });
}
