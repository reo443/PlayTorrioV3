# Unified play flow — design

Date: 2026-10-25
Status: draft for approval
Repo: PlayTorrioV3 (Flutter 3.47.6 / Dart 3.11)

## Intent

Today playback takes three surfaces:

1. **`details_page.dart`** — the poster click lands here. `Play Movie` / `Play Episodes`
   calls `_handlePlayAction`, which pushes `WatchScreen`.
2. **`watch_screen.dart`** (3,633 lines) — a full page that re-renders the backdrop,
   logo, synopsis and genre pills, then a sources card with type chips and seeder /
   size / addon / audio filters. Picking a row pushes `PlayerScreen`.
3. **`player_screen.dart`** — playback. It already owns `PlayerSourcesPanel`, a
   right-aligned (`Align(centerRight)`) panel that can switch source mid-playback from
   `cachedSources`, but it is only reachable **on error**, and only for TV
   (`_currentEpisode != null && detail.videos.isNotEmpty`). For movies it is unreachable.

Two problems follow:

- `WatchScreen` is a mandatory stop whose only job is picking a source, and it throws the
  scraped list away: `PlayerScreen(source: s, …)` receives one `StreamSource`, so the
  in-player panel must re-scrape. That re-scrape is the lag when the panel opens.
- Movies have no way back to the source list at all, because the panel's guards require an
  episode.

## Decisions taken

These come from the human partner and are not open:

- **D1 — Resolve-then-push.** Tapping Play resolves sources while the user stays on the
  details page (button shows progress). The player is pushed only once a source is chosen.
  No intermediate selection page, no player screen without a source.
- **D2 — Delete `WatchScreen`.** It leaves the flow and the file is deleted.
- **D3 — Port the ordering, drop the filters.** The provider/quality ordering moves into
  one shared ranker. The manual filters (type, seeders, size, addon, audio) are not
  carried anywhere.
- **D4 — Cached panel.** The player gets a sources button that opens the right-hand panel
  from a cache, so opening it never re-scrapes.

## Goals

- **G1** One tap on Play starts the best available source, with no intermediate page.
- **G2** The sources button works for movies and episodes, and the panel opens from cache.
- **G3** Switching source keeps the episode context, resume position and subtitle choice.
- **G4** One code path serves details, continue-watching resume, and dead-source fallback.

## Non-goals

- A player state without a source (`PlayerScreen.source` stays required).
- Preserving the manual filters in any UI, including the player panel.
- A persistent, cross-session source cache.
- Redesigning the details page, the player chrome, or the panel's visual language.
  `player_sources_panel.dart` still carries 43 colour literals; its colour migration
  belongs to the player phase, not here.
- Anime / manga / audiobook / music playback paths.

## Anti-goals

Anything on this list means the design failed even if the tests pass:

- Auto-selection that starts playback **later** than today's `WatchScreen` path on a cold
  cache.
- A black, dead or error-flashing player screen while scraping.
- Opening the panel triggers a scrape when a list is already known.
- Losing resume position, subtitle selection or the current episode when the user switches
  source.
- Three different ways to pick a source surviving the change.

## Constraints

- No new packages.
- A failing provider must never abort resolution (`AGENTS.md`, error isolation).
- Must work on all five platforms; no platform-specific code paths.
- `StreamService.fetchStreams` is a `Stream<StreamSource>` and calls `stopAllScrapers()`
  on entry, so only one resolution should be in flight at a time.
- Existing gates: `flutter analyze` at 33 issues (0 errors / 0 warnings); the full test
  suite's 13 baseline failures are pre-existing and must not grow.

## Architecture

### 1. `lib/services/stream/source_ranker.dart` (new)

```dart
abstract final class SourceRanker {
  static List<StreamSource> rank(
    Iterable<StreamSource> sources, {
    required Map<String, int> addonOrder,
    required bool customBuiltinProviders,
    required bool p2pActive,
    required bool httpActive,
  });
}
```

Pure and synchronous, so it is testable without providers.

- **Filter** (ported from `_WatchScreenState`): when P2P is off, drop torrents that are not
  debrid; when the built-in HTTP provider is off, drop `addonName == 'playtorriohttp'`.
