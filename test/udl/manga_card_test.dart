import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/manga/manga.dart';
import 'package:playtorrio/widgets/common/poster_skeleton.dart';
import 'package:playtorrio/widgets/manga/manga_card.dart';

import '../widgets_ui/host.dart';

Manga _manga({String cover = ''}) => Manga(
  id: '1',
  title: 'Berserk',
  coverSmall: cover,
  coverNormal: cover,
  type: 'manga',
  year: '1989',
  tags: const ['Action'],
);

Widget _card(Manga manga) => SizedBox(
  width: 150,
  height: 288,
  child: MangaCard(manga: manga),
);

void main() {
  testWidgets('missing cover uses the shared poster fallback', (tester) async {
    await tester.pumpWidget(host(_card(_manga())));

    // The shared fallback draws a movie glyph; manga's deleted local copy drew
    // a broken-image glyph, so this pins which class actually rendered.
    expect(
      find.descendant(
        of: find.byType(MissingPoster),
        matching: find.byIcon(Icons.movie_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.broken_image_rounded), findsNothing);
  });

  testWidgets('renders the title and meta line', (tester) async {
    await tester.pumpWidget(host(_card(_manga())));

    expect(find.text('Berserk'), findsOneWidget);
    expect(find.textContaining('1989'), findsOneWidget);
  });

  testWidgets('a cover URL still renders without throwing', (tester) async {
    await tester.pumpWidget(host(_card(_manga(cover: 'https://example.invalid/a.jpg'))));

    expect(tester.takeException(), isNull);
  });
}
