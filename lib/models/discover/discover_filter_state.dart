import 'package:flutter/foundation.dart';

/// Immutable set of Browse (Discover) advanced filters.
///
/// This is the single source of truth handed to the filter sheet and returned
/// from it. Sorting is intentionally *not* part of this model — sort stays a
/// separate concern (see `DiscoverPage._sortBy`).
@immutable
class DiscoverFilterState {
  /// Selected TMDB genre ids (OR semantics).
  final List<int> genreIds;

  /// Minimum vote average, 0–10. `0` means "any".
  final double minScore;

  /// Inclusive runtime bounds in minutes; `null` means unbounded.
  final int? minRuntime;
  final int? maxRuntime;

  /// Inclusive release-year bounds; `null` means unbounded.
  final int? yearFrom;
  final int? yearTo;

  /// Selected streaming-provider ids (OR semantics).
  final List<int> providerIds;

  /// Single original-language code (TMDB supports one value only).
  final String? language;

  /// Single origin-country code.
  final String? country;

  /// Single age certification (e.g. `PG-13`).
  final String? certification;

  const DiscoverFilterState({
    this.genreIds = const [],
    this.minScore = 0,
    this.minRuntime,
    this.maxRuntime,
    this.yearFrom,
    this.yearTo,
    this.providerIds = const [],
    this.language,
    this.country,
    this.certification,
  });

  static const DiscoverFilterState empty = DiscoverFilterState();

  bool get isEmpty => activeCount == 0;

  /// Number of active filter *categories* (0–8).
  ///
  /// Counting rule: each category contributes once, regardless of how many
  /// values it holds (e.g. selecting three genres still counts as one).
  int get activeCount {
    var count = 0;
    if (genreIds.isNotEmpty) count++;
    if (minScore > 0) count++;
    if (minRuntime != null || maxRuntime != null) count++;
    if (yearFrom != null || yearTo != null) count++;
    if (providerIds.isNotEmpty) count++;
    if (language != null && language!.isNotEmpty) count++;
    if (country != null && country!.isNotEmpty) count++;
    if (certification != null && certification!.isNotEmpty) count++;
    return count;
  }

  DiscoverFilterState toggleGenre(int id) {
    final next = [...genreIds];
    next.contains(id) ? next.remove(id) : next.add(id);
    return copyWith(genreIds: next);
  }

  DiscoverFilterState toggleProvider(int id) {
    final next = [...providerIds];
    next.contains(id) ? next.remove(id) : next.add(id);
    return copyWith(providerIds: next);
  }

  DiscoverFilterState copyWith({
    List<int>? genreIds,
    double? minScore,
    int? minRuntime,
    int? maxRuntime,
    int? yearFrom,
    int? yearTo,
    List<int>? providerIds,
    String? language,
    String? country,
    String? certification,
    bool clearRuntime = false,
    bool clearYears = false,
    bool clearYearFrom = false,
    bool clearYearTo = false,
    bool clearLanguage = false,
    bool clearCountry = false,
    bool clearCertification = false,
  }) {
    return DiscoverFilterState(
      genreIds: genreIds ?? this.genreIds,
      minScore: minScore ?? this.minScore,
      minRuntime: clearRuntime ? null : (minRuntime ?? this.minRuntime),
      maxRuntime: clearRuntime ? null : (maxRuntime ?? this.maxRuntime),
      yearFrom: (clearYears || clearYearFrom)
          ? null
          : (yearFrom ?? this.yearFrom),
      yearTo: (clearYears || clearYearTo) ? null : (yearTo ?? this.yearTo),
      providerIds: providerIds ?? this.providerIds,
      language: clearLanguage ? null : (language ?? this.language),
      country: clearCountry ? null : (country ?? this.country),
      certification: clearCertification
          ? null
          : (certification ?? this.certification),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiscoverFilterState &&
        listEquals(other.genreIds, genreIds) &&
        other.minScore == minScore &&
        other.minRuntime == minRuntime &&
        other.maxRuntime == maxRuntime &&
        other.yearFrom == yearFrom &&
        other.yearTo == yearTo &&
        listEquals(other.providerIds, providerIds) &&
        other.language == language &&
        other.country == country &&
        other.certification == certification;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(genreIds),
    minScore,
    minRuntime,
    maxRuntime,
    yearFrom,
    yearTo,
    Object.hashAll(providerIds),
    language,
    country,
    certification,
  );
}
