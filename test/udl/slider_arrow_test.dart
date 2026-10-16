import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/slider_arrow.dart';

import '../widgets_ui/host.dart';

Widget _arrow({VoidCallback? onTap}) => Center(
  child: SliderArrow(icon: Icons.arrow_forward_ios_rounded, onTap: onTap ?? () {}),
);

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(SliderArrow),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('resting fill and border come from the tokens', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_arrow()));

    final decoration = _decoration(tester);
    expect(decoration.color, tokens.bgPrimary.withValues(alpha: 0.5));
    expect(
      (decoration.border! as Border).top.color,
      tokens.textPrimary.withValues(alpha: 0.1),
    );
  });

  testWidgets('hover lifts the fill and border', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_arrow()));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(SliderArrow)));
    await tester.pumpAndSettle();

    final decoration = _decoration(tester);
    expect(decoration.color, tokens.textPrimary.withValues(alpha: 0.15));
    expect(
      (decoration.border! as Border).top.color,
      tokens.textPrimary.withValues(alpha: 0.3),
    );
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('resting fill follows the selected palette', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(host(_arrow(), palette: last));

    expect(
      _decoration(tester).color,
      PlayTorrioTokens.fromPalette(last).bgPrimary.withValues(alpha: 0.5),
    );
    expect(
      _decoration(tester).color,
      isNot(
        PlayTorrioTokens.fromPalette(
          AppThemeService.palettes.first,
        ).bgPrimary.withValues(alpha: 0.5),
      ),
    );
  });

  testWidgets('tap fires the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_arrow(onTap: () => taps++)));

    await tester.tap(find.byType(SliderArrow));
    await tester.pump();

    expect(taps, 1);
  });
}
