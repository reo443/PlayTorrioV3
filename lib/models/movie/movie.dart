import '../../services/metadata/tmdb_service.dart';

class Movie {
  final String id;
  final String name;
  final String? poster;
  final String? year;
  final String type;
  final String addonBaseUrl;
  final String? imdbRating;
  final double? popularity;
  final int? runtime;
  final List<String> genres;

  Movie({
    required this.id,
    required this.name,
    this.poster,
    this.year,
    required this.type,
    required this.addonBaseUrl,
    this.imdbRating,
    this.popularity,
    this.runtime,
    this.genres = const [],
  });

  /// Whether this movie represents a collection or franchise item.
  bool get isCollection =>
      type == 'collections' ||
      type == 'collection' ||
      id.startsWith('ctmdb.') ||
      name.toLowerCase().endsWith('collection');

  factory Movie.fromJson(Map<String, dynamic> json, String addonBaseUrl) {
    String? ratingStr;
    if (json['imdbRating'] != null) {
      ratingStr = json['imdbRating'].toString();
    } else if (json['rating'] != null) {
      ratingStr = json['rating'].toString();
    } else if (json['imdb_rating'] != null) {
      ratingStr = json['imdb_rating'].toString();
    } else if (json['vote_average'] != null) {
      ratingStr = json['vote_average'].toString();
    }

    double? popularity;
    if (json['popularity'] is num) {
      popularity = (json['popularity'] as num).toDouble();
    } else {
      popularity = double.tryParse(json['popularity']?.toString() ?? '');
    }

    return Movie(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      poster: json['poster']?.toString(),
      year: json['releaseInfo']?.toString() ?? json['year']?.toString(),
      type: json['type']?.toString() ?? 'movie',
      addonBaseUrl: addonBaseUrl,
      imdbRating: ratingStr,
      popularity: popularity,
      runtime: _parseRuntime(
        json['runtime'] ?? json['duration'] ?? json['runtimeMinutes'],
      ),
      genres: _parseGenres(json['genres'] ?? json['genre']),
    );
  }

  /// Builds a [Movie] from a TMDB API item (trending/popular/discover/search).
  ///
  /// [mediaType] is typically TMDB's `media_type` (`movie`/`tv`); `series` is
  /// accepted as an alias for `tv`. Items are tagged with [TmdbService.kSentinel].
  factory Movie.fromTmdb(Map<String, dynamic> json, String mediaType) {
    final rawType = mediaType.isNotEmpty
        ? mediaType
        : (json['media_type']?.toString() ?? 'movie');
    final isTv = rawType == 'tv' || rawType == 'series';

    final numericId = json['id']?.toString() ?? '';
    final dateStr =
        (json['release_date'] ?? json['first_air_date'] ?? '').toString();

    double? popularity;
    if (json['popularity'] is num) {
      popularity = (json['popularity'] as num).toDouble();
    } else {
      popularity = double.tryParse(json['popularity']?.toString() ?? '');
    }

    final rating = json['vote_average'];
    final ratingStr = (rating is num && rating > 0) ? rating.toString() : null;

    return Movie(
      id: numericId.isEmpty ? '' : '${TmdbService.kSentinel}:$numericId',
      name: (json['title'] ??
              json['name'] ??
              json['original_title'] ??
              json['original_name'] ??
              'Unknown')
          .toString(),
      poster: TmdbService.imageUrl(json['poster_path']?.toString()),
      year: dateStr.length >= 4 ? dateStr.substring(0, 4) : null,
      type: isTv ? 'series' : 'movie',
      addonBaseUrl: TmdbService.kSentinel,
      imdbRating: ratingStr,
      popularity: popularity,
    );
  }

  /// Parses genre data that can arrive as a list or a comma-separated
  /// string depending on the addon.
  static List<String> _parseGenres(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Parses runtime values like "181", "181 min", "2h 21min", or PT2H21M
  /// into total minutes.
  static int? _parseRuntime(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();

    final s = value.toString().trim();
    if (s.isEmpty) return null;

    final hMatch = RegExp(r'(\d+)\s*h', caseSensitive: false).firstMatch(s);
    final mMatch = RegExp(r'(\d+)\s*m(?!s)', caseSensitive: false).firstMatch(s);
    if (hMatch != null || mMatch != null) {
      return (int.tryParse(hMatch?.group(1) ?? '') ?? 0) * 60 +
          (int.tryParse(mMatch?.group(1) ?? '') ?? 0);
    }

    final digits = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
    return (digits != null && digits > 0) ? digits : null;
  }
}
