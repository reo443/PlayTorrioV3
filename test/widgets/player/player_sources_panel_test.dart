import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/movie/movie_detail.dart';
import 'package:playtorrio/models/movie/video.dart';
import 'package:playtorrio/models/stream/stream_model.dart';
import 'package:playtorrio/services/stream/playback_source_cache.dart';
import 'package:playtorrio/widgets/player/player_sources_panel.dart';

StreamSource src(String title, {String? url}) => StreamSource(
      addonName: 'AddonA',
      title: title,
      url: url,
      infoHash: url == null ? 'hash-${title.hashCode}' : null,
    );

MovieDetail movie({String id = 'tt9', String name = 'Movie'}) =>
    MovieDetail(id: id, type: 'movie', name: name);

Video episode({int season = 1, int number = 3}) => Video(
      id: 'tt9:$season:$number',
      title: 'Episode $number',
      season: season,
      episode: number,
    );

Widget host(PlayerSourcesPanel panel) => MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: SizedBox.expand(child: panel),
        ),
      ),
    );

List<String> visibleTitles(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .whereType<String>()
    .where((s) => s.startsWith('Source '))
    .toList();

void main() {
  testWidgets("renders a movie's cached sources without scraping",
      (tester) async {
    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(),
      currentAddonName: 'AddonA',
      cachedSources: [src('Source One'), src('Source Two')],
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () => throw StateError('scraped'),
    )));
    await tester.pump();

    expect(find.text('Source One'), findsOneWidget);
    expect(find.text('Source Two'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders rows in ranker order', (tester) async {
    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(),
      currentAddonName: 'AddonA',
      cachedSources: [src('Source A'), src('Source B')],
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onClose: () {},
      ranker: (sources) => sources.toList().reversed.toList(),
      sourceStream: () => throw StateError('scraped'),
    )));
    await tester.pump();

    expect(visibleTitles(tester), ['Source B', 'Source A']);
  });

  testWidgets('tapping a row reports a null episode for a movie',
      (tester) async {
    StreamSource? played;
    Video? playedEpisode;
    var calls = 0;

    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(),
      currentAddonName: 'AddonA',
      cachedSources: [src('Source One')],
      onSourcesLoaded: (_) {},
      onPlaySource: (source, episode) {
        calls++;
        played = source;
        playedEpisode = episode;
      },
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () => throw StateError('scraped'),
    )));
    await tester.pump();

    await tester.tap(find.text('Source One'));

    expect(calls, 1);
    expect(played!.title, 'Source One');
    expect(playedEpisode, isNull);
  });

  testWidgets('hides the back-to-episodes affordance for a movie',
      (tester) async {
    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(),
      currentAddonName: 'AddonA',
      cachedSources: [src('Source One')],
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onBackToEpisodes: null,
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () => throw StateError('scraped'),
    )));
    await tester.pump();

    expect(find.byTooltip('Back to Episodes'), findsNothing);

    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: episode(),
      detail: movie(),
      currentAddonName: 'AddonA',
      cachedSources: [src('Source One')],
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onBackToEpisodes: () {},
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () => throw StateError('scraped'),
    )));
    await tester.pump();

    expect(find.byTooltip('Back to Episodes'), findsOneWidget);
  });

  testWidgets('title-level scrape when there is no episode', (tester) async {
    var scraped = 0;

    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(id: 'tt9'),
      currentAddonName: 'AddonA',
      cachedSources: null,
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () {
        scraped++;
        return Stream<StreamSource>.value(src('Scraped 1080p'));
      },
    )));
    await tester.pumpAndSettle();

    expect(scraped, 1);
    expect(find.text('Scraped 1080p'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters the list with the kind chips', (tester) async {
    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(),
      currentAddonName: 'AddonA',
      cachedSources: [
        src('Source Torrent'),
        StreamSource(
          addonName: 'AddonA',
          title: 'Source Direct',
          url: 'https://cdn.example/a.m3u8',
        ),
        StreamSource(
          addonName: 'AddonA',
          name: '[RD] AddonA',
          title: 'Source Debrid',
          url: 'magnet:?xt=urn:btih:abc',
        ),
      ],
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () => throw StateError('scraped'),
    )));
    await tester.pump();

    expect(find.text('Source Torrent'), findsOneWidget);
    expect(find.text('Source Direct'), findsOneWidget);
    expect(find.text('Source Debrid'), findsOneWidget);

    await tester.tap(find.text('Direct'));
    await tester.pump();

    expect(find.text('Source Direct'), findsOneWidget);
    expect(find.text('Source Torrent'), findsNothing);
    expect(find.text('Source Debrid'), findsNothing);

    await tester.tap(find.text('Torrents'));
    await tester.pump();

    expect(find.text('Source Torrent'), findsOneWidget);
    expect(find.text('Source Direct'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pump();

    expect(find.text('Source Direct'), findsOneWidget);
    expect(find.text('Source Torrent'), findsOneWidget);
    expect(find.text('Source Debrid'), findsOneWidget);
  });

  testWidgets('chips count the sources of each kind', (tester) async {
    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(),
      currentAddonName: 'AddonA',
      cachedSources: [
        src('Source Torrent'),
        src('Source Torrent Two'),
        StreamSource(
          addonName: 'AddonA',
          title: 'Source Direct',
          url: 'https://cdn.example/a.m3u8',
        ),
      ],
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () => throw StateError('scraped'),
    )));
    await tester.pump();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Torrents'), findsOneWidget);
    expect(find.text('Direct'), findsOneWidget);
    expect(find.text('·  3'), findsOneWidget); // All
    expect(find.text('·  2'), findsOneWidget); // Torrents
    expect(find.text('·  1'), findsOneWidget); // Direct
  });

  testWidgets('offers a way back when a chip matches nothing', (tester) async {
    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(),
      currentAddonName: 'AddonA',
      cachedSources: [src('Source Torrent')],
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () => throw StateError('scraped'),
    )));
    await tester.pump();

    await tester.tap(find.text('Direct'));
    await tester.pump();

    expect(find.text('No direct sources'), findsOneWidget);

    await tester.tap(find.text('Show all'));
    await tester.pump();

    expect(find.text('Source Torrent'), findsOneWidget);
  });

  testWidgets('adopts sources the resolver is still draining', (tester) async {
    const key = 'movie:tt9:0:0';
    PlaybackSourceCache.clear();
    PlaybackSourceCache.write(key, [src('Source Early')]);

    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(),
      currentAddonName: 'AddonA',
      cacheKey: key,
      cachedSources: PlaybackSourceCache.read(key),
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () => throw StateError('scraped'),
    )));
    await tester.pump();

    expect(find.text('Source Torrent'), findsNothing);

    PlaybackSourceCache.write(
      key,
      [src('Source Early'), src('Source Torrent')],
    );
    await tester.pump();

    expect(find.text('Source Torrent'), findsOneWidget);
    expect(find.text('Source Early'), findsOneWidget);

    PlaybackSourceCache.clear();
  });

  testWidgets('uses movie wording in the empty state', (tester) async {
    await tester.pumpWidget(host(PlayerSourcesPanel(
      episode: null,
      detail: movie(),
      currentAddonName: 'AddonA',
      cachedSources: null,
      onSourcesLoaded: (_) {},
      onPlaySource: (_, __) {},
      onClose: () {},
      ranker: (sources) => sources.toList(),
      sourceStream: () => const Stream<StreamSource>.empty(),
    )));
    await tester.pumpAndSettle();

    expect(find.text('No streams found'), findsOneWidget);
  });
}
