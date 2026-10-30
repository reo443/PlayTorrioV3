import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/movie/movie.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/movie/tmdb_person.dart';
import '../../models/movie/video.dart';
import '../config/env_service.dart';

/// TMDB metadata + catalog source for movies & TV.
///
/// Static, mirroring [MetadataService]: in-memory caches, and every fetch is
/// null-safe/empty-safe — a failure (missing key, 401, network error) never
/// throws across a page boundary.
class TmdbService {
  TmdbService._();

  /// Sentinel `addonBaseUrl` marking items and catalogs that come from TMDB.
  static const String kSentinel = 'tmdb';

  static const String _base = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p';
  static const String _language = 'en-US';

  /// Number of items the TMDB API returns per page.
  static const int pageSize = 20;

  /// `listId` → (endpoint path, default media type).
  static const Map<String, (String, String)> _staticLists = {
    'trending_day': ('/trending/movie/day', 'movie'),
    'trending_tv_day': ('/trending/tv/day', 'series'),
    'trending_week': ('/trending/movie/week', 'movie'),
    'popular_movie': ('/movie/popular', 'movie'),
    'popular_series': ('/tv/popular', 'series'),
    'top_rated_movie': ('/movie/top_rated', 'movie'),
    'top_rated_series': ('/tv/top_rated', 'series'),
    'now_playing': ('/movie/now_playing', 'movie'),
    'upcoming': ('/movie/upcoming', 'movie'),
  };

  static const Map<String, String> _listTitles = {
    'trending_day': 'Trending Today',
    'trending_tv_day': 'Trending Today',
    'trending_week': 'Trending This Week',
    'popular_movie': 'Popular Movies',
    'popular_series': 'Popular Series',
    'top_rated_movie': 'Top Rated Movies',
    'top_rated_series': 'Top Rated Series',
    'now_playing': 'Now Playing',
    'upcoming': 'Upcoming',
  };

  static final Map<String, List<Movie>> _listCache = {};

  // Cached filter-option lists (rarely change; avoid refetching per sheet open).
  static final Map<String, List<({int id, String name})>> _idNameCache = {};
  static final Map<String, List<({String code, String name})>> _codeNameCache = {};
  static final Map<String, List<String>> _stringListCache = {};

  /// Curated home-page lists in display order (list id → content type).
  static const List<({String listId, String type})> homeLists = [
    (listId: 'trending_day', type: 'movie'),
    (listId: 'trending_week', type: 'movie'),
    (listId: 'popular_movie', type: 'movie'),
    (listId: 'popular_series', type: 'series'),
    (listId: 'top_rated_movie', type: 'movie'),
    (listId: 'now_playing', type: 'movie'),
    (listId: 'upcoming', type: 'movie'),
  ];

  /// Whether a TMDB API key is available (from `.env` / dart-define / env).
  static bool get isConfigured => EnvService.tmdbApiKey.trim().isNotEmpty;

  /// Clears the in-memory caches (lists + filter options).
  static void clearCache() {
    _listCache.clear();
    _idNameCache.clear();
    _codeNameCache.clear();
    _stringListCache.clear();
  }

