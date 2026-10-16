import 'package:flutter_test/flutter_test.dart';

import 'package:playtorrio/models/movie/movie.dart';
import 'package:playtorrio/models/movie/movie_detail.dart';
import 'package:playtorrio/services/metadata/tmdb_service.dart';

void main() {
  group('Movie.fromTmdb', () {
    test('maps a movie list item', () {
      final movie = Movie.fromTmdb({
        'id': 123,
        'media_type': 'movie',
        'title': 'Test',
        'poster_path': '/x.jpg',
        'release_date': '2024-05-01',
        'vote_average': 7.2,
        'popularity': 50.3,
        'genre_ids': [28],
      }, 'movie');

      expect(movie.id, 'tmdb:123');
      expect(movie.name, 'Test');
      expect(movie.type, 'movie');
      expect(movie.poster, 'https://image.tmdb.org/t/p/w500/x.jpg');
      expect(movie.year, '2024');
      expect(movie.imdbRating, '7.2');
      expect(movie.popularity, 50.3);
      expect(movie.addonBaseUrl, TmdbService.kSentinel);
    });

    test('maps a series item using name and first_air_date', () {
      final movie = Movie.fromTmdb({
        'id': 456,
        'media_type': 'tv',
        'name': 'Show',
        'first_air_date': '2023-01-01',
        'poster_path': '/y.jpg',
      }, 'tv');

      expect(movie.id, 'tmdb:456');
      expect(movie.name, 'Show');
      expect(movie.type, 'series');
      expect(movie.year, '2023');
      expect(movie.poster, 'https://image.tmdb.org/t/p/w500/y.jpg');
    });
  });

  group('TmdbService', () {
    test('exposes the tmdb sentinel', () {
      expect(TmdbService.kSentinel, 'tmdb');
    });

    test('catalogTitle returns human readable titles', () {
      expect(TmdbService.catalogTitle('trending_day'), 'Trending Today');
      expect(TmdbService.catalogTitle('trending_week'), 'Trending This Week');
      expect(TmdbService.catalogTitle('popular_movie'), 'Popular Movies');
      expect(TmdbService.catalogTitle('popular_series'), 'Popular Series');
      expect(TmdbService.catalogTitle('some_unknown_list'), isNotEmpty);
    });

    test('imageUrl builds tmdb image urls', () {
      expect(TmdbService.imageUrl('/a.jpg'), 'https://image.tmdb.org/t/p/w500/a.jpg');
      expect(TmdbService.imageUrl('/a.jpg', size: 'original'),
          'https://image.tmdb.org/t/p/original/a.jpg');
      expect(TmdbService.imageUrl(null), '');
      expect(TmdbService.imageUrl(''), '');
    });

    test('isConfigured is false without an api key', () {
      expect(TmdbService.isConfigured, isFalse);
    });

    test('fetchList returns empty when unconfigured (never throws)', () async {
      expect(await TmdbService.fetchList('trending_day'), isEmpty);
      expect(await TmdbService.fetchList('genre_movie_28'), isEmpty);
    });
  });

  group('MovieDetail.fromTmdb', () {
    test('maps movie details, resolving the IMDb id', () {
      final detail = MovieDetail.fromTmdb({
        'id': 123,
        'title': 'Test Movie',
        'overview': 'A plot',
        'release_date': '2024-05-01',
        'runtime': 120,
        'poster_path': '/p.jpg',
        'backdrop_path': '/b.jpg',
        'genres': [
          {'id': 28, 'name': 'Action'},
          {'id': 12, 'name': 'Adventure'},
        ],
        'external_ids': {'imdb_id': 'tt123'},
        'credits': {
          'cast': [
            {'name': 'Actor One'},
            {'name': 'Actor Two'},
          ],
          'crew': [
            {'name': 'Dir Person', 'job': 'Director'},
          ],
        },
      }, 'movie');

      expect(detail.id, 'tt123');
      expect(detail.tmdbId, '123');
      expect(detail.type, 'movie');
      expect(detail.name, 'Test Movie');
      expect(detail.description, 'A plot');
      expect(detail.cast, ['Actor One', 'Actor Two']);
      expect(detail.director, ['Dir Person']);
      expect(detail.genres, ['Action', 'Adventure']);
      expect(detail.poster, 'https://image.tmdb.org/t/p/w500/p.jpg');
      expect(detail.background, 'https://image.tmdb.org/t/p/original/b.jpg');
      expect(detail.year, '2024');
    });

    test('series without an imdb id falls back to a tmdb id', () {
      final detail = MovieDetail.fromTmdb({
        'id': 456,
        'name': 'Test Show',
        'first_air_date': '2023-01-01',
        'external_ids': <String, dynamic>{},
        'created_by': [
          {'name': 'Creator Person'},
        ],
      }, 'tv');

      expect(detail.id, 'tmdb:456');
      expect(detail.tmdbId, '456');
      expect(detail.type, 'series');
      expect(detail.year, '2023');
      expect(detail.director, ['Creator Person']);
    });

    test('captures series season numbers (sorted)', () {
      final detail = MovieDetail.fromTmdb({
        'id': 789,
        'name': 'Multi Season',
        'external_ids': <String, dynamic>{},
        'seasons': [
          {'season_number': 2, 'name': 'Season 2'},
          {'season_number': 0, 'name': 'Specials'},
          {'season_number': 1, 'name': 'Season 1'},
        ],
      }, 'tv');

      expect(detail.seasons, [0, 1, 2]);
    });

    test('movies have no seasons', () {
      final detail = MovieDetail.fromTmdb({
        'id': 1,
        'title': 'A Movie',
        'external_ids': <String, dynamic>{},
      }, 'movie');

      expect(detail.seasons, isEmpty);
    });
  });

  group('TmdbService.seasonEpisodesFromJson', () {
    test('maps episodes with season and episode numbers', () {
      final videos = TmdbService.seasonEpisodesFromJson({
        'season_number': 2,
        'episodes': [
          {
            'id': 1,
            'name': 'Pilot',
            'episode_number': 1,
            'overview': 'o1',
            'still_path': '/s1.jpg',
            'air_date': '2023-01-01',
          },
          {'id': 2, 'name': 'Second', 'episode_number': 2},
        ],
      }, 2);

      expect(videos.length, 2);
      expect(videos.first.season, 2);
      expect(videos.first.episode, 1);
      expect(videos.first.title, 'Pilot');
      expect(videos.first.overview, 'o1');
      expect(videos.first.thumbnail, 'https://image.tmdb.org/t/p/w500/s1.jpg');
      expect(videos[1].episode, 2);
    });

    test('missing episodes list yields empty', () {
      expect(TmdbService.seasonEpisodesFromJson({'season_number': 1}, 1), isEmpty);
    });
  });

  group('TmdbService.findResultFromJson', () {
    test('prefers a movie result', () {
      final r = TmdbService.findResultFromJson({
        'movie_results': [
          {'id': 10},
        ],
        'tv_results': <dynamic>[],
      });
      expect(r?.type, 'movie');
      expect(r?.tmdbId, '10');
    });

    test('falls back to a tv result', () {
      final r = TmdbService.findResultFromJson({
        'movie_results': <dynamic>[],
        'tv_results': [
          {'id': 20},
        ],
      });
      expect(r?.type, 'series');
      expect(r?.tmdbId, '20');
    });

    test('returns null when nothing matches', () {
      expect(
        TmdbService.findResultFromJson({
          'movie_results': <dynamic>[],
          'tv_results': <dynamic>[],
        }),
        isNull,
      );
    });
  });

  group('TmdbService.homeLists', () {
    test('are non-empty, unique and each have a title', () {
      expect(TmdbService.homeLists, isNotEmpty);
      final ids = TmdbService.homeLists.map((e) => e.listId).toList();
      expect(ids.toSet().length, ids.length);
      for (final list in TmdbService.homeLists) {
        expect(list.type, isIn(['movie', 'series']));
        expect(TmdbService.catalogTitle(list.listId), isNotEmpty);
      }
    });

    test('pageSize matches the TMDB API page size', () {
      expect(TmdbService.pageSize, 20);
    });
  });

  group('TmdbService.genresFromJson', () {
    test('maps genre id/name pairs and skips malformed entries', () {
      final genres = TmdbService.genresFromJson({
        'genres': [
          {'id': 28, 'name': 'Action'},
          {'id': '35', 'name': 'Comedy'},
          {'name': 'No Id'},
          {'id': 99},
        ],
      });

      expect(genres.length, 2);
      expect(genres.first.id, 28);
      expect(genres.first.name, 'Action');
      expect(genres[1].id, 35);
      expect(genres[1].name, 'Comedy');
    });

    test('missing genres list yields empty', () {
      expect(TmdbService.genresFromJson(<String, dynamic>{}), isEmpty);
    });
  });
}
