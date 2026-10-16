import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/ui/app_card.dart';

import 'host.dart';

void main() {
  testWidgets('renders its child on the surface token color', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(const AppCard(child: Text('Hello'))));
    expect(find.text('Hello'), findsOneWidget);
    expect(materialColorOf(tester, find.byType(AppCard)), tokens.surface);
  });

  testWidgets('elevated and selected change the surface', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(const AppCard(elevated: true, child: Text('x'))),
    );
    expect(
      materialColorOf(tester, find.byType(AppCard)),
      tokens.surfaceElevated,
    );
    await tester.pumpWidget(
      host(const AppCard(selected: true, child: Text('x'))),
    );
    expect(
      materialColorOf(tester, find.byType(AppCard)),
      tokens.surfaceSelected,
    );
  });

  testWidgets('onTap fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(AppCard(onTap: () => taps++, child: const Text('x'))),
    );
    await tester.tap(find.byType(AppCard));
    expect(taps, 1);
  });

  testWidgets('a card with no onTap renders no InkWell', (tester) async {
    await tester.pumpWidget(host(const AppCard(child: Text('x'))));
    expect(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });
}
