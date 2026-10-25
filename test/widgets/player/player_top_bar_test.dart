import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/glass_settings.dart';
import 'package:playtorrio/widgets/player/player_glass.dart';
import 'package:playtorrio/widgets/player/player_top_bar.dart';

Widget host(PlayerTopBar bar) => MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: SizedBox(width: 1200, height: 200, child: bar),
        ),
      ),
    );

PlayerTopBar bar({
  VoidCallback? onShowSources,
  bool isSourcesActive = false,
}) =>
    PlayerTopBar(
      title: 'Film',
      onBack: () {},
      onShowSources: onShowSources,
      isSourcesActive: isSourcesActive,
    );

void main() {
  setUp(() {
    GlassSettings.enabled.value = false;
  });

  testWidgets('shows a sources button that fires its callback', (tester) async {
    var taps = 0;

    await tester.pumpWidget(host(bar(onShowSources: () => taps++)));

    expect(find.byTooltip('Sources'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.source_rounded));

    expect(taps, 1);
  });

  testWidgets('disables the sources button when no callback is given',
      (tester) async {
    await tester.pumpWidget(host(bar()));

    final button = tester.widget<PlayerIconButton>(
      find.ancestor(
        of: find.byTooltip('Sources'),
        matching: find.byType(PlayerIconButton),
      ),
    );

    expect(button.onPressed, isNull);
  });
}
