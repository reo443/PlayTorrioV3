import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_motion.dart';
import 'package:playtorrio/widgets/ui/skeleton_box.dart';

import 'host.dart';

void main() {
  testWidgets('reduce returns Duration.zero when animations are disabled', (
    tester,
  ) async {
    late Duration reduced;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            reduced = AppMotion.reduce(context, AppMotion.standard);
            return const SizedBox.shrink();
          },
        ),
        disableAnimations: true,
      ),
    );
    expect(reduced, Duration.zero);
  });

  testWidgets('reduce passes the duration through when animations are enabled', (
    tester,
  ) async {
    late Duration reduced;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            reduced = AppMotion.reduce(context, AppMotion.standard);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(reduced, AppMotion.standard);
  });

  testWidgets('renders a box of the requested size', (tester) async {
    await tester.pumpWidget(host(const SkeletonBox(width: 100, height: 150)));
    expect(tester.getSize(find.byType(SkeletonBox)), const Size(100, 150));
  });

  testWidgets('is static when animations are disabled', (tester) async {
    await tester.pumpWidget(
      host(const SkeletonBox(width: 100, height: 150), disableAnimations: true),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('animates when animations are enabled', (tester) async {
    await tester.pumpWidget(host(const SkeletonBox(width: 100, height: 150)));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SkeletonBox), findsOneWidget);
  });

  testWidgets('reduced motion toggled while mounted does not create a second ticker', (
    tester,
  ) async {
    // MediaQuery can change while a skeleton is on screen (the user turning
    // reduced motion on, then off). SingleTickerProviderStateMixin allows
    // exactly one ticker for the State's lifetime, so the state must not
    // dispose and rebuild its controller.
    await tester.pumpWidget(host(const SkeletonBox(width: 100, height: 150)));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(
      host(const SkeletonBox(width: 100, height: 150), disableAnimations: true),
    );
    expect(tester.takeException(), isNull);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(host(const SkeletonBox(width: 100, height: 150)));
    expect(tester.takeException(), isNull);
    expect(tester.hasRunningAnimations, isTrue);
  });
}
