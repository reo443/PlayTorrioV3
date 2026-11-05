import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/stream/stream_model.dart';
import 'package:playtorrio/services/scraper/sites/source_liveness.dart';

StreamSource source(String title, {String? url = 'https://example.com/stream.m3u8'}) =>
    StreamSource(addonName: 'PlayTorrioHTTP', title: title, url: url);

/// Collects the filtered stream into a list.
Future<List<StreamSource>> collect(
  Stream<StreamSource> sources, {
  SourceProbe? probe,
}) async {
  if (probe == null) return filterLiveSources(sources).toList();
  return filterLiveSources(sources, probe: probe).toList();
}

void main() {
  group('filterLiveSources', () {
    test('drops sources the probe rejects and keeps the ones it accepts', () async {
      final dead = source('dead');
      final live = source('live');

      final result = await collect(
        Stream.fromIterable([dead, live]),
        probe: (s) async => s.title == 'live',
      );

      expect(result, [live]);
    });

    test('a probe that throws drops only that source', () async {
      final first = source('first');
      final broken = source('broken');
      final last = source('last');

      final result = await collect(
        Stream.fromIterable([first, broken, last]),
        probe: (s) async {
          if (s.title == 'broken') throw StateError('probe blew up');
          return true;
        },
      );

      expect(result, [first, last]);
    });

    test('preserves the arrival order of the accepted sources', () async {
      final a = source('a');
      final b = source('b');
      final c = source('c');
      final d = source('d');

      final result = await collect(
        Stream.fromIterable([a, b, c, d]),
        probe: (s) async => s.title != 'b',
      );

      expect(result.map((s) => s.title), ['a', 'c', 'd']);
    });

    test('probes every source exactly once', () async {
      final seen = <String>[];
      final sources = [source('a'), source('b'), source('c')];

      await collect(
        Stream.fromIterable(sources),
        probe: (s) async {
          seen.add(s.title!);
          return true;
        },
      );

      expect(seen, ['a', 'b', 'c']);
    });

    test('an empty stream yields nothing', () async {
      final result = await collect(const Stream<StreamSource>.empty());
      expect(result, isEmpty);
    });

    test('default probe drops a source without a probeable URL', () async {
      final noUrl = source('no url', url: null);
      final notHttp = source('not http', url: 'magnet:?xt=urn:btih:abc');

      final result = await collect(Stream.fromIterable([noUrl, notHttp]));

      expect(result, isEmpty);
    });

    test('default probe keeps a torrent source without touching the network', () async {
      final torrent = StreamSource(addonName: 'PlayTorrio', title: 'torrent', infoHash: 'abc123');

      final result = await collect(Stream.fromIterable([torrent]));

      expect(result, [torrent]);
    });
  });
}
