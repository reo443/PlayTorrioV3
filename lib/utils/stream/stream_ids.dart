/// Stream ids are the contract between the app and its sources.
///
/// Stremio stream addons and the built-in scrapers address an episode as
/// `<imdb-id>:<season>:<episode>`. Other producers use their own scheme
/// (`cloudstream_ep:…`, `anilist:…`, `arabic_anime:…`) and must be passed
/// through untouched.
///
/// TMDB-backed series used to hand the player their numeric TMDB episode id,
/// which no source understands, so the id is rebuilt here from the show's IMDb
/// id whenever the episode does not already carry an IMDb-style id.
library;

/// The id [StreamService] should receive for an episode of [detailId].
///
/// - an existing `tt…` episode id wins;
/// - otherwise the show's IMDb id plus season/episode is rebuilt;
/// - provider-specific ids are kept;
/// - with no episode id at all, the show id plus numbers is the last resort.
String resolveEpisodeStreamId({
  required String detailId,
  String? episodeId,
  int? season,
  int? episode,
}) {
  final id = (episodeId ?? '').trim();

  if (id.startsWith('tt')) return id;

  if (detailId.startsWith('tt') && season != null && episode != null) {
    return '$detailId:$season:$episode';
  }

  if (id.isNotEmpty) return id;

  if (detailId.isEmpty) return '';
  return '$detailId:${season ?? 1}:${episode ?? 1}';
}
