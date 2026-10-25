# Unified Play Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One tap on Play resolves the best source and opens the player directly, with a sources button in the player that opens the cached source list, replacing the `WatchScreen` stop.

**Architecture:** Three new headless units — a pure `SourceRanker` (the ordering ported out of `WatchScreen`), an in-memory `PlaybackSourceCache` (session-scoped, 20 min TTL), and `AutoPlayService` (subscribes to `StreamService.fetchStreams`, ranks, completes early, keeps draining into the cache). The player receives the resolved list plus a cache key, seeds its existing per-episode map, and gains a top-bar sources button; the details page holds a progress button while resolving. `watch_screen.dart` is deleted and its two continue-watching call sites move onto the same service.

**Tech Stack:** Flutter 3.47.6 / Dart 3.11, `flutter_test`, no new packages.

**Spec:** `docs/superpowers/specs/2026-10-25-unified-play-flow-design.md`

## Global Constraints

- No new packages; no pubspec changes.
- `flutter analyze` must stay at **33 issues, 0 errors, 0 warnings**.
- Full `flutter test` baseline is **13 failures in 7 files**: `audio_language_detector_test`, `chunk1_vyla_test`, `chunk2_anime_vyla_test`, `download_service_test`, `models/my_list_item_test`, `movy_scraper_test`, `widgets/anime_search_page_test`. No new failures; a failure in any other file is a regression.
- Error isolation: a failing provider must never throw out of a scrape path. All new stream handling tolerates errors and empty results.
- Works on all five platforms; no platform-specific branches.
- `StreamService.fetchStreams` and `fetchStreamsForTargetAddon` call `stopAllScrapers()` on entry — assume one resolution at a time; never start two scrapes for one Play tap.
- Do **not** stage or modify `test/theme/app_theme_service_test.dart` (another author's uncommitted file).
- Do not change the colour literals in `player_sources_panel.dart`, `player_top_bar.dart` or `player_screen.dart`; their token migration belongs to a later phase.
- Commit per task, directly on `main`. Never push to the `upstream` remote.

## Review Focus

Five conditions the spec implies but no happy-path test exercises. Each is pinned by a test in the task that owns the code.

1. **A movie opens the sources panel with no cached list** (`episode == null`) — it must scrape at title level and never touch `episode!`. → Task 4, `title-level scrape when there is no episode`.
2. **Play, then back out while resolving** — no navigation after dispose, no leaked subscription, no stuck button. → Task 3 `cancel before any source completes` + Task 7 dispose wiring.
3. **Two rapid Play taps** — one scrape, one push. → Task 3 `starting twice for the same key returns the same session` + Task 7 in-flight guard.
4. **A title whose only sources are torrents arriving slowly** — must still start, and must never hang past the hard cap. → Task 3 `waits out the grace window` and `returns null at the hard cap`.
5. **A collection part** — plays as a movie with the part's own title/year, and the cache key the player seeds matches the one the resolver wrote. → Task 3 `forDetails scrapes a collection part` + Task 6 key scheme.

---

### Task 1: `SourceRanker` — port the ordering out of `WatchScreen`

**Files:**
- Create: `lib/services/stream/source_ranker.dart`
- Test: `test/services/source_ranker_test.dart`

**Interfaces:**
- Consumes: `StreamSource` (`addonName`, `providerId`, `qualityRank`, `seeders`, `isTorrent`, `isDebrid`), `BuiltinProvidersSettingsService` (`isCustom`, `instance.getProviderRank(String)`, `static String detectProviderId(StreamSource)`), `AddonManager.instance.addons`, `AddonManager.instance.isPlayTorrioActive`, `AddonManager.instance.isPlayTorrioHttpActive`.
- Produces, for Tasks 3, 4 and 6:
  ```dart
  typedef StreamSorter = List<StreamSource> Function(Iterable<StreamSource> sources);

  abstract final class SourceRanker {
    static const int unknownAddonOrder = 999;
    static Map<String, int> buildAddonOrder(Iterable<InstalledAddon> addons);
    static List<StreamSource> rank(
      Iterable<StreamSource> sources, {
      required Map<String, int> addonOrder,
      required bool customBuiltinProviders,
      required bool p2pActive,
      required bool httpActive,
    });
    static List<StreamSource> rankWithLiveSettings(Iterable<StreamSource> sources);
  }
  ```

**Source of truth:** `_WatchScreenState._addonOrder` (watch_screen.dart ~line 995) and the comparator in `_applyFilters`/`_sortSources` (watch_screen.dart ~line 373). Port both verbatim, minus the user-facing filters.

- [ ] **Step 1: Write the failing tests**

`test/services/source_ranker_test.dart`. Build sources with a small helper:
```dart
StreamSource src({
  String addon = 'AddonA',
  String? title,
  String? url,
  String? infoHash,
  String? providerId,
}) =>
    StreamSource(
      addonName: addon,
      title: title,
      url: url,
      infoHash: infoHash,
      providerId: providerId,
    );
```
A source is a torrent when it has an `infoHash` and no `url`, and debrid when it also has `url`. Quality comes from `title` (`'X 1080p'` → rank 3). Seeders come from `title` text (`'S: 50'`).

Tests (names are the requirement):
1. `drops non-debrid torrents when P2P is off` — `[torrent, http]` with `p2pActive: false` → only the http source.
2. `keeps debrid torrents when P2P is off` — a source with both `infoHash` and `url` survives.
3. `drops playtorriohttp when the built-in HTTP provider is off` — `addonName: 'playtorriohttp'` with `httpActive: false` is absent.
4. `orders by configured provider rank in custom mode` — two `playtorriohttp` sources with `providerId` ranks 2 and 0, `customBuiltinProviders: true` → rank-0 source first even when the other has better quality.
5. `orders by installed addon order outside custom mode` — `addonOrder: {'AddonA': 0, 'AddonB': 5}`, AddonB source has `1080p` and AddonA `480p` → AddonA first.
6. `orders by quality then seeders within one addon` — `1080p`/low seeders before `720p`/high seeders; two equal-quality sources order by seeders descending.
7. `keeps input order for fully equal candidates` — three identical sources come back in input order.
8. `buildAddonOrder maps manifest id, name and the playtorrio aliases` — an `InstalledAddon` whose `manifest.id` is `builtin.playtorriohttp` maps its index under `name.toLowerCase()`, `id.toLowerCase()` and `'playtorriohttp'`; same for `builtin.playtorrio` → `'playtorrio'`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/services/source_ranker_test.dart`
Expected: compile error, `SourceRanker` is not defined.

- [ ] **Step 3: Implement `lib/services/stream/source_ranker.dart`**

`rank` filters first (P2P rule, HTTP rule), then sorts with a comparator that returns, in this order:
1. custom-builtin provider rank ascending, **only when** `customBuiltinProviders` is true **and** both sources are `playtorriohttp`, using `providerId ?? BuiltinProvidersSettingsService.detectProviderId(source)`;
2. `addonOrder[addonName.toLowerCase()] ?? unknownAddonOrder` ascending;
3. `qualityRank` descending;
4. `seeders` descending (`null` counts as 0);
5. original input index ascending — capture it with `asMap()` / an `indexOf`-free precomputed list, because `List.sort` is not stable.

`rankWithLiveSettings` builds `addonOrder` from `AddonManager.instance.addons` (cached in a `static Map<String, int>? _cachedAddonOrder`), then passes `customBuiltinProviders: BuiltinProvidersSettingsService.instance.isCustom`, `p2pActive: AddonManager.instance.isPlayTorrioActive`, `httpActive: AddonManager.instance.isPlayTorrioHttpActive`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/services/source_ranker_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/services/stream/source_ranker.dart test/services/source_ranker_test.dart
git commit -m "feat(stream): extract source ordering into SourceRanker"
```

---

### Task 2: `PlaybackSourceCache` — session cache for resolved sources

**Files:**
- Create: `lib/services/stream/playback_source_cache.dart`
- Test: `test/services/playback_source_cache_test.dart`

**Interfaces:**
- Consumes: `StreamSource`.
- Produces, for Tasks 3, 4, 6, 7:
  ```dart
  abstract final class PlaybackSourceCache {
    static Duration ttl = const Duration(minutes: 20);
    static DateTime Function() now = DateTime.now;   // test seam
    static String keyFor({required String type, required String id, int? season, int? episode});
    static List<StreamSource>? read(String key);
    static void write(String key, List<StreamSource> sources);
    static void clear();
  }
  ```

- [ ] **Step 1: Write the failing tests**

`test/services/playback_source_cache_test.dart`, with `setUp(PlaybackSourceCache.clear)` and `tearDown` restoring `now = DateTime.now` and `ttl = const Duration(minutes: 20)`:
1. `keyFor builds type:id:season:episode with zeros when absent` — `keyFor(type: 'movie', id: 'tt1')` → `'movie:tt1:0:0'`.
2. `keyFor separates episodes of one series` — `(1,3)` and `(1,4)` differ.
3. `read returns what was written, overwriting on rewrite` — write 2 sources, rewrite with 1, `read` length is 1.
4. `read returns null once the ttl has passed` — set `now` to a fixed clock, write, advance `now` past `ttl`, expect `null`.
5. `clear empties every entry`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/services/playback_source_cache_test.dart`
Expected: compile error, `PlaybackSourceCache` is not defined.

- [ ] **Step 3: Implement `lib/services/stream/playback_source_cache.dart`**

A `static final Map<String, _Entry> _entries` holding the list plus the `DateTime` written; `read` deletes and returns `null` when `now().difference(writtenAt) > ttl`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/services/playback_source_cache_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/services/stream/playback_source_cache.dart test/services/playback_source_cache_test.dart
git commit -m "feat(stream): add session source cache"
```

---

### Task 3: `AutoPlayRequest` + `AutoPlayService` — resolve, rank, complete early, keep draining

**Files:**
- Create: `lib/services/stream/auto_play_service.dart`
- Test: `test/services/auto_play_service_test.dart`

**Interfaces:**
- Consumes: `SourceRanker`/`StreamSorter` (Task 1), `PlaybackSourceCache` (Task 2), `StreamService.fetchStreams`, `resolveEpisodeStreamId` (`utils/stream/stream_ids.dart`), `MovieDetail`, `Video`.
- Produces, for Tasks 6, 7, 8:
  ```dart
  class AutoPlayRequest {
    final MovieDetail detail;
    final Video? episode;
    final String scrapeType;      // 'movie' for a collection part, else the content type
    final String scrapeId;
    final String scrapeTitle;
    final int? scrapeYear;
    final int? season;
    final int? episodeNumber;
    final List<String> genres;
    final String cacheKey;

    factory AutoPlayRequest.forDetails({
      required MovieDetail detail,
      Video? episode,
      required String type,
      required bool isCollection,
    });
  }

  class AutoPlayResult {
    final StreamSource source;
    final List<StreamSource> sources;
    final String cacheKey;
    final bool fromCache;
  }

  class AutoPlaySession {
    Future<AutoPlayResult?> get result;
    void cancel();
  }

  typedef SourceStreamFactory = Stream<StreamSource> Function();

  abstract final class AutoPlayService {
    static void reset();                          // test seam: drops in-flight tracking
    static AutoPlaySession start(
      AutoPlayRequest request, {
      SourceStreamFactory? sourceStreamFactory,   // default: live StreamService
      StreamSorter? ranker,                       // default: SourceRanker.rankWithLiveSettings
      Duration earlyCompleteGrace = const Duration(seconds: 4),
      Duration hardCap = const Duration(seconds: 20),
      Duration drainCap = const Duration(seconds: 60),
    });
  }
  ```

**Transform required by `forDetails`** — ported from `watch_screen.dart:186-215`:
- `scrapeId = episode == null ? detail.id : resolveEpisodeStreamId(detailId: detail.id, episodeId: episode.id, season: episode.season, episode: episode.episode)`
- collection part (`isCollection && episode != null`): `scrapeType = 'movie'`, `scrapeTitle = episode.title`, `scrapeYear = int.tryParse` of the first 4 chars of `episode.released`, `season = null`, `episodeNumber = null`
- otherwise: `scrapeType = type`, `scrapeTitle = detail.name`, `scrapeYear = int.tryParse(detail.year ?? '')`, `season = episode?.season`, `episodeNumber = episode?.episode`
- `genres = detail.genres`
- `cacheKey = PlaybackSourceCache.keyFor(type: scrapeType, id: scrapeId, season: season, episode: episodeNumber)`

- [ ] **Step 1: Write the failing tests**

`test/services/auto_play_service_test.dart`, with `setUp(() { PlaybackSourceCache.clear(); AutoPlayService.reset(); })`. Use `earlyCompleteGrace`/`hardCap` of 20–40 ms in timer tests and drive streams with `StreamController<StreamSource>`.

1. `forDetails scrapes a plain movie as itself` — title/year from the detail, `season`/`episodeNumber` null, `cacheKey == 'movie:tt1:0:0'`.
2. `forDetails scrapes a collection part as a movie with the part title and year` — `isCollection: true`, episode `title: 'Part Two'`, `released: '2019-05-01'` → `scrapeType 'movie'`, `scrapeTitle 'Part Two'`, `scrapeYear 2019`, null season/episode, and `cacheKey` contains the part's id.
3. `forDetails keeps season and episode for a series` — `cacheKey == 'series:tt2:1:3'` for season 1 episode 3.
4. `start returns cached sources without scraping` — write two sources to the key, pass a factory that fails the test if called → `fromCache true`, one factory call count of 0.
5. `start completes early on a non-torrent source` — emit an http source, then (later) a torrent → result is the http source, obtained before the second emission.
6. `start waits out the grace window when only torrents arrive` — emit one torrent, keep the stream open, `earlyCompleteGrace: 20ms` → result arrives after ~20 ms with that torrent.
7. `start completes when the stream closes` — emit a torrent and close immediately → result without waiting for the grace.
8. `start returns null when the stream is empty` — closed empty stream.
9. `start returns null at the hard cap` — open stream with no emissions, `hardCap: 20ms`.
10. `cancel before any source completes the result with null and delivers nothing` — call `cancel()` immediately, then emit → result `null`.
11. `starting twice for the same key returns the same session` — identity check on `start(...)` twice.
12. `keeps draining into the cache after completing` — after the result completes, emit another source; `PlaybackSourceCache.read(cacheKey)` eventually contains it.
13. `deduplicates identical sources` — two sources with the same `infoHash` and `addonName` appear once.
14. `uses the injected ranker for the chosen source` — pass `(s) => s.toList().reversed.toList()` with two http sources and assert the second-listed one wins.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/services/auto_play_service_test.dart`
Expected: compile error, `AutoPlayService` is not defined.

- [ ] **Step 3: Implement `lib/services/stream/auto_play_service.dart`**

Session shape: a `Completer<AutoPlayResult?>`, a `StreamSubscription`, and a `List<StreamSource> _collected` plus `bool _done`.

- `start` first returns `_inFlight[request.cacheKey]` when present; else checks the cache (non-empty → an already-completed session) and otherwise builds one, registers it in `_inFlight`, and removes it when the result completes.
- The default `sourceStreamFactory` yields `request.episode?.streams` first, then `StreamService.fetchStreams(type: request.scrapeType, id: request.scrapeId, title: request.scrapeTitle, year: request.scrapeYear, season: request.season, episode: request.episodeNumber, genres: request.genres)`.
- On each emitted source: dedupe, add, `PlaybackSourceCache.write(cacheKey, ranked)`, and complete when the ranked-first candidate is not a torrent, or when the grace timer (started on the first emission) fires.
- Complete with the ranked-first on stream `done`; start a `hardCap` timer that completes with the best-so-far (or `null`) if nothing has arrived; on error, complete like `done`.
- After completing the result, keep the subscription for up to `drainCap` so later sources keep landing in the cache, then cancel it. `cancel()` cancels the subscription, completed timers, completes a pending result with `null`, and clears `_inFlight` for the key.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/services/auto_play_service_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/services/stream/auto_play_service.dart test/services/auto_play_service_test.dart
git commit -m "feat(stream): add AutoPlayService that resolves and caches the best source"
```

---

### Task 4: `PlayerSourcesPanel` — movies, ranking, title-level scrape

**Files:**
- Modify: `lib/widgets/player/player_sources_panel.dart`
- Test: `test/widgets/player/player_sources_panel_test.dart` (create the directory)

**Interfaces:**
- Consumes: `StreamSorter`, `SourceRanker.rankWithLiveSettings`, `SourceStreamFactory`, `StreamService.fetchStreamsForTargetAddon`.
- Produces, for Task 6:
  ```dart
  final Video? episode;
  final VoidCallback? onBackToEpisodes;
  final Function(StreamSource source, Video? episode) onPlaySource;
  final StreamSorter ranker;                     // defaults to SourceRanker.rankWithLiveSettings
  @visibleForTesting final SourceStreamFactory? sourceStream;
  ```

- [ ] **Step 1: Write the failing tests**

`test/widgets/player/player_sources_panel_test.dart`. Pump inside `MaterialApp(home: Scaffold(body: SizedBox(width: 420, height: 800, child: panel)))` wrapped in a `MediaQuery`; keep identity `ranker: (s) => s.toList()` except where ordering is the assertion.

1. `renders a movie's cached sources without scraping` — `episode: null`, `cachedSources` with two sources, `sourceStream: () => throw StateError('scraped')` → both rows visible, no throw.
2. `renders rows in ranker order` — `ranker: (s) => s.toList().reversed.toList()`, assert the row order in the widget tree matches the reversed list.
3. `tapping a row reports a null episode for a movie` — `onPlaySource` captures `(source, episode)`; assert `episode == null` and the right source.
4. `hides the back-to-episodes affordance for a movie` — `onBackToEpisodes: null` → no 'Episodes' label; with a callback → present.
5. `title-level scrape when there is no episode` — `episode: null`, `cachedSources: null`, `detail` with `id: 'tt9'`, `sourceStream: () => Stream.value(src(title: 'Movie 1080p'))` → after `pumpAndSettle` one row appears and the widget did not throw.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widgets/player/player_sources_panel_test.dart`
Expected: compile errors on `episode: null` / unknown `ranker`.

- [ ] **Step 3: Modify `lib/widgets/player/player_sources_panel.dart`**

- Make `episode`, `onBackToEpisodes` and the `onPlaySource` episode parameter nullable; every `widget.episode!` use becomes a null-safe read (`widget.episode?.season`, `widget.episode?.episode`).
- `_startScraping`: when `widget.episode == null`, use `id: widget.detail!.id`, `season: null`, `episode: null` in the existing `fetchStreamsForTargetAddon` call; when `sourceStream` is non-null use it instead of any live scrape.
- Build the visible list as `widget.ranker(_sources)` instead of `_sources`.
- Header: show `S…E…` only when `widget.episode != null`; otherwise just the title.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/widgets/player/player_sources_panel_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/player/player_sources_panel.dart test/widgets/player/player_sources_panel_test.dart
git commit -m "feat(player): support movies and ranked ordering in the sources panel"
```

---

### Task 5: `PlayerTopBar` — sources button

**Files:**
- Modify: `lib/widgets/player/player_top_bar.dart`
- Test: `test/widgets/player/player_top_bar_test.dart`

**Interfaces:**
- Consumes: existing `PlayerTopBar` params.
- Produces, for Task 6:
  ```dart
  final VoidCallback? onShowSources;
  final bool isSourcesActive;
  ```

- [ ] **Step 1: Write the failing tests**

`test/widgets/player/player_top_bar_test.dart`, pumping the bar under the app theme:
1. `shows a sources button that fires its callback` — `find.byTooltip('Sources')`, tap, callback fires once.
2. `disables the sources button when no callback is given` — `onShowSources: null` → the `IconButton`'s `onPressed` is null.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widgets/player/player_top_bar_test.dart`
Expected: `find.byTooltip('Sources')` finds nothing.

- [ ] **Step 3: Modify `lib/widgets/player/player_top_bar.dart`**

Add the two fields (defaults `null` / `false`). Insert an `IconButton` with `icon: const Icon(Icons.source_rounded, size: 20)`, `tooltip: 'Sources'`, `onPressed: onShowSources`, in the trailing action row immediately **before** the episodes toggle. When `isSourcesActive` is true, tint the icon with `PlayTorrioTokens.of(context).accent`; otherwise leave the existing default icon colour untouched.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/widgets/player/player_top_bar_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/player/player_top_bar.dart test/widgets/player/player_top_bar_test.dart
git commit -m "feat(player): add sources button to the top bar"
```

---

### Task 6: `PlayerScreen` — seed the cache, open the panel for movies

**Files:**
- Modify: `lib/pages/player/player_screen.dart` (fields ~line 60; `initState` ~line 200; `_toggleEpisodesPanel` ~line 1259; `PlayerTopBar` ~line 2110/2162; panel block ~line 2437; error-path guards ~lines 517 and 1151)
- Test: covered by Tasks 4 and 5 plus the Task 9 gates (no cheap widget test exists for this 4,000-line screen — state that in the commit body)

**Interfaces:**
- Consumes: `PlaybackSourceCache.keyFor`, `SourceRanker` default in the panel, new `PlayerTopBar.onShowSources`/`isSourcesActive`, nullable `PlayerSourcesPanel.episode`.
- Produces, for Tasks 7 and 8:
  ```dart
  final List<StreamSource>? initialSources;
  final String? sourceCacheKey;
  ```

- [ ] **Step 1: Add the fields and the key scheme**

Add the two constructor fields (both optional). Add:
```dart
String _sourcesKeyFor(Video? episode) {
  if (episode != null && episode == widget.episode && widget.sourceCacheKey != null) {
    return widget.sourceCacheKey!;
  }
  return PlaybackSourceCache.keyFor(
    type: widget.detail?.type ?? 'movie',
    id: widget.detail?.id ?? '',
    season: episode?.season,
    episode: episode?.episode,
  );
}
```
and in `initState`, before any panel can open:
```dart
final initial = widget.initialSources;
if (initial != null && initial.isNotEmpty) {
  _cachedSourcesByEpisode[_sourcesKeyFor(widget.episode)] = List<StreamSource>.from(initial);
}
```

- [ ] **Step 2: Wire the button and the panel**

- Add `void _toggleSourcesPanel()` that sets `_sourcesEpisode = _currentEpisode; _sourcesErrorMessage = null; _showSourcesPanel = !_showSourcesPanel;` (keep controls visible as the existing handlers do).
- Pass `onShowSources: _isLoading ? null : _toggleSourcesPanel` and `isSourcesActive: _showSourcesPanel || _showEpisodesPanel` to both `PlayerTopBar` constructions.
- Change the panel guard from `if (_showSourcesPanel && _sourcesEpisode != null && !_isLoading)` to `if (_showSourcesPanel && !_isLoading)`, pass `episode: _sourcesEpisode`, `onBackToEpisodes: (widget.detail?.videos.isNotEmpty ?? false) ? _onBackToEpisodes : null`, and `cachedSources: _cachedSourcesByEpisode[_sourcesKeyFor(_sourcesEpisode)]`.
- In `onSourcesLoaded`, store under `_sourcesKeyFor(_sourcesEpisode)` and also `PlaybackSourceCache.write(key, sources)`.
- Relax the two error-path conditions (`_currentEpisode != null && widget.detail!.videos.isNotEmpty`) to `widget.detail != null`, so a failed movie source opens the panel too.
- `_playNewSource(StreamSource newSource, Video? episode)`: keep the existing body, make the episode nullable, and keep writing the new list to `_cachedSourcesByEpisode`.

- [ ] **Step 3: Verify it compiles and the neighbours still pass**

Run: `flutter analyze lib/pages/player/player_screen.dart`
Expected: no new issues (33-issue total unchanged).
Run: `flutter test test/widgets/player`
Expected: All tests passed.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/player/player_screen.dart
git commit -m "feat(player): seed source cache and open the panel for movies"
```

---

### Task 7: `DetailsPage` — resolve on the page, then push the player

**Files:**
- Modify: `lib/pages/details/details_page.dart` (state fields ~line 80; `dispose` ~line 175; `_handlePlayAction` 187-201; `_buildPlayButton` 1087-1118; episode row tap ~1498)
- Test: none beyond the Task 3 unit tests; verification is Step 4

**Interfaces:**
- Consumes: `AutoPlayRequest.forDetails`, `AutoPlayService.start`, `PlaybackSourceCache` (indirectly), `PlayerScreen.initialSources`/`sourceCacheKey` (Task 6), `AppDialog(title:, message:, actions:)`, `CinematicSlideRoute`.
- Produces: nothing other tasks import.

- [ ] **Step 1: Replace `_handlePlayAction`**

```dart
Future<void> _handlePlayAction(Video? ep) async {
  final detail = _detail;
  if (detail == null || _isResolvingPlayback) return;

  final request = AutoPlayRequest.forDetails(
    detail: detail,
    episode: ep,
    type: _resolvedType ?? detail.type,
    isCollection: _isCollection,
  );

  setState(() => _isResolvingPlayback = true);
  final session = _playSession = AutoPlayService.start(request);
  final result = await session.result;
  if (_playSession == session) _playSession = null;
  if (!mounted) return;
  setState(() => _isResolvingPlayback = false);

  if (result == null) {
    _showNoSourceDialog(ep);
    return;
  }

  Navigator.push(
    context,
    CinematicSlideRoute(
      page: PlayerScreen(
        source: result.source,
        initialSources: result.sources,
        sourceCacheKey: result.cacheKey,
        title: request.scrapeTitle,
        backdropUrl: detail.background,
        logoUrl: detail.logo,
        detail: detail,
        episode: ep,
      ),
    ),
  );
}
```
Add `bool _isResolvingPlayback = false; AutoPlaySession? _playSession;` next to the other state fields, and cancel it in `dispose` (`_playSession?.cancel();`) before `super.dispose()`.

- [ ] **Step 2: Progress state on the play button**

In `_buildPlayButton`, keep the gradient container but: label becomes `_isResolvingPlayback ? 'Finding source…' : (existing ternary)`, the leading icon becomes a `SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))` while resolving, and `onTap` becomes `() {}` while resolving (the guard in `_handlePlayAction` is the real protection; `_HoverButton.onTap` is non-nullable).

- [ ] **Step 3: The no-source dialog**

`_showNoSourceDialog(Video? ep)` shows `AppDialog(title: 'No working source found', message: 'None of the enabled sources returned a playable stream.', actions: [AppButton(label: 'Cancel', variant: AppButtonVariant.tertiary, onPressed: () => Navigator.pop(context)), AppButton(label: 'Retry', onPressed: () { Navigator.pop(context); _handlePlayAction(ep); })])` via `showDialog`.

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/pages/details/details_page.dart`
Expected: no new issues.
Manual: open a movie with addons enabled, tap Play → the button shows "Finding source…", the player opens by itself, and no selection page appears.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/details/details_page.dart
git commit -m "feat(details): resolve the best source on Play instead of opening WatchScreen"
```

---

### Task 8: Continue-watching onto the same service; delete `WatchScreen`

**Files:**
- Modify: `lib/services/continue_watching/continue_watching_service.dart` (first-launch site ~503-521, fallback ~924-935)
- Delete: `lib/pages/player/watch_screen.dart`
- Test: none new; the dead-source rescrape keeps its existing scoring, and Task 3 covers the resolution

**Interfaces:**
- Consumes: `AutoPlayRequest.forDetails`, `AutoPlayService.start`, `PlayerScreen.initialSources`/`sourceCacheKey` (Task 6).

- [ ] **Step 1: Replace the first-launch push**

Replace the `WatchScreen(...)` push with `AutoPlayService.start(AutoPlayRequest.forDetails(detail: movieDetail, episode: video, type: item.type, isCollection: false))`, awaited with a progress dialog (reuse the dialog already used on the neighbouring resume path), then push `PlayerScreen(source:, initialSources:, sourceCacheKey:, title:, backdropUrl: item.backdropUrl, detail: movieDetail, episode: video, initialPosition: Duration(seconds: item.positionSeconds))`. On `null`, show a SnackBar ("No working source found") and return without navigating.

- [ ] **Step 2: Replace the dead-source fallback**

Keep `calculateSourceMatchScore` and the existing "top candidate wins whenever any candidate exists" rule untouched. Only the `else` branch (zero candidates) changes from `WatchScreen(...)` to the same `AutoPlayService` + `PlayerScreen` push as Step 1.

- [ ] **Step 3: Delete the page**

```bash
git rm lib/pages/player/watch_screen.dart
```
Remove its import from `continue_watching_service.dart`. Confirm no reference remains:
`Get-ChildItem lib -Recurse -Filter *.dart | Select-String -Pattern "WatchScreen"` → no output.

- [ ] **Step 4: Verify**

Run: `flutter analyze`
Expected: 33 issues, 0 errors, 0 warnings (the deleted file removes its own existing infos; if the total *drops*, that is fine — record the new number in the commit body).

- [ ] **Step 5: Commit**

```bash
git add -A lib/services/continue_watching/continue_watching_service.dart lib/pages/player
git commit -m "feat(playback): route continue-watching through AutoPlay and delete WatchScreen"
```

---

### Task 9: Full verification

**Files:** none.

- [ ] **Step 1: Analysis gate**

Run: `flutter analyze`
Expected: 0 errors, 0 warnings; total ≤ 33.

- [ ] **Step 2: New and neighbouring tests**

Run: `flutter test test/services/source_ranker_test.dart test/services/playback_source_cache_test.dart test/services/auto_play_service_test.dart test/widgets/player test/udl`
Expected: All tests passed.

- [ ] **Step 3: Full suite against the baseline**

Run: `flutter test`
Expected: failures only in the 7 baseline files; no failure in `test/services`, `test/widgets`, `test/udl`.

- [ ] **Step 4: Colour guard untouched**

Run: `flutter test test/udl/no_inline_colors_test.dart`
Expected: passes with the same 26 migrated files — this change adds no literals to the guard and removes none from it.

- [ ] **Step 5: Manual checklist (dev machine, emerald theme, P2P off)**

1. Movie, healthy provider: one Play tap → player opens; no selection page.
2. Sources icon mid-playback → panel opens with no spinner; switching keeps position.
3. Series Play → current season's first episode starts; the panel lists that episode.
4. P2P off + HTTP provider off → "No working source found" dialog, no player pushed.
5. Continue-watching with a dead saved source → lands on a working player.
6. Collection "Play First Movie" → the part plays.
7. Airplane mode → dialog, no crash, the button returns to "Play".

- [ ] **Step 6: Commit any fixups, then report**

Summarise: files created/modified/deleted, the analyze/test numbers, and anything flagged during the work (per `AGENTS.md`).