- **Order**, ported verbatim from `_WatchScreenState`'s comparator:
  1. With custom built-in providers configured, and both candidates from
     `playtorriohttp`: provider rank from
     `BuiltinProvidersSettingsService.instance.getProviderRank(...)` ascending
     (`providerId ?? detectProviderId(source)`).
  2. Otherwise installed-addon order (`AddonManager.instance.addons` index, keyed by
     manifest name and id; 999 when unknown).
  3. Within the same addon/provider: `qualityRank` descending (4K > 1080p > 720p > 480p >
     unknown).
  4. Then seeders descending.
  5. Then the original index, so the result is deterministic (Dart's `sort` is not
     stable).

The ranker takes `addonOrder` as an argument rather than reading `AddonManager` itself, so
tests can inject it; the caller builds it once per session and caches it, exactly as
`_addonOrder` does today.

### 2. `lib/services/stream/playback_source_cache.dart` (new)

Session-scoped, in memory, no persistence.

```dart
abstract final class PlaybackSourceCache {
  static String keyFor({required String type, required String id, int? season, int? episode});
  static List<StreamSource>? read(String key);
  static void write(String key, List<StreamSource> sources);
  static void clear();
}
```

- Key shape `type:id:season:episode`, with `0` for absent season/episode, so a movie and
  every episode of a series get distinct entries.
- Entries expire after **20 minutes**; `read` returns `null` when stale.
- `write` stores the newest list; the resolver writes partial lists as scraping
  progresses, so a later open sees more.

### 3. `lib/services/stream/auto_play_service.dart` (new)

The single entry point the three call sites use.

```dart
class AutoPlaySession {
  Future<AutoPlayResult?> get result;
  void cancel();
}

class AutoPlayResult {
  final StreamSource source;
  final List<StreamSource> sources;
  final String cacheKey;
  final bool fromCache;
}

abstract final class AutoPlayService {
  /// `scrapeTitle` / `scrapeYear` / `season` / `episodeNumber` are the *scrape*
  /// parameters, which are not always the detail's own fields: a collection part
  /// scrapes as a movie using the part's title and year (see §6). `detail` and
  /// `episode` exist only for the player hand-off and the cache key.
  static AutoPlaySession start({
    required MovieDetail detail,
    Video? episode,
    required String type,
    required String scrapeTitle,
    int? scrapeYear,
    int? season,
    int? episodeNumber,
    required String cacheKey,
  });
}
```

Behaviour:

0. **Embedded streams first** — `episode?.streams` is prepended to the list before any
   scrape. `WatchScreen._loadStreams` did this; dropping it loses titles whose only
   playable sources ship inside the episode payload.
1. **Cache hit** — a non-empty, unexpired entry returns immediately with its best-ranked
   source (`fromCache: true`). No scrape.
2. **Otherwise** subscribe to `StreamService.fetchStreams(type:, id:, title:, year:,
   season:, episode:, genres:)` with the scrape parameters above — for a collection part
   that means `type: 'movie'`, the part's title and year, and no season/episode, exactly
   what `_loadStreams` did — and accumulate.
3. **Complete when** one of these happens, whichever is first:
   - the ranked-first candidate is **not a torrent** (direct HTTP or debrid) — this is the
     fast path, typically a few hundred ms after the first provider answers;
   - **4 seconds** have elapsed since the first source arrived (torrents only, so a
     torrent-only title still starts);
   - the stream **closes** (all providers finished);
   - the hard cap of **20 seconds** is reached, at which point the best-so-far is used.
4. **After completing**, keep draining the same subscription into
   `PlaybackSourceCache` for up to **60 seconds**, so the panel shows a fuller list than
   the moment of auto-play. Draining tolerates cancellation: if another scrape calls
   `stopAllScrapers`, the stream just ends and the cache keeps what it has.
5. **Failure** — nothing playable by the hard cap, or the stream errors: `result`
   completes with `null`, and the caller shows a retry.

`cancel()` closes the subscription immediately (used when the details page is disposed or
the user navigates away).

### 4. `player_sources_panel.dart` (modified)

- `episode` becomes `Video?`; `onBackToEpisodes` becomes `VoidCallback?`.
- Header reads "Sources"; the "back to episodes" affordance only renders when
  `onBackToEpisodes != null`.
