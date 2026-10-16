import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/anime/anime_media.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/anime/anime_card.dart';
import 'package:playtorrio/widgets/ui/app_chip.dart';

import '../widgets_ui/host.dart';

AnimeMedia _anime({int score = 87, int popularity = 0}) => AnimeMedia(
  id: 1,
  titleRomaji: 'Cowboy Bebop',
  format: 'TV',
  totalEpisodes: 26,
  averageScore: score,
  popularity: popularity,
  seasonYear: 1998,
  genres: const ['Action'],
);

Widget _card(AnimeMedia anime, {VoidCallback? onTap}) => SizedBox(
  width: 150,
  height: 288,
  child: AnimeCard(anime: anime, onTap: onTap ?? () {}),
);

void main() {
  testWidgets('score is shown through the shared rating badge', (tester) async {
    await tester.pumpWidget(host(_card(_anime())));

    final badge = tester.widget<AppBadge>(find.byType(AppBadge).first);
    expect(badge.tone, AppBadgeTone.rating);
  });

  testWidgets('popularity falls back to the warning badge', (tester) async {
    await tester.pumpWidget(host(_card(_anime(score: 0, popularity: 4200))));

    final badge = tester.widget<AppBadge>(find.byType(AppBadge).first);
    expect(badge.tone, AppBadgeTone.warning);
  });

  testWidgets('episode count uses the neutral badge', (tester) async {
    await tester.pumpWidget(host(_card(_anime())));

    final eps = tester
        .widgetList<AppBadge>(find.byType(AppBadge))
        .firstWhere((b) => b.label.endsWith('EPS'));
    expect(eps.tone, AppBadgeTone.neutral);
  });

  testWidgets('format pill follows the palette accent', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(host(_card(_anime()), palette: last));

    final pill = tester.widget<Container>(
      find.ancestor(of: find.text('TV'), matching: find.byType(Container)).first,
    );
    final decoration = pill.decoration! as BoxDecoration;
    expect(
      decoration.color,
      PlayTorrioTokens.fromPalette(last).accent.withValues(alpha: 0.90),
    );
  });

  testWidgets('tap fires the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 150,
          height: 288,
          child: AnimeCard(anime: _anime(), onTap: () => taps++),
        ),
      ),
    );

    await tester.tap(find.byType(AnimeCard));
    await tester.pump();

    expect(taps, 1);
  });
}
