import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';

import 'host.dart';

void main() {
  testWidgets('primary renders its label and uses the theme accent', (
    tester,
  ) async {
    await tester.pumpWidget(host(AppButton(label: 'Play', onPressed: () {})));
    expect(find.text('Play'), findsOneWidget);
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    expect(materialColorOf(tester, find.byType(AppButton)), tokens.accent);
  });

  testWidgets('secondary and tertiary use a non-accent surface', (
    tester,
  ) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(
        AppButton(
          label: 'Details',
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
      ),
    );
    expect(materialColorOf(tester, find.byType(AppButton)), isNot(tokens.accent));
  });

  testWidgets('enabled button fires onPressed once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(AppButton(label: 'Play', onPressed: () => taps++)),
    );
    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('disabled button is not tappable and announces itself as disabled', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AppButton(label: 'Play')));
    final ink = tester.widget<InkWell>(
      find.descendant(of: find.byType(AppButton), matching: find.byType(InkWell)),
    );
    expect(ink.onTap, isNull);
    final announcesDisabled = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(AppButton),
            matching: find.byType(Semantics),
          ),
        )
        .any((s) => s.properties.enabled == false);
    expect(announcesDisabled, isTrue);
  });

  testWidgets('loading shows a progress indicator and blocks taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        AppButton(
          label: 'Play',
          icon: Icons.play_arrow,
          onPressed: () => taps++,
          loading: true,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });

  testWidgets('expand fills the available width', (tester) async {
    await tester.pumpWidget(
      host(AppButton(label: 'Play', onPressed: () {}, expand: true)),
    );
    expect(tester.getSize(find.byType(AppButton)).width, 360);
  });

  testWidgets('a very long label ellipsizes instead of overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(host(AppButton(label: 'A' * 200, onPressed: () {})));
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives 2x text scale without overflowing', (tester) async {
    await tester.pumpWidget(
      host(
        AppButton(label: 'Play now', icon: Icons.play_arrow, onPressed: () {}),
        textScale: 2.0,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon-only button exposes its tooltip as a semantics label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(AppIconButton(icon: Icons.search, tooltip: 'Search', onPressed: () {})),
    );
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    handle.dispose();
  });
}