- **It now ranks what it shows.** The panel currently renders arrival order. Because
  `WatchScreen` (the only ranked list today) is being deleted, the panel becomes the one
  place users see sources, so it sorts through `SourceRanker` — for both the cached and
  the freshly scraped list. That means threading `addonOrder` and the P2P / HTTP flags into
  the panel, or calling a small helper that supplies them.
- **Title-level scrape when there is no cache.** Today the panel scrapes from
  `episode.id`; with `episode: null` (a movie) it scrapes the title instead
  (`type`, `detail.id`, title, year, no season/episode), writes the result to
  `PlaybackSourceCache`, and ranks it. Without this a movie's panel has nothing to show.
- `cachedSources` keeps its current meaning: when non-empty the panel renders instantly
  and only probes bitrates in the background; when null/empty it scrapes as above.
- `onSourcesLoaded` keeps reporting the list upward so the caller writes it to
  `PlaybackSourceCache`.

Note on the cache promise: only the details/auto-play path (and any later path that has
already scraped) hands the panel a list, so its **first** open there is instant. The
continue-watching paths push a player with no list, so their first open still scrapes —
same as today, except it now works for movies — and every later open reads the cache.

### 5. `player_screen.dart` (modified)

- New fields `final List<StreamSource>? initialSources;` and
  `final String? sourceCacheKey;`. The key is passed in rather than recomputed, because a
  collection part's key cannot be derived from `detail` + `episode` alone.
- `initState` seeds `_cachedSourcesByEpisode[key]` from `initialSources` — using
  `sourceCacheKey` when given, otherwise the key built from `detail` + `episode` — so the
  panel's first open is a cache read.
- Resources/top bar gains a **sources button** (all content types, not just TV) that sets
  `_sourcesEpisode` to the current episode (or `null` for a movie) and flips
  `_showSourcesPanel`.
- The two existing panel-opening guards that require
  `widget.detail?.videos.isNotEmpty == true` are relaxed for movies, so the
  "this source failed, pick another" flow also works there.
- `onSourcesLoaded` writes to `PlaybackSourceCache` under the same key.

### 6. `details_page.dart` (modified)

`_handlePlayAction` becomes:

1. Choose the target episode exactly as today (current season's first, else `videos.first`,
   else `null` for a movie).
2. Derive the scrape parameters exactly as `_loadStreams` did — including the collection
   case, which plays the part as a `movie` with the part's own title and year — and build
   the cache key from them.
3. Set `_isResolvingPlayback = true`; the play button swaps its label to
   "Finding source…" and shows a small progress indicator. The button stays inert while
   resolving.
4. `await AutoPlayService.start(...).result`.
5. On a result: push `PlayerScreen(source:, initialSources:, sourceCacheKey:, title:,
   backdropUrl:, logoUrl:, detail:, episode:)` and reset the flag. `initialPosition` is
   **not** passed: the details page has never resumed, and adding a progress lookup there
   is a separate behaviour change.
6. On `null`: an `AppDialog` — "No working source found" with **Retry** and **Cancel**
   (this replaces `WatchScreen`'s empty state).
7. `dispose` cancels an in-flight session.

### 7. `continue_watching_service.dart` (modified)

Two `WatchScreen` pushes, both replaced by the same service:

- **First-launch cloud item** (no local source) — currently `WatchScreen` so the user can
  pick manually; becomes resolve-then-push with the existing Arabic-style progress dialog.
- **Dead saved source** — keeps `calculateSourceMatchScore` for the rescrape and keeps
  today's rule: the top-scoring candidate wins if any candidate exists (there has never
  been a score floor; `950` is only an early-completion trigger). `AutoPlayService` runs
  **only** when that rescrape returns zero candidates, so the latency-sensitive path still
  performs exactly one scrape.

### 8. Deleted

`lib/pages/player/watch_screen.dart`. Only three references exist (`details_page` and the
two above); `_C` / `_S` are private to that file, so nothing else breaks.

## Flow after the change

