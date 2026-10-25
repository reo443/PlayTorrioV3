import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/movie/movie_detail.dart';
import 'package:playtorrio/models/movie/video.dart';
import 'package:playtorrio/models/stream/stream_model.dart';
import 'package:playtorrio/services/stream/auto_play_service.dart';
import 'package:playtorrio/services/stream/playback_source_cache.dart';

StreamSource http(String title, {String addon = 'AddonA'}) => StreamSource(
      addonName: addon,
      title: title,
      url: 'https://example.com/${title.hashCode}.mp4',
    );

StreamSource torrent(
  String title, {
  String addon = 'AddonA',
  String? infoHash,
}) =>
    StreamSource(
      addonName: addon,
      title: title,
      infoHash: infoHash ?? title,
    );

MovieDetail movie({
  String id = 'tt1',
  String name = 'Film',
  String? year = '2020',
  String type = 'movie',
}) =>
    MovieDetail(id: id, type: type, name: name, year: year);

AutoPlayRequest requestFor(
  MovieDetail detail, {
  Video? episode,
  String type = 'movie',
  bool isCollection = false,
}) =>
    AutoPlayRequest.forDetails(
      detail: detail,
      episode: episode,
      type: type,
      isCollection: isCollection,
    );

List<StreamSource> identity(Iterable<StreamSource> sources) =>
    sources.toList();

