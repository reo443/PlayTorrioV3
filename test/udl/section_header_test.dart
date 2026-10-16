import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_typography.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/section_header.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';

import '../widgets_ui/host.dart';

void main() {
  testWidgets('title uses the section heading scale', (tester) async {
    await tester.pumpWidget(host(const SectionHeader(title: 'Trending')));

    final title = tester.widget<Text>(find.text('Trending'));
    expect(title.style!.fontSize, AppTypography.screenTitle.fontSize);
    expect(title.style!.fontWeight, AppTypography.screenTitle.fontWeight);
  });

  testWidgets('subtitle uses the token tertiary colour', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(const SectionHeader(title: 'Trending', subtitle: 'This week')),
    );

    final subtitle = tester.widget<Text>(find.text('This week'));
    expect(subtitle.style!.color, tokens.textTertiary);
  });

  testWidgets('onSeeAll renders a shared AppButton that fires the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(SectionHeader(title: 'Trending', onSeeAll: () => taps++)),
    );

    expect(find.byType(AppButton), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('no see-all control without onSeeAll', (tester) async {
    await tester.pumpWidget(host(const SectionHeader(title: 'Trending')));

    expect(find.byType(AppButton), findsNothing);
    expect(find.text('See All'), findsNothing);
  });
}