  /// Builds a TMDB image URL. Returns `''` when [path] is empty.
  static String imageUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_imageBase/$size$path';
  }

  /// Human-readable title for a `listId`, used for section headers.
  static String catalogTitle(String listId) {
    final known = _listTitles[listId];
    if (known != null) return known;
    if (listId.startsWith('genre_movie_')) return 'Movies';
    if (listId.startsWith('genre_series_')) return 'Series';
    return 'Browse';
  }

  /// Performs a TMDB GET and returns the decoded body, or `null` on any
  /// failure. Includes `api_key` + `language=en-US` on every request.
  static Future<dynamic> _getRaw(
    String path, {
    Map<String, String>? query,
  }) async {
    final key = EnvService.tmdbApiKey.trim();
    if (key.isEmpty) return null;

    try {
      final params = <String, String>{
        'api_key': key,
        'language': _language,
        ...?query,
      };
      final uri = Uri.parse('$_base$path').replace(queryParameters: params);
      final res = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  /// Performs a TMDB GET and returns the decoded object, or `null` on any
  /// failure (including when the endpoint returns a JSON array).
  static Future<Map<String, dynamic>?> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final decoded = await _getRaw(path, query: query);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  /// Fetches a catalog list by [listId] (see [_staticLists] and `genre_*`).
  static Future<List<Movie>> fetchList(String listId, {int page = 1}) async {
    final cacheKey = '$listId|$page';
    final cached = _listCache[cacheKey];
    if (cached != null) return List<Movie>.from(cached);

    final String? path;
    final String mediaType;
    final query = <String, String>{'page': '$page'};

    if (listId.startsWith('genre_movie_')) {
      path = '/discover/movie';
      query['with_genres'] = listId.substring('genre_movie_'.length);
      query['sort_by'] = 'popularity.desc';
      mediaType = 'movie';
    } else if (listId.startsWith('genre_series_')) {
      path = '/discover/tv';
      query['with_genres'] = listId.substring('genre_series_'.length);
      query['sort_by'] = 'popularity.desc';
      mediaType = 'series';
    } else {
      final entry = _staticLists[listId];
      if (entry == null) return const [];
      path = entry.$1;
      mediaType = entry.$2;
    }

    final data = await _get(path, query: query);
    if (data == null) return const [];

    final results = data['results'];
    if (results is! List) return const [];

    final movies = <Movie>[];
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final itemType = item['media_type']?.toString();
      final type = (itemType == 'movie' || itemType == 'tv') ? itemType! : mediaType;
      final movie = Movie.fromTmdb(item, type);
      if (_isUsable(movie)) movies.add(movie);
    }

    _listCache[cacheKey] = movies;
    return List<Movie>.from(movies);
  }

  // ── Search ────────────────────────────────────────────────────────────

  /// TMDB multi-search across movies and TV, tagged with [kSentinel].
  static Future<List<Movie>> searchMulti(String query, {int page = 1}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final data = await _get('/search/multi', query: {'query': q, 'page': '$page'});
    if (data == null) return const [];

    final results = data['results'];
    if (results is! List) return const [];

    final movies = <Movie>[];
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final mediaType = item['media_type']?.toString();
      if (mediaType != 'movie' && mediaType != 'tv') continue;
      final movie = Movie.fromTmdb(item, mediaType!);
      if (_isUsable(movie)) movies.add(movie);
    }
    return movies;
  }

  // ── Details ───────────────────────────────────────────────────────────

  /// Fetches full details (credits, external ids, videos, recommendations) for
  /// a movie/series by TMDB numeric id. Returns `null` on failure.
  static Future<MovieDetail?> fetchDetails(String type, String tmdbId) async {
    final isTv = type == 'tv' || type == 'series';
    final data = await _get(
      isTv ? '/tv/$tmdbId' : '/movie/$tmdbId',
      query: {'append_to_response': 'external_ids,credits,videos,recommendations'},
    );
    if (data == null) return null;
    return MovieDetail.fromTmdb(data, isTv ? 'tv' : 'movie');
  }

  // ── Find by IMDb ──────────────────────────────────────────────────────

  /// Resolves an IMDb id (`tt…`) to a TMDB id + type. `null` when unresolved.
  static Future<({String type, String tmdbId})?> resolveByImdb(
    String imdbId,
  ) async {
    final id = imdbId.trim();
    if (id.isEmpty) return null;

    final data = await _get('/find/$id', query: {'external_source': 'imdb_id'});
    if (data == null) return null;
    return findResultFromJson(data);
  }

  /// Parses a `/find/{imdb}?external_source=imdb_id` response.
  @visibleForTesting
  static ({String type, String tmdbId})? findResultFromJson(
    Map<String, dynamic> data,
  ) {
    final movieResults = data['movie_results'];
    if (movieResults is List && movieResults.isNotEmpty) {
      final first = movieResults.first;
      if (first is Map && first['id'] != null) {
        return (type: 'movie', tmdbId: first['id'].toString());
      }
    }
    final tvResults = data['tv_results'];
    if (tvResults is List && tvResults.isNotEmpty) {
      final first = tvResults.first;
      if (first is Map && first['id'] != null) {
        return (type: 'series', tmdbId: first['id'].toString());
      }
    }
    return null;
  }

  // ── Recommendations ───────────────────────────────────────────────────

  /// Recommendation items for a movie/series, tagged with [kSentinel].
  static Future<List<Movie>> fetchRecommendations(
    String type,
    String tmdbId,
  ) async {
    final isTv = type == 'tv' || type == 'series';
    final data = await _get(
      isTv ? '/tv/$tmdbId/recommendations' : '/movie/$tmdbId/recommendations',
    );
    if (data == null) return const [];

    final results = data['results'];
    if (results is! List) return const [];

    final movies = <Movie>[];
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final movie = Movie.fromTmdb(item, isTv ? 'tv' : 'movie');
      if (_isUsable(movie)) movies.add(movie);
    }
    return movies;
  }

  // ── Season episodes ───────────────────────────────────────────────────

  /// Episodes of a series season as [Video]s. Empty on failure.
  ///
  /// [showImdbId] is the show's IMDb id (a `tt…` id). When it is known, episode
  /// ids are stamped as `<imdb>:<season>:<episode>` — the only id shape that
  /// Stremio stream addons and the built-in scrapers understand. Without it the
  /// TMDB episode id is kept as a last resort.
  static Future<List<Video>> fetchSeasonEpisodes(
    String tmdbId,
    int season, {
    String? showImdbId,
  }) async {
    final data = await _get('/tv/$tmdbId/season/$season');
    if (data == null) return const [];
    return seasonEpisodesFromJson(data, season, showImdbId: showImdbId);
  }

  /// Parses a `/tv/{id}/season/{n}` response into episode [Video]s.
  @visibleForTesting
  static List<Video> seasonEpisodesFromJson(
    Map<String, dynamic> data,
    int season, {
    String? showImdbId,
  }) {
    final episodes = data['episodes'];
    if (episodes is! List) return const [];

    final imdb = (showImdbId ?? '').trim();
    final hasImdb = imdb.startsWith('tt');
    final videos = <Video>[];
    for (final ep in episodes) {
      if (ep is! Map<String, dynamic>) continue;

      final rawNumber = ep['episode_number'];
      final episodeNumber =
          rawNumber is int ? rawNumber : int.tryParse('$rawNumber');
      if (episodeNumber == null) continue;

      final still = imageUrl(ep['still_path']?.toString());
      videos.add(Video(
        id: hasImdb
            ? '$imdb:$season:$episodeNumber'
            : (ep['id']?.toString() ?? '${season}x$episodeNumber'),
        title: (ep['name'] ?? 'Episode $episodeNumber').toString(),
        season: season,
        episode: episodeNumber,
        released: ep['air_date']?.toString(),
        thumbnail: still.isEmpty ? null : still,
        overview: ep['overview']?.toString(),
      ));
    }
    return videos;
  }

  static bool _isUsable(Movie movie) =>
      movie.id != '$kSentinel:' && movie.name.isNotEmpty && movie.name != 'Unknown';

  // ── Genres ────────────────────────────────────────────────────────────

  /// Genre list for a media type (`movie`/`series`). Empty on failure.
  static Future<List<({int id, String name})>> fetchGenres(String type) async {
    final cacheKey = 'genres|$type';
    final cached = _idNameCache[cacheKey];
    if (cached != null) return cached;

    final isTv = type == 'tv' || type == 'series';
    final data = await _get(isTv ? '/genre/tv/list' : '/genre/movie/list');
    if (data == null) return const [];
    final result = genresFromJson(data);
    _idNameCache[cacheKey] = result;
    return result;
  }

  /// Parses a `/genre/{type}/list` response into `(id, name)` records.
  @visibleForTesting
  static List<({int id, String name})> genresFromJson(
    Map<String, dynamic> data,
  ) {
    final genres = data['genres'];
    if (genres is! List) return const [];

    final result = <({int id, String name})>[];
    for (final g in genres) {
      if (g is! Map) continue;
      final rawId = g['id'];
      final id = rawId is int ? rawId : int.tryParse('$rawId');
      final name = g['name']?.toString();
      if (id == null || name == null || name.isEmpty) continue;
      result.add((id: id, name: name));
    }
    return result;
  }

  // ── Discover (filtered browsing) ──────────────────────────────────────

  /// Pseudo sort value meaning "use the TMDB trending feed" rather than a
  /// `/discover` `sort_by`. Handled by callers, never sent to the API.
  static const String kTrendingSort = 'trending';

  /// Sort options for the given media type. [kTrendingSort] is a pseudo value
  /// resolved by callers to the trending list endpoint.
  static List<({String value, String label})> sortOptionsFor(String type) {
    final isTv = type == 'tv' || type == 'series';
    return [
      (value: 'popularity.desc', label: 'Popular'),
      (value: kTrendingSort, label: 'Trending'),
      (value: 'vote_average.desc', label: 'Top Rated'),
      (
        value: isTv ? 'first_air_date.desc' : 'primary_release_date.desc',
        label: 'Newest',
      ),
      (value: isTv ? 'name.asc' : 'original_title.asc', label: 'Alphabetical'),
    ];
  }

  /// Minimum-rating filter buckets; `minScore == null` means "Any".
  static const List<({double? minScore, String label})> scoreOptions = [
    (minScore: null, label: 'Any'),
    (minScore: 5, label: '5.0+'),
    (minScore: 6, label: '6.0+'),
    (minScore: 7, label: '7.0+'),
    (minScore: 8, label: '8.0+'),
    (minScore: 9, label: '9.0+'),
  ];

  /// Runtime filter buckets.
  static const List<({int? min, int? max, String label})> runtimeOptions = [
    (min: null, max: null, label: 'Any'),
    (min: null, max: 90, label: 'Under 90m'),
    (min: 90, max: 120, label: '90-120m'),
    (min: 120, max: null, label: 'Over 120m'),
  ];

  /// Release years from the current year back to 1950.
  static List<int> get yearOptions {
    final now = DateTime.now().year;
    return [for (var y = now; y >= 1950; y--) y];
  }

  /// Filtered discovery of movies/series via `/discover`.
  ///
  /// Multi-value filters use TMDB's `|` (OR) semantics.
  static Future<List<Movie>> discover({
    required String type,
    List<int>? genreIds,
    int? yearFrom,
    int? yearTo,
    String? sortBy,
    List<int>? providerIds,
    String? country,
    String? language,
    String? certification,
    double? minScore,
    int? minRuntime,
    int? maxRuntime,
    int page = 1,
    String region = 'US',
  }) async {
    final data = await _get(
      _discoverPath(type),
      query: buildDiscoverQuery(
        type: type,
        genreIds: genreIds,
        yearFrom: yearFrom,
        yearTo: yearTo,
        sortBy: sortBy,
        providerIds: providerIds,
        country: country,
        language: language,
        certification: certification,
        minScore: minScore,
        minRuntime: minRuntime,
        maxRuntime: maxRuntime,
        page: page,
        region: region,
      ),
    );
    if (data == null) return const [];

    final results = data['results'];
    if (results is! List) return const [];

    final isTv = _isTv(type);
    final movies = <Movie>[];
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final movie = Movie.fromTmdb(item, isTv ? 'tv' : 'movie');
      if (_isUsable(movie)) movies.add(movie);
    }
    return movies;
  }

  /// Total number of titles matching a [discover] query (`total_results`).
  /// Returns `null` when the request fails or is unconfigured — callers must
  /// not fabricate a count.
  static Future<int?> discoverTotal({
    required String type,
    List<int>? genreIds,
    int? yearFrom,
    int? yearTo,
    String? sortBy,
    List<int>? providerIds,
    String? country,
    String? language,
    String? certification,
    double? minScore,
    int? minRuntime,
    int? maxRuntime,
    String region = 'US',
  }) async {
    final data = await _get(
      _discoverPath(type),
      query: buildDiscoverQuery(
        type: type,
        genreIds: genreIds,
        yearFrom: yearFrom,
        yearTo: yearTo,
        sortBy: sortBy,
        providerIds: providerIds,
        country: country,
        language: language,
        certification: certification,
        minScore: minScore,
        minRuntime: minRuntime,
        maxRuntime: maxRuntime,
        region: region,
      ),
    );
    if (data == null) return null;
    final total = data['total_results'];
    if (total is int) return total;
    return int.tryParse('$total');
  }

  static bool _isTv(String type) => type == 'tv' || type == 'series';

  static String _discoverPath(String type) =>
      _isTv(type) ? '/discover/tv' : '/discover/movie';

  /// Builds the query map for a `/discover` request. Kept public/testable so
  /// the filter → API mapping stays in one place.
  @visibleForTesting
  static Map<String, String> buildDiscoverQuery({
    required String type,
    List<int>? genreIds,
    int? yearFrom,
    int? yearTo,
    String? sortBy,
    List<int>? providerIds,
    String? country,
    String? language,
    String? certification,
    double? minScore,
    int? minRuntime,
    int? maxRuntime,
    int page = 1,
    String region = 'US',
  }) {
    final isTv = _isTv(type);
    final query = <String, String>{
      'page': '$page',
      'sort_by': (sortBy == null || sortBy == kTrendingSort)
          ? 'popularity.desc'
          : sortBy,
    };

    if (genreIds != null && genreIds.isNotEmpty) {
      // Comma = AND: results must match *all* selected genres.
      query['with_genres'] = genreIds.join(',');
    }
    if (yearFrom != null) {
      query[isTv ? 'first_air_date.gte' : 'primary_release_date.gte'] =
          '$yearFrom-01-01';
    }
    if (yearTo != null) {
      query[isTv ? 'first_air_date.lte' : 'primary_release_date.lte'] =
          '$yearTo-12-31';
    }
    if (providerIds != null && providerIds.isNotEmpty) {
      query['with_watch_providers'] = providerIds.join('|');
      query['watch_region'] = region;
    }
    if (country != null && country.isNotEmpty) {
      query['with_origin_country'] = country;
    }
    if (language != null && language.isNotEmpty) {
      query['with_original_language'] = language;
    }
    if (certification != null && certification.isNotEmpty) {
      query['certification'] = certification;
      query['certification_country'] = region;
    }
    if (minScore != null && minScore > 0) {
      query['vote_average.gte'] = minScore.toString();
      query['vote_count.gte'] = '50';
    }
    if (minRuntime != null) query['with_runtime.gte'] = '$minRuntime';
    if (maxRuntime != null) query['with_runtime.lte'] = '$maxRuntime';

    return query;
  }

  /// TMDB provider IDs for the curated set of top streaming services, in
  /// display order.
  static const List<int> curatedWatchProviderIds = [
    8, // Netflix
    9, // Amazon Prime Video
    1899, // Max
    337, // Disney+
    188, // YouTube Premium
    531, // Paramount+
    15, // Hulu
    386, // Peacock
    350, // Apple TV+
    283, // Crunchyroll
  ];

  /// Watch providers (streaming services) available in [region].
  static Future<List<({int id, String name})>> fetchWatchProviders(
    String type, {
    String region = 'US',
  }) async {
    final cacheKey = 'providers|$type|$region';
    final cached = _idNameCache[cacheKey];
    if (cached != null) return cached;

    final isTv = type == 'tv' || type == 'series';
    final data = await _get(
      isTv ? '/watch/providers/tv' : '/watch/providers/movie',
      query: {'watch_region': region},
    );
    if (data == null) return const [];
    final result = _idNameList(data['results'], 'provider_id', 'provider_name');
    _idNameCache[cacheKey] = result;
    return result;
  }

  /// ISO-3166-1 countries from `/configuration/countries`.
  static Future<List<({String code, String name})>> fetchCountries() async {
    const cacheKey = 'countries';
    final cached = _codeNameCache[cacheKey];
    if (cached != null) return cached;

    final decoded = await _getRaw('/configuration/countries');
    if (decoded is! List) return const [];
    final result = <({String code, String name})>[];
    for (final c in decoded) {
      if (c is! Map) continue;
      final code = c['iso_3166_1']?.toString();
      final name = c['english_name']?.toString();
      if (code == null || code.isEmpty || name == null || name.isEmpty) continue;
      result.add((code: code, name: name));
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    _codeNameCache[cacheKey] = result;
    return result;
  }

  /// ISO-639-1 languages from `/configuration/languages`.
  static Future<List<({String code, String name})>> fetchLanguages() async {
    const cacheKey = 'languages';
    final cached = _codeNameCache[cacheKey];
    if (cached != null) return cached;

    final decoded = await _getRaw('/configuration/languages');
    if (decoded is! List) return const [];
    final result = <({String code, String name})>[];
    for (final l in decoded) {
      if (l is! Map) continue;
      final code = l['iso_639_1']?.toString();
      final name = (l['english_name'] ?? l['name'])?.toString();
      if (code == null || code.isEmpty || name == null || name.isEmpty) continue;
      result.add((code: code, name: name));
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    _codeNameCache[cacheKey] = result;
    return result;
  }

  /// Age certifications for [region] (e.g. US → G, PG, PG-13, R).
  static Future<List<String>> fetchCertifications(
    String type, {
    String region = 'US',
  }) async {
    final cacheKey = 'certs|$type|$region';
    final cached = _stringListCache[cacheKey];
    if (cached != null) return cached;

    final isTv = type == 'tv' || type == 'series';
    final data = await _get(
      isTv ? '/certification/tv/list' : '/certification/movie/list',
    );
    if (data == null) return const [];
    final result = certificationsFromJson(data, region);
    _stringListCache[cacheKey] = result;
    return result;
  }

  /// Parses a `/certification/{type}/list` response for [region].
  @visibleForTesting
  static List<String> certificationsFromJson(
    Map<String, dynamic> data,
    String region,
  ) {
    final certifications = data['certifications'];
    if (certifications is! Map) return const [];
    final forRegion =
        certifications[region] ?? certifications[region.toUpperCase()];
    if (forRegion is! List) return const [];

    final result = <String>[];
    for (final c in forRegion) {
      if (c is! Map) continue;
      final value = c['certification']?.toString();
      if (value != null && value.isNotEmpty) result.add(value);
    }
    return result;
  }

  // ── People ────────────────────────────────────────────────────────────

  /// Looks up a person by display name and returns their filmography.
  ///
  /// TMDB has no "person by name" endpoint, so this searches first and then
  /// fetches the full profile. Returns `null` when nothing matches or the
  /// request fails.
  static Future<TmdbPerson?> fetchPersonByName(String name) async {
    final q = name.trim();
    if (q.isEmpty) return null;

    final search = await _get('/search/person', query: {'query': q});
    if (search == null) return null;

    final id = personIdFromSearchJson(search, name: q);
    if (id == null) return null;
    return fetchPerson(id);
  }

  /// Fetches a person and their combined movie + TV credits by TMDB id.
  static Future<TmdbPerson?> fetchPerson(int id) async {
    final data = await _get(
      '/person/$id',
      query: {'append_to_response': 'combined_credits'},
    );
    if (data == null) return null;
    return personFromJson(data);
  }

  /// Picks the person id out of a `/search/person` response, preferring an
  /// exact (case-insensitive) [name] match over the most popular result.
  @visibleForTesting
  static int? personIdFromSearchJson(
    Map<String, dynamic> data, {
    String? name,
  }) {
    final results = data['results'];
    if (results is! List) return null;

    final target = name?.trim().toLowerCase();
    int? firstId;
    for (final item in results) {
      if (item is! Map) continue;
      final rawId = item['id'];
      final id = rawId is int ? rawId : int.tryParse('$rawId');
      if (id == null) continue;
      firstId ??= id;
      if (target != null &&
          item['name']?.toString().trim().toLowerCase() == target) {
        return id;
      }
    }
    return firstId;
  }

  /// Parses `/person/{id}?append_to_response=combined_credits`.
  @visibleForTesting
  static TmdbPerson? personFromJson(Map<String, dynamic> data) {
    final rawId = data['id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId');
    final name = data['name']?.toString().trim() ?? '';
    if (id == null || name.isEmpty) return null;

    final profileUrl = imageUrl(data['profile_path']?.toString(), size: 'w185');

    return TmdbPerson(
      id: id,
      name: name,
      profileUrl: profileUrl.isEmpty ? null : profileUrl,
      department: data['known_for_department']?.toString() ?? '',
      biography: data['biography']?.toString().trim() ?? '',
      credits: _creditsFromJson(data['combined_credits']),
    );
  }

  static List<Movie> _creditsFromJson(dynamic combined) {
    if (combined is! Map) return const [];
    final cast = combined['cast'];
    if (cast is! List) return const [];

    // Keyed by media type + numeric id: a movie and a series can share the
    // same numeric id, and Movie.id alone would collapse them.
    final byKey = <String, Movie>{};
    for (final item in cast) {
      if (item is! Map<String, dynamic>) continue;
      final mediaType = item['media_type']?.toString();
      if (mediaType != 'movie' && mediaType != 'tv') continue;

      final movie = Movie.fromTmdb(item, mediaType!);
      if (!_isUsable(movie)) continue;

      final key = '${movie.type}|${movie.id}';
      final existing = byKey[key];
      if (existing == null ||
          (movie.popularity ?? 0) > (existing.popularity ?? 0)) {
        byKey[key] = movie;
      }
    }

    final credits = byKey.values.toList()
      ..sort((a, b) {
        final yearA = int.tryParse(a.year ?? '') ?? -1;
        final yearB = int.tryParse(b.year ?? '') ?? -1;
        if (yearA != yearB) return yearB.compareTo(yearA);
        return (b.popularity ?? 0).compareTo(a.popularity ?? 0);
      });
    return credits;
  }

  static List<({int id, String name})> _idNameList(
    dynamic list,
    String idKey,
    String nameKey,
  ) {
    if (list is! List) return const [];
    final result = <({int id, String name})>[];
    for (final item in list) {
      if (item is! Map) continue;
      final rawId = item[idKey];
      final id = rawId is int ? rawId : int.tryParse('$rawId');
      final name = item[nameKey]?.toString();
      if (id == null || name == null || name.isEmpty) continue;
      result.add((id: id, name: name));
    }
    return result;
  }
}
