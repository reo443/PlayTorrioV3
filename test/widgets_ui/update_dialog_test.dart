import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/services/updater/app_updater_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/updater/update_dialog.dart';

import 'host.dart';

UpdateInfo _info() => UpdateInfo(
  currentVersion: '3.0.0',
  latestVersion: '3.1.0',
  downloadUrl: 'https://example.invalid/playtorrio.apk',
  releaseNotes: 'Bug fixes',
  publishedAt: DateTime(2026, 1, 1),
  isMacOS: false,
);

void main() {
  testWidgets('the dialog body paints the palette elevated surface', (
    tester,
  ) async {
    final barbie = AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');

    await tester.pumpWidget(
      host(UpdateDialog(updateInfo: _info()), palette: barbie),
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(UpdateDialog),
            matching: find.byType(Container),
          )
          .first,
    );

    expect(
      (container.decoration as BoxDecoration?)?.color,
      PlayTorrioTokens.fromPalette(barbie).surfaceElevated,
    );
  });

  testWidgets('its two footer actions are shared buttons', (tester) async {
    await tester.pumpWidget(
      host(UpdateDialog(updateInfo: _info()), palette: AppThemeService.palettes.first),
    );

    expect(find.widgetWithText(AppButton, 'Later'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Update Now'), findsOneWidget);
  });
}
