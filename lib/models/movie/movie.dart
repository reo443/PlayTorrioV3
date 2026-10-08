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
    );
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
