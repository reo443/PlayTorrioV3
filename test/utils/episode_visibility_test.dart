import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/movie/video.dart';
import 'package:playtorrio/utils/details/episode_visibility.dart';

Video _episode({int? season, int? episode}) => Video(
      id: '${season ?? 0}:${episode ?? 0}',
      title: 'Episode',
      season: season,
      episode: episode,
    );

void main() {
  group('shouldShowEpisodes', () {
    test('is false when no source has episodes', () {
      expect(
        shouldShowEpisodes(
          videos: const [],
          tmdbSeasons: const [],
          currentSeasonEpisodes: const [],
        ),
        isFalse,
      );
    });

    test('is true when the addon supplied videos', () {
      expect(
        shouldShowEpisodes(
          videos: [_episode(season: 1, episode: 1)],
          tmdbSeasons: const [],
          currentSeasonEpisodes: const [],
        ),
        isTrue,
      );
    });

    test('is true when only TMDB supplied seasons', () {
      expect(
        shouldShowEpisodes(
          videos: const [],
          tmdbSeasons: const [1, 2],
          currentSeasonEpisodes: const [],
        ),
        isTrue,
      );
    });

    test('is true when only the selected season has episodes', () {
      expect(
        shouldShowEpisodes(
          videos: const [],
          tmdbSeasons: const [],
          currentSeasonEpisodes: [_episode(season: 1, episode: 1)],
        ),
        isTrue,
      );
    });
  });

  group('shouldShowSeasonTabs', () {
    test('uses the TMDB season list when TMDB supplied the episodes', () {
      expect(
        shouldShowSeasonTabs(
          videos: const [],
          isTmdb: true,
          tmdbSeasons: const [1, 2],
        ),
        isTrue,
      );
      expect(
        shouldShowSeasonTabs(
          videos: const [],
          isTmdb: true,
          tmdbSeasons: const [1],
        ),
        isFalse,
      );
    });

    test('ignores the TMDB list when TMDB is not the source', () {
      expect(
        shouldShowSeasonTabs(
          videos: [_episode(season: 1, episode: 1)],
          isTmdb: false,
          tmdbSeasons: const [1, 2, 3],
        ),
        isFalse,
      );
    });

    test('counts distinct seasons in the addon videos', () {
      expect(
        shouldShowSeasonTabs(
          videos: [
            _episode(season: 1, episode: 1),
            _episode(season: 1, episode: 2),
            _episode(season: 2, episode: 1),
          ],
          isTmdb: false,
          tmdbSeasons: const [],
        ),
        isTrue,
      );
    });

    test('treats videos without a season as a single season', () {
      expect(
        shouldShowSeasonTabs(
          videos: [_episode(episode: 1), _episode(episode: 2)],
          isTmdb: false,
          tmdbSeasons: const [],
        ),
        isFalse,
      );
    });
  });
}
