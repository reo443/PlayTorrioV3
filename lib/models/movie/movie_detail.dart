import '../../services/metadata/tmdb_service.dart';
import 'cast_member.dart';
import 'link.dart';
import 'video.dart';

class MovieDetail {
  final String id;
  final String type;
  final String name;
  final String? poster;
  final String? background;
  final String? logo;
  final String? description;
  final String? year;
  final String? imdbRating;
  final List<String> genres;
  final List<String> cast;

  /// Cast credits with optional profile images (populated for TMDB details).
  final List<CastMember> castMembers;
  final List<String> director;
  final String? runtime;
  final List<Link> links;
  final List<Video> videos;
  final String? tmdbId;

  /// Season numbers available for a series (populated for TMDB series).
  final List<int> seasons;

  MovieDetail({
    required this.id,
    required this.type,
    required this.name,
    this.poster,
    this.background,
    this.logo,
    this.description,
    this.year,
    this.imdbRating,
    this.genres = const [],
    this.cast = const [],
    this.castMembers = const [],
    this.director = const [],
    this.runtime,
    this.links = const [],
    this.videos = const [],
    this.tmdbId,
    this.seasons = const [],
  });

  /// Whether this detail represents a collection or franchise item.
  bool get isCollection =>
      type == 'collections' ||
      type == 'collection' ||
      id.startsWith('ctmdb.') ||
      name.toLowerCase().endsWith('collection');

  MovieDetail copyWith({
    String? id,
    String? type,
    String? name,
    String? poster,
    String? background,
    String? logo,
    String? description,
    String? year,
    String? imdbRating,
    List<String>? genres,
    List<String>? cast,
    List<CastMember>? castMembers,
    List<String>? director,
    String? runtime,
    List<Link>? links,
    List<Video>? videos,
    String? tmdbId,
    List<int>? seasons,
  }) {
    return MovieDetail(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      poster: poster ?? this.poster,
      background: background ?? this.background,
      logo: logo ?? this.logo,
      description: description ?? this.description,
      year: year ?? this.year,
      imdbRating: imdbRating ?? this.imdbRating,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
      castMembers: castMembers ?? this.castMembers,
      director: director ?? this.director,
      runtime: runtime ?? this.runtime,
      links: links ?? this.links,
      videos: videos ?? this.videos,
      tmdbId: tmdbId ?? this.tmdbId,
      seasons: seasons ?? this.seasons,
    );
  }

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    return MovieDetail(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'movie',
      name: json['name']?.toString() ?? 'Unknown',
      poster: json['poster']?.toString(),
      background: json['background']?.toString(),
      logo: json['logo']?.toString(),
      description: json['description']?.toString(),
      year: json['releaseInfo']?.toString() ?? json['year']?.toString(),
      imdbRating: json['imdbRating']?.toString(),
      genres: _parseStringList(json['genres']),
      cast: _parseStringList(json['cast']),
      director: _parseStringList(json['director']),
      runtime: json['runtime']?.toString(),
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => Link.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tmdbId: json['moviedb_id']?.toString(),
    );
  }

  /// Builds a [MovieDetail] from a TMDB details response.
  ///
  /// [type] is TMDB's `movie`/`tv` (or the app's `series`). The [id] becomes the
  /// IMDb id (`external_ids.imdb_id`) when present — because stream scrapers
  /// resolve by IMDb — otherwise `tmdb:<numeric id>`.
  factory MovieDetail.fromTmdb(Map<String, dynamic> json, String type) {
    final isTv = type == 'tv' || type == 'series';
    final numericId = json['id']?.toString() ?? '';

    final externalIds = json['external_ids'];
    final imdbId = (externalIds is Map)
        ? externalIds['imdb_id']?.toString()
        : json['imdb_id']?.toString();
    final effectiveId = (imdbId != null && imdbId.isNotEmpty)
        ? imdbId
        : (numericId.isNotEmpty ? '${TmdbService.kSentinel}:$numericId' : '');

    final dateStr =
        (json['release_date'] ?? json['first_air_date'] ?? '').toString();

    final castList = <String>[];
    final castMemberList = <CastMember>[];
    final directorList = <String>[];
    final credits = json['credits'];
    if (credits is Map) {
      final cast = credits['cast'];
      if (cast is List) {
        for (final c in cast.take(15)) {
          if (c is Map) {
            final n = c['name']?.toString();
            if (n != null && n.isNotEmpty) {
              castList.add(n);
              castMemberList.add(CastMember(
                name: n,
                character: c['character']?.toString(),
                profilePath: c['profile_path']?.toString(),
              ));
            }
          }
        }
      }
      final crew = credits['crew'];
      if (crew is List) {
        for (final c in crew) {
          if (c is Map && c['job']?.toString() == 'Director') {
            final n = c['name']?.toString();
            if (n != null && n.isNotEmpty) directorList.add(n);
          }
        }
      }
    }
    if (directorList.isEmpty) {
      final createdBy = json['created_by'];
      if (createdBy is List) {
        for (final c in createdBy) {
          if (c is Map) {
            final n = c['name']?.toString();
            if (n != null && n.isNotEmpty) directorList.add(n);
          }
        }
      }
    }

    final genreNames = <String>[];
    final genreList = json['genres'];
    if (genreList is List) {
      for (final g in genreList) {
        if (g is Map) {
          final n = g['name']?.toString();
          if (n != null && n.isNotEmpty) genreNames.add(n);
        }
      }
    }

    final rating = json['vote_average'];
    final runtime = isTv ? null : json['runtime'];

    final seasonNumbers = <int>[];
    final seasonList = json['seasons'];
    if (seasonList is List) {
      for (final s in seasonList) {
        if (s is! Map) continue;
        final raw = s['season_number'];
        final n = raw is int ? raw : int.tryParse('$raw');
        if (n != null) seasonNumbers.add(n);
      }
      seasonNumbers.sort();
    }

    return MovieDetail(
      id: effectiveId,
      type: isTv ? 'series' : 'movie',
      name: (json['title'] ?? json['name'] ?? 'Unknown').toString(),
      poster: TmdbService.imageUrl(json['poster_path']?.toString()),
      background:
          TmdbService.imageUrl(json['backdrop_path']?.toString(), size: 'original'),
      description: json['overview']?.toString(),
      year: dateStr.length >= 4 ? dateStr.substring(0, 4) : null,
      imdbRating: (rating is num && rating > 0) ? rating.toString() : null,
      genres: genreNames,
      cast: castList,
      castMembers: castMemberList,
      director: directorList,
      runtime: (runtime is num && runtime > 0) ? runtime.toString() : null,
      tmdbId: numericId.isEmpty ? null : numericId,
      seasons: seasonNumbers,
    );
  }
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is String) return [value];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}
