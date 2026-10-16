import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/movie/movie.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/movie/movie_card.dart';
import 'package:playtorrio/widgets/ui/app_chip.dart';

import '../widgets_ui/host.dart';

Movie _movie({String? poster}) => Movie(
  id: 'tt1',
  name: 'Dune',
  poster: poster,
  year: '2021',
  type: 'movie',
  addonBaseUrl: '',
  imdbRating: '8.0',
);

Widget _card(Movie movie, {VoidCallback? onTap}) => SizedBox(
  width: 150,
  height: 288,
  child: MovieCard(movie: movie, onTap: onTap),
);

Color? _posterFill(WidgetTester tester) => tester
    .widget<ColoredBox>(find.descendant(
      of: find.byType(MovieCard),
      matching: find.byType(ColoredBox),
    ).first)
    .color;

void main() {
  testWidgets('poster background fill uses the token surface', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_card(_movie())));

    expect(_posterFill(tester), tokens.surfaceElevated);
  });

  testWidgets('poster fill follows the selected palette', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(host(_card(_movie()), palette: last));

    expect(_posterFill(tester), PlayTorrioTokens.fromPalette(last).surfaceElevated);
    expect(
      _posterFill(tester),
      isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).surfaceElevated),
    );
  });

  testWidgets('rating is shown through the shared AppBadge', (tester) async {
    await tester.pumpWidget(host(_card(_movie())));

    final badge = tester.widget<AppBadge>(find.byType(AppBadge));
    expect(badge.tone, AppBadgeTone.rating);
    // The existing formatter drops the decimal for whole scores.
    expect(badge.label, '8');
  });

  testWidgets('tap fires the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_card(_movie(), onTap: () => taps++)));

    await tester.tap(find.byType(MovieCard));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('a missing poster falls back without throwing', (tester) async {
    await tester.pumpWidget(host(_card(_movie())));

    expect(tester.takeException(), isNull);
    expect(find.text('Dune'), findsOneWidget);
  });
}
