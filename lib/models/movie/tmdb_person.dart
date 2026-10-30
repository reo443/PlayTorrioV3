import 'movie.dart';

/// A TMDB person plus their acting filmography.
///
/// [credits] are plain [Movie]s tagged with `TmdbService.kSentinel`, so they
/// open the normal details page when tapped.
class TmdbPerson {
  const TmdbPerson({
    required this.id,
    required this.name,
    this.profileUrl,
    this.department = '',
    this.biography = '',
    this.credits = const [],
  });

  final int id;
  final String name;
  final String? profileUrl;

  /// TMDB's `known_for_department` (e.g. "Acting", "Directing").
  final String department;

  final String biography;

  /// Movie + TV credits, newest first.
  final List<Movie> credits;
}