```
poster tap → details page
  Play tap → resolve (button: "Finding source…")
            ├─ cache hit ────────────────┐
            └─ scrape → rank → first good │
                                          ↓
                             PlayerScreen(source, initialSources)
                                          ↓
                       playback starts; sources icon → panel (cache read, instant)
                                          ↓
                             pick another → swap in place
```

## Failure behaviour

| Situation | Behaviour |
|---|---|
| No sources at all | Dialog with Retry/Cancel on the details page; nothing navigates |
| Scrape errors on every provider | Same dialog (error isolation already prevents exceptions) |
| Best source fails during playback | Existing player error path; now the panel opens for movies too, with "Source failed to play. Select another source." |
| User leaves the details page mid-resolve | Session cancelled; no navigation, no leaked subscription |
| Cached URL is dead | The player's error path reopens the panel; picking a source refreshes the cache entry |

## Testing

- **`source_ranker_test.dart`** — provider-rank ordering in custom mode; addon order;
  quality then seeders; P2P-off drops non-debrid torrents; HTTP-off drops
  `playtorriohttp`; equal candidates keep input order (determinism).
- **`playback_source_cache_test.dart`** — movie vs episode keys are distinct; overwrite
  replaces; expiry returns null; `clear` empties.
- **`auto_play_service_test.dart`** — with an injected stream: completes early on a
  non-torrent; waits for the 4s grace on torrents only; completes on close; returns null at
  the cap; cache hit returns `fromCache: true` without scraping; `cancel` stops delivery.
- **`player_sources_panel_test.dart`** — `episode: null` + `cachedSources` renders rows
  without scraping and in ranker order; tapping a row calls `onPlaySource`; no
  back-to-episodes row for a movie; a movie with no cache scrapes at title level.
- **`source_ranker_test.dart`** also covers the collection/normalisation case indirectly:
  the ranker is pure, so the transform is tested through `AutoPlayService`'s scrape-param
  construction instead.
- **No widget test for the details page** — it needs addons, metadata and
  `SharedPreferences`; it stays covered by the manual check, as the UDL phases do.
- Gates: `flutter analyze` (33 issues, 0/0), `flutter test test/services
  test/widgets/player`, then the full suite against the 13-failure baseline.

## Manual verification

1. Movie with a healthy provider: one tap plays; the player appears without a selection
   page.
2. Sources icon mid-playback → panel opens with no spinner; switching keeps the position.
3. Series: Play starts the current season's first episode; the panel lists that episode's
   sources.
4. P2P off, HTTP off → the "No working source found" dialog appears instead of a dead
   player.
5. Continue-watching entry with a dead saved source → lands on the player with a working
   source.
6. A collection's "Play First Movie" resolves the part as a movie and plays it.
7. Airplane mode → dialog, no crash, no stuck button.

## Calls I made (check these while reading)

- **No direct-before-torrent tier.** The existing comparator has no type tier, and adding
  one would silently outrank the user's configured provider order. The ranker therefore
  ports exactly what `WatchScreen` did. *(This is the one I would most like you to
  confirm or overrule.)*
- **The panel now sorts with the same ranker.** Deleting `WatchScreen` removes the only
  ranked list in the app; leaving the panel in arrival order would mean the ordering you
  asked me to port is never seen by a user. Cost: the panel needs `addonOrder` and the
  P2P/HTTP flags threaded in.
- **Embedded episode streams are kept.** `episode.streams` is prepended exactly as
  `_loadStreams` did; without it some titles would resolve to nothing.
- **Collections keep today's transform** — the chosen part scrapes as a `movie` with the
  part's title and year. The cache key therefore travels to the player as a string rather
  than being re-derived.
- **Early-completion rule**: first non-torrent, else a 4s grace, else stream close, else a
  20s cap.
- **Cache TTL 20 minutes**, session-scoped, in memory.
- **No resume from the details page.** `initialPosition` stays null on that path, exactly
  as today; resuming remains the continue-watching entry's job. Adding a progress lookup
  to the details page would be a second, separate behaviour change.
- **No score floor on the dead-source fallback** — top candidate wins whenever one exists,
  so that path still does one scrape.
- **The panel's colours stay untouched** in this change; they belong to the player phase.
- **No prefetch**: sources are scraped on Play, not when the details page opens. Eager
  prefetch would make Play feel instant but triples the scrape volume while browsing.
