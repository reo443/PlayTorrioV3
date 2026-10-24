import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_semantic_colors.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/ui/app_chip.dart';

import 'host.dart';

void main() {
  testWidgets('unselected chip uses the subtle border, selected uses the accent', (
    tester,
  ) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(AppChip(label: 'Action', onTap: () {})));
    expect(
      materialColorOf(tester, find.byType(AppChip)),
      isNot(tokens.surfaceSelected),
    );
    await tester.pumpWidget(
      host(AppChip(label: 'Action', selected: true, onTap: () {})),
    );
    expect(
      materialColorOf(tester, find.byType(AppChip)),
      tokens.surfaceSelected,
    );
  });

  testWidgets('chip is a labeled button for assistive tech', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(AppChip(label: 'Action', onTap: () {})));
    expect(find.bySemanticsLabel('Action'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('badge tone colors its label with the fixed semantic color', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const AppBadge(label: 'HDR', tone: AppBadgeTone.quality4k)),
    );
    final text = tester.widget<Text>(find.text('HDR'));
    expect(text.style?.color, AppSemanticColors.quality4k);
  });

  testWidgets('a very long chip label does not overflow', (tester) async {
    await tester.pumpWidget(host(AppChip(label: 'A' * 200, onTap: () {})));
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives 2x text scale without overflowing', (tester) async {
    await tester.pumpWidget(
      host(const AppBadge(label: '1080p'), textScale: 2.0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the accentSecondary tone follows the palette', (tester) async {
    final barbie = AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');

    await tester.pumpWidget(
      host(
        const AppBadge(label: 'Debrid', tone: AppBadgeTone.accentSecondary),
        palette: AppThemeService.palettes.first,
      ),
    );
    final a = tester.widget<Text>(find.text('Debrid')).style?.color;

    await tester.pumpWidget(
      host(
        const AppBadge(label: 'Debrid', tone: AppBadgeTone.accentSecondary),
        palette: barbie,
      ),
    );
    final b = tester.widget<Text>(find.text('Debrid')).style?.color;

    expect(a, isNot(b));
    expect(b, PlayTorrioTokens.fromPalette(barbie).accentSecondary);
  });
}
