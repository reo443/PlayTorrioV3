import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_semantic_colors.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/modern_toast.dart';

import '../widgets_ui/host.dart';

/// Pumps an empty host and hands back its [BuildContext] so the toast can be
/// inserted into the real root overlay, exactly as the player does.
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    host(
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return ctx;
}

Color? _iconColor(WidgetTester tester, IconData icon) =>
    tester.widget<Icon>(find.byIcon(icon)).color;

void main() {
  testWidgets('success toast uses the semantic success colour', (tester) async {
    final ctx = await _pumpHost(tester);
    ModernToast.show(ctx, message: 'Saved', type: ToastType.success);
    await tester.pump();

    expect(_iconColor(tester, Icons.check_circle_rounded), AppSemanticColors.success);

    ModernToast.dismiss();
    await tester.pump();
  });

  testWidgets('error toast uses the semantic error colour', (tester) async {
    final ctx = await _pumpHost(tester);
    ModernToast.show(ctx, message: 'Failed', type: ToastType.error);
    await tester.pump();

    expect(_iconColor(tester, Icons.cancel_rounded), AppSemanticColors.error);

    ModernToast.dismiss();
    await tester.pump();
  });

  testWidgets('info toast uses the active accent', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    final ctx = await _pumpHost(tester);
    ModernToast.show(ctx, message: 'Syncing');
    await tester.pump();

    expect(_iconColor(tester, Icons.subtitles_rounded), tokens.accent);

    ModernToast.dismiss();
    await tester.pump();
  });

  testWidgets('pill surface comes from the token surface', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    final ctx = await _pumpHost(tester);
    ModernToast.show(ctx, message: 'Syncing');
    await tester.pump();

    final pill = tester.widget<Container>(
      find.ancestor(of: find.text('Syncing'), matching: find.byType(Container)).first,
    );
    final decoration = pill.decoration! as BoxDecoration;
    expect(decoration.color, tokens.surface.withValues(alpha: 0.8));

    ModernToast.dismiss();
    await tester.pump();
  });
}
