import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/continue_watching/continue_watching_item.dart';
import 'package:playtorrio/models/stream/stream_model.dart';
import 'package:playtorrio/services/continue_watching/continue_watching_service.dart';

void main() {
  group('Continue Watching Source Matching Tests', () {
    test('Matches exact source card name, title and comments (FSOnline example)', () {
      final savedItem = ContinueWatchingItem(
        id: 'tt0137523',
        title: 'Fight Club',
        type: 'movie',
        positionSeconds: 1200,
        totalDurationSeconds: 8400,
        lastWatchedAt: DateTime.now(),
        isTorrent: false,
        addonName: 'PlayTorrioHTTP',
        streamName: 'PlayTorrioHTTP',
        streamTitle: 'FSOnline · FileSuN · 1080p',
        streamDescription: 'FSOnline HLS Stream',
        quality: '1080p',
      );

      final exactMatch = StreamSource(
        name: 'PlayTorrioHTTP',
        addonName: 'PlayTorrioHTTP',
        title: 'FSOnline · FileSuN · 1080p',
        description: 'FSOnline HLS Stream',
        url: 'https://example.com/fsonline/master.m3u8',
      );

      final variantPunctuationMatch = StreamSource(
        name: 'PlayTorrioHTTP',
        addonName: 'PlayTorrioHTTP',
        title: 'FSOnline . FileSuN . 1080P',
        description: 'FSOnline HLS Stream',
        url: 'https://example.com/fsonline/master2.m3u8',
      );

      final differentScraper = StreamSource(
        name: 'PlayTorrioHTTP',
        addonName: 'PlayTorrioHTTP',
        title: 'VidFast · vRapid · 1080p',
        description: 'VidFast Direct Stream',
        url: 'https://example.com/vidfast/video.mp4',
      );

      final exactScore = ContinueWatchingService.calculateSourceMatchScore(exactMatch, savedItem);
      final variantScore = ContinueWatchingService.calculateSourceMatchScore(variantPunctuationMatch, savedItem);
      final diffScore = ContinueWatchingService.calculateSourceMatchScore(differentScraper, savedItem);

      print('Exact match score: $exactScore');
      print('Variant punctuation score: $variantScore');
      print('Different scraper score: $diffScore');

      // Exact and variant should both score > 1400 (exceeding early completion threshold of 950)
      expect(exactScore, greaterThan(1400.0));
      expect(variantScore, greaterThan(1400.0));

      // Different scraper should score much lower (under 500, well below 950)
      expect(diffScore, lessThan(500.0));
      expect(exactScore, greaterThan(diffScore + 1000.0));
    });
  });

  group('Continue Watching resume stream id', () {
    ContinueWatchingItem item({
      String id = 'tt0903747',
      String type = 'series',
      int? season = 1,
      int? episode = 5,
      String? episodeId,
    }) =>
        ContinueWatchingItem(
          id: id,
          title: 'Breaking Bad',
          type: type,
          season: season,
          episode: episode,
          episodeId: episodeId,
          positionSeconds: 60,
          totalDurationSeconds: 3000,
          lastWatchedAt: DateTime.now(),
          isTorrent: false,
        );

    test('rebuilds an IMDb episode id from a stored TMDB episode id', () {
      expect(
        ContinueWatchingService.resolveStreamId(item(episodeId: '62085')),
        'tt0903747:1:5',
      );
    });

    test('keeps a movie id untouched', () {
      expect(
        ContinueWatchingService.resolveStreamId(
          item(id: 'tt0137523', type: 'movie', season: null, episode: null),
        ),
        'tt0137523',
      );
    });

    test('keeps provider-specific episode ids untouched', () {
      expect(
        ContinueWatchingService.resolveStreamId(
          item(
            id: 'cloudstream_ep:source:data',
            episodeId: 'cloudstream_ep:source:data',
          ),
        ),
        'cloudstream_ep:source:data',
      );
    });
  });
}
