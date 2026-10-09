/// Browse filters for the manga discovery grid, mapped to WeebCentral's
/// search/data query parameters.
class MangaBrowseFilter {
  /// Sort option: Popularity, Subscribers, Recently Added, Latest Updates, Alphabet.
  final String sort;

  /// Sort direction.
  final bool descending;

  /// Content types to include: Manga, Manhwa, Manhua, OEL.
  final List<String> types;

  /// Publication statuses to include: Ongoing, Complete, Hiatus, Canceled.
  final List<String> statuses;

  /// Genre tags to require.
  final List<String> includedTags;

  /// Genre tags to exclude.
  final List<String> excludedTags;

  /// Official translation filter: Any, True, False.
  final String official;

  /// Adult content filter: Any, True, False.
  final String adult;

  const MangaBrowseFilter({
    this.sort = 'Popularity',
    this.descending = true,
    this.types = const [],
    this.statuses = const [],
    this.includedTags = const [],
    this.excludedTags = const [],
    this.official = 'Any',
    this.adult = 'False',
  });

  static const sortOptions = <String>[
    'Popularity',
    'Subscribers',
    'Recently Added',
    'Latest Updates',
    'Alphabet',
  ];

  static const typeOptions = <String>['Manga', 'Manhwa', 'Manhua', 'OEL'];

  static const statusOptions = <String>[
    'Ongoing',
    'Complete',
    'Hiatus',
    'Canceled',
  ];

  bool get isDefault =>
      sort == 'Popularity' &&
      descending &&
      types.isEmpty &&
      statuses.isEmpty &&
      includedTags.isEmpty &&
      excludedTags.isEmpty &&
      official == 'Any' &&
      adult == 'False';

  int get activeCount {
    var count = 0;
    if (sort != 'Popularity' || !descending) count++;
    if (types.isNotEmpty) count++;
    if (statuses.isNotEmpty) count++;
    if (includedTags.isNotEmpty) count++;
    if (excludedTags.isNotEmpty) count++;
    if (official != 'Any') count++;
    if (adult != 'False') count++;
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (other is! MangaBrowseFilter) return false;
    bool listEq(List<String> a, List<String> b) =>
        a.length == b.length && a.every(b.contains);
    return sort == other.sort &&
        descending == other.descending &&
        listEq(types, other.types) &&
        listEq(statuses, other.statuses) &&
        listEq(includedTags, other.includedTags) &&
        listEq(excludedTags, other.excludedTags) &&
        official == other.official &&
        adult == other.adult;
  }

  @override
  int get hashCode =>
      Object.hash(sort, descending, official, adult, Object.hashAll(types),
          Object.hashAll(statuses), Object.hashAll(includedTags), Object.hashAll(excludedTags));
}