void main() {
  setUp(() {
    PlaybackSourceCache.clear();
    AutoPlayService.reset();
  });

  tearDown(() {
    AutoPlayService.reset();
    PlaybackSourceCache.clear();
  });

  group('AutoPlayRequest.forDetails', () {
    test('scrapes a plain movie as itself', () {
      final request = requestFor(movie());

      expect(request.scrapeType, 'movie');
      expect(request.scrapeId, 'tt1');
      expect(request.scrapeTitle, 'Film');
      expect(request.scrapeYear, 2020);
      expect(request.season, isNull);
      expect(request.episodeNumber, isNull);
      expect(request.cacheKey, 'movie:tt1:0:0');
    });

    test('scrapes a collection part as a movie with the part title and year',
        () {
      final detail = movie(
        id: 'collection-1',
        name: 'Franchise',
        year: '2001',
        type: 'collection',
      );
      final part = Video(
        id: 'part-2',
        title: 'Part Two',
        released: '2019-05-01',
      );

      final request = requestFor(
        detail,
        episode: part,
        type: 'collection',
        isCollection: true,
      );

      expect(request.scrapeType, 'movie');
      expect(request.scrapeTitle, 'Part Two');
      expect(request.scrapeYear, 2019);
      expect(request.season, isNull);
      expect(request.episodeNumber, isNull);
      expect(request.cacheKey, contains('part-2'));
    });

    test('keeps season and episode for a series', () {
      final detail = movie(id: 'tt2', type: 'series');
      final episode = Video(
        id: 'ep-3',
        title: 'Episode 3',
        season: 1,
        episode: 3,
      );

      final request = requestFor(detail, episode: episode, type: 'series');

      // The id part is the *resolved* stream id, which already carries the
      // season/episode for Stremio-style ids, so the key repeats them.
      expect(request.scrapeId, 'tt2:1:3');
      expect(request.cacheKey, 'series:tt2:1:3:1:3');
      expect(request.season, 1);
      expect(request.episodeNumber, 3);
    });
  });

  group('AutoPlayService', () {
    test('returns cached sources without scraping', () async {
      final request = requestFor(movie());
      PlaybackSourceCache.write(request.cacheKey, [
        torrent('Old 1080p'),
        http('New 720p'),
      ]);
      var factoryCalls = 0;

      final session = AutoPlayService.start(
        request,
        sourceStreamFactory: () {
          factoryCalls++;
          return const Stream<StreamSource>.empty();
        },
        ranker: identity,
      );
      final result = await session.result.timeout(const Duration(seconds: 2));

      expect(result, isNotNull);
      expect(result!.fromCache, isTrue);
      expect(result.sources, hasLength(2));
      expect(factoryCalls, 0);
    });

    test('completes early on a non-torrent source', () async {
      final controller = StreamController<StreamSource>();
      addTearDown(controller.close);
      final request = requestFor(movie());

      final session = AutoPlayService.start(
        request,
        sourceStreamFactory: () => controller.stream,
        ranker: identity,
      );
      controller.add(http('Fast 1080p'));

      final result = await session.result.timeout(const Duration(seconds: 2));

      expect(result, isNotNull);
      expect(result!.source.title, 'Fast 1080p');
      expect(result.fromCache, isFalse);
      session.cancel();
    });

    test('waits out the grace window when only torrents arrive', () async {
      final controller = StreamController<StreamSource>();
      addTearDown(controller.close);
      final request = requestFor(movie());

      final session = AutoPlayService.start(
        request,
        sourceStreamFactory: () => controller.stream,
        ranker: identity,
        earlyCompleteGrace: const Duration(milliseconds: 40),
      );
      final started = DateTime.now();
      controller.add(torrent('Slow 1080p'));

      final result = await session.result.timeout(const Duration(seconds: 2));
      final elapsed = DateTime.now().difference(started);

      expect(result, isNotNull);
      expect(result!.source.title, 'Slow 1080p');
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(30));
      session.cancel();
    });

    test('completes when the stream closes', () async {
      final controller = StreamController<StreamSource>();
      final request = requestFor(movie());

      final session = AutoPlayService.start(
        request,
        sourceStreamFactory: () => controller.stream,
        ranker: identity,
        earlyCompleteGrace: const Duration(seconds: 5),
      );
      controller.add(torrent('Closed 1080p'));
      unawaited(controller.close());

      final result = await session.result.timeout(const Duration(seconds: 2));

      expect(result, isNotNull);
      expect(result!.source.title, 'Closed 1080p');
    });

    test('returns null when the stream is empty', () async {
      final session = AutoPlayService.start(
        requestFor(movie()),
        sourceStreamFactory: () => const Stream<StreamSource>.empty(),
        ranker: identity,
      );

      expect(
        await session.result.timeout(const Duration(seconds: 2)),
        isNull,
      );
    });

    test('returns null at the hard cap', () async {
      final controller = StreamController<StreamSource>();
      addTearDown(controller.close);

      final session = AutoPlayService.start(
        requestFor(movie()),
        sourceStreamFactory: () => controller.stream,
        ranker: identity,
        hardCap: const Duration(milliseconds: 40),
      );

      expect(
        await session.result.timeout(const Duration(seconds: 2)),
        isNull,
      );
      session.cancel();
    });

    test('cancel before any source completes the result with null', () async {
      final controller = StreamController<StreamSource>();
      addTearDown(controller.close);
      final request = requestFor(movie());

      final session = AutoPlayService.start(
        request,
        sourceStreamFactory: () => controller.stream,
        ranker: identity,
      );
      session.cancel();
      controller.add(http('Late 1080p'));

      expect(await session.result, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(PlaybackSourceCache.read(request.cacheKey), isNull);
    });

    test('starting twice for the same key returns the same session', () {
      final controller = StreamController<StreamSource>();
      addTearDown(controller.close);
      final request = requestFor(movie());

      final first = AutoPlayService.start(
        request,
        sourceStreamFactory: () => controller.stream,
        ranker: identity,
      );
      final second = AutoPlayService.start(
        request,
        sourceStreamFactory: () => throw StateError('second factory ran'),
        ranker: identity,
      );

      expect(identical(first, second), isTrue);
      first.cancel();
    });

    test('keeps draining into the cache after completing', () async {
      final controller = StreamController<StreamSource>();
      addTearDown(controller.close);
      final request = requestFor(movie());

      final session = AutoPlayService.start(
        request,
        sourceStreamFactory: () => controller.stream,
        ranker: identity,
      );
      controller.add(http('First 1080p'));
      expect(
        await session.result.timeout(const Duration(seconds: 2)),
        isNotNull,
      );

      controller.add(torrent('Second 720p'));
      await Future<void>.delayed(Duration.zero);

      final cached = PlaybackSourceCache.read(request.cacheKey);
      expect(cached, isNotNull);
      expect(cached!.map((s) => s.title), contains('Second 720p'));
      session.cancel();
    });

    test('deduplicates identical sources', () async {
      final controller = StreamController<StreamSource>();
      final request = requestFor(movie());

      final session = AutoPlayService.start(
        request,
        sourceStreamFactory: () => controller.stream,
        ranker: identity,
        earlyCompleteGrace: const Duration(seconds: 5),
      );
      controller.add(torrent('Dup 1080p', infoHash: 'same'));
      controller.add(torrent('Dup 1080p', infoHash: 'same'));
      unawaited(controller.close());

      final result = await session.result.timeout(const Duration(seconds: 2));

      expect(result!.sources, hasLength(1));
    });

    test('uses the injected ranker for the chosen source', () async {
      final controller = StreamController<StreamSource>();
      final request = requestFor(movie());

      final session = AutoPlayService.start(
        request,
        sourceStreamFactory: () => controller.stream,
        ranker: (sources) => sources.toList().reversed.toList(),
        earlyCompleteGrace: const Duration(seconds: 5),
      );
      controller.add(torrent('First 1080p', infoHash: 'a'));
      controller.add(torrent('Second 720p', infoHash: 'b'));
      unawaited(controller.close());

      final result = await session.result.timeout(const Duration(seconds: 2));

      expect(result!.source.title, 'Second 720p');
    });

    test('drain cap stops recording without cancelling the source stream',
        () async {
      var cancelled = false;
      final controller = StreamController<StreamSource>(
        onCancel: () => cancelled = true,
      );
      final request = requestFor(movie());

      final session = AutoPlayService.start(
        request,
        sourceStreamFactory: () => controller.stream,
        ranker: identity,
        drainCap: const Duration(milliseconds: 20),
      );
      controller.add(http('First 1080p'));
      expect(
        await session.result.timeout(const Duration(seconds: 2)),
        isNotNull,
      );

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(cancelled, isFalse);

      controller.add(torrent('Late 720p'));
      await Future<void>.delayed(Duration.zero);
      expect(
        PlaybackSourceCache.read(request.cacheKey)!.map((s) => s.title),
        isNot(contains('Late 720p')),
      );
      await controller.close();
    });
  });
}
