// Visibility rules for the details page's episode section.
//
// Episodes can come from three places: the addon's `videos` list, the TMDB
// season list, and the season currently selected. The section has to render
// when any of them has content, and the season tabs only make sense when there
// is more than one season to choose from.

import '../../models/movie/video.dart';

/// Whether the page has anything to show in the episode section.
bool shouldShowEpisodes({
  required List<Video> videos,
  required List<int> tmdbSeasons,
  required List<Video> currentSeasonEpisodes,
}) =>
    videos.isNotEmpty ||
    tmdbSeasons.isNotEmpty ||
    currentSeasonEpisodes.isNotEmpty;

/// Whether the season tab strip should be shown instead of a plain heading.
///
/// TMDB reports its seasons directly, so it is authoritative when it supplied
/// the episodes; otherwise the seasons are whatever the addon's videos carry.
bool shouldShowSeasonTabs({
  required List<Video> videos,
  required bool isTmdb,
  required List<int> tmdbSeasons,
}) {
  if (isTmdb) return tmdbSeasons.length > 1;

  final seasons = videos.map((v) => v.season).whereType<int>().toSet();
  return seasons.length > 1;
}
