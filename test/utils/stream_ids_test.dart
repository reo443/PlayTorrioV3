import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/utils/stream/stream_ids.dart';

void main() {
  group('resolveEpisodeStreamId', () {
    test('keeps an id that is already an IMDb episode id', () {
      expect(
        resolveEpisodeStreamId(
          detailId: 'tt0903747',
          episodeId: 'tt0903747:1:5',
          season: 1,
          episode: 5,
        ),
        'tt0903747:1:5',
      );
    });

    test('rebuilds an IMDb episode id from a numeric TMDB episode id', () {
      expect(
        resolveEpisodeStreamId(
          detailId: 'tt0903747',
          episodeId: '62085',
          season: 1,
          episode: 5,
        ),
        'tt0903747:1:5',
      );
    });

    test('rebuilds the id when the episode carries no id at all', () {
      expect(
        resolveEpisodeStreamId(
          detailId: 'tt0903747',
          season: 2,
          episode: 3,
        ),
        'tt0903747:2:3',
      );
    });

    test('keeps a provider-specific episode id', () {
      expect(
        resolveEpisodeStreamId(
          detailId: 'cloudstream_ep:source:data',
          episodeId: 'cloudstream_ep:source:data',
          season: 1,
          episode: 2,
        ),
        'cloudstream_ep:source:data',
      );
    });

    test('cannot rebuild without an IMDb show id, so it keeps the TMDB id', () {
      expect(
        resolveEpisodeStreamId(
          detailId: 'tmdb:1396',
          episodeId: '62085',
          season: 1,
          episode: 5,
        ),
        '62085',
      );
    });

    test('falls back to show id plus numbers for a non-IMDb provider', () {
      expect(
        resolveEpisodeStreamId(
          detailId: 'anilist:1',
          season: 1,
          episode: 4,
        ),
        'anilist:1:1:4',
      );
    });

    test('returns an empty id when there is nothing to build from', () {
      expect(resolveEpisodeStreamId(detailId: ''), '');
    });
  });
}
