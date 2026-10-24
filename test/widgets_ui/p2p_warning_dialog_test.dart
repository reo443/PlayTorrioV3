import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/p2p/p2p_warning_dialog.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';

import 'host.dart';

AppThemePalette get _amethyst => AppThemeService.palettes.first;
AppThemePalette get _barbie =>
    AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');

/// The dialog picks its layout from `MediaQuery.sizeOf`, which `host`'s width
/// cap does not change - it sees the 800x600 test surface, i.e. the *desktop*
/// branch. Pinning the media size is what selects the phone branch, and the
/// phone branch is the one every assertion here is meaningful for: under the
/// test font (every glyph one em wide) three shared buttons cannot share a
/// row, so the desktop branch would overflow for reasons that do not exist in
/// the real app.
Widget _phone(Widget child) =>
    MediaQuery(data: const MediaQueryData(size: Size(360, 800)), child: child);

void main() {
  testWidgets('the dialog surface is the palette elevated surface', (
    tester,
  ) async {
    Future<Color?> surfaceFor(AppThemePalette palette) async {
      await tester.pumpWidget(
        host(_phone(const P2pWarningDialog()), palette: palette),
      );
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(P2pWarningDialog),
              matching: find.byType(Container),
            )
            .first,
      );
      return (container.decoration as BoxDecoration?)?.color;
    }

    final a = await surfaceFor(_amethyst);
    final b = await surfaceFor(_barbie);

    expect(a, isNot(b));
    expect(b, PlayTorrioTokens.fromPalette(_barbie).surfaceElevated);
  });

  testWidgets('its three actions are shared buttons', (tester) async {
    await tester.pumpWidget(
      host(_phone(const P2pWarningDialog()), palette: _amethyst),
    );

    // "Yes, Turn Off P2P" is the emphasised action; the other two are the
    // escape hatches. A hand-rolled ElevatedButton/OutlinedButton/TextButton
    // mix would leave the dialog with three different button shapes.
    expect(find.byType(AppButton), findsNWidgets(3));
    expect(find.widgetWithText(AppButton, 'Yes, Turn Off P2P'), findsOneWidget);
    expect(find.widgetWithText(AppButton, "Don't Show Again"), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Exit'), findsOneWidget);
  });
}
