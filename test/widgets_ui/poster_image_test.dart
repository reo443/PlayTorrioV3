import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/widgets/ui/poster_image.dart';

import 'host.dart';

void main() {
  testWidgets('null url renders the fallback, not a network image', (
    tester,
  ) async {
    await tester.pumpWidget(host(const PosterImage(imageUrl: null)));
    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty url renders the fallback', (tester) async {
    await tester.pumpWidget(host(const PosterImage(imageUrl: '')));
    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
  });

  testWidgets('a url renders a cached network image at the aspect ratio', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const PosterImage(imageUrl: 'https://example.com/a.jpg')),
    );
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    final size = tester.getSize(find.byType(PosterImage).first);
    expect(size.width / size.height, closeTo(2 / 3, 0.01));
  });

  testWidgets('backdrop keeps 16:9', (tester) async {
    await tester.pumpWidget(
      host(
        const PosterImage(
          imageUrl: 'https://example.com/a.jpg',
          aspect: MediaAspect.backdrop,
        ),
        width: 320,
      ),
    );
    final size = tester.getSize(find.byType(PosterImage).first);
    expect(size.width / size.height, closeTo(16 / 9, 0.01));
  });

  testWidgets('a custom fallback replaces the default', (tester) async {
    await tester.pumpWidget(
      host(const PosterImage(imageUrl: null, fallback: Text('none'))),
    );
    expect(find.text('none'), findsOneWidget);
  });
}
