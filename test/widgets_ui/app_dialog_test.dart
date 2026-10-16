import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/ui/app_dialog.dart';

import 'host.dart';

void main() {
  testWidgets('renders title, message and actions', (tester) async {
    await tester.pumpWidget(
      host(
        const AppDialog(
          title: 'Remove?',
          message: 'This cannot be undone',
          actions: [Text('OK')],
        ),
      ),
    );
    expect(find.text('Remove?'), findsOneWidget);
    expect(find.text('This cannot be undone'), findsOneWidget);
  });

  testWidgets('showAppDialog returns true on confirm', (tester) async {
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => AppButton(
            label: 'Ask',
            onPressed: () async => result = await showAppDialog(
              context,
              title: 'Remove?',
              message: 'Sure?',
              cancelLabel: 'Cancel',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('showAppDialog returns false on cancel', (tester) async {
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => AppButton(
            label: 'Ask',
            onPressed: () async => result = await showAppDialog(
              context,
              title: 'Remove?',
              cancelLabel: 'Cancel',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('destructive confirm uses the destructive variant', (
    tester,
  ) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => AppButton(
            label: 'Ask',
            onPressed: () => showAppDialog(
              context,
              title: 'Remove?',
              confirmLabel: 'Remove',
              destructive: true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    final confirm = find.ancestor(
      of: find.text('Remove'),
      matching: find.byType(AppButton),
    );
    expect(materialColorOf(tester, confirm), tokens.destructive);
  });
}
