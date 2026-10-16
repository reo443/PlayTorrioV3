import '../../services/metadata/tmdb_service.dart';

/// A single cast credit, carrying the optional TMDB profile image path.
class CastMember {
  final String name;
  final String? character;
  final String? profilePath;

  const CastMember({
    required this.name,
    this.character,
    this.profilePath,
  });

  /// Full URL to the TMDB profile image, or null when no image is available.
  String? get imageUrl {
    final url = TmdbService.imageUrl(profilePath, size: 'w185');
    return url.isEmpty ? null : url;
  }
}
