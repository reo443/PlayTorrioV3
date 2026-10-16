import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/poster_skeleton.dart';
import 'package:playtorrio/widgets/ui/skeleton_box.dart';

import '../widgets_ui/host.dart';

Color? _missingPosterSurface(WidgetTester tester) {
  final box = tester.widget<ColoredBox>(
    find
        .descendant(of: find.byType(MissingPoster), matching: find.byType(ColoredBox))
        .first,
  );
  return box.color;
}

void main() {
  testWidgets('PosterSkeleton renders the shared SkeletonBox', (tester) async {
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: PosterSkeleton())),
    );

    expect(find.byType(SkeletonBox), findsOneWidget);
  });

  testWidgets('PosterSkeleton fills its frame squarely', (tester) async {
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: PosterSkeleton())),
    );

    final skeleton = tester.widget<SkeletonBox>(find.byType(SkeletonBox));
    expect(skeleton.radius, BorderRadius.zero);
  });

  testWidgets('PosterSkeleton is static under reduced motion', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(width: 120, height: 180, child: PosterSkeleton()),
        disableAnimations: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('PosterSkeleton shimmers when motion is allowed', (tester) async {
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: PosterSkeleton())),
    );

    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('MissingPoster uses the token surface and tertiary icon', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: MissingPoster())),
    );

    expect(_missingPosterSurface(tester), tokens.surfaceElevated);
    final icon = tester.widget<Icon>(
      find.descendant(of: find.byType(MissingPoster), matching: find.byType(Icon)),
    );
    expect(icon.color, tokens.textTertiary);
  });

  testWidgets('MissingPoster follows the selected palette', (tester) async {
    final last = AppThemeService.palettes.last;
    final first = AppThemeService.palettes.first;
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: MissingPoster()), palette: last),
    );

    expect(
      _missingPosterSurface(tester),
      PlayTorrioTokens.fromPalette(last).surfaceElevated,
    );
    expect(
      _missingPosterSurface(tester),
      isNot(PlayTorrioTokens.fromPalette(first).surfaceElevated),
    );
  });
}
