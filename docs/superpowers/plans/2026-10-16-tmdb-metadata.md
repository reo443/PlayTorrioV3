# TMDB Metadata Replacement — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Stremio/Cinemeta metadata layer with TMDB as the sole metadata + catalog source for movies & TV (user addons provide streams only), with the API key loaded from an untracked `.env` file.

**Architecture:** A new static `TmdbService` mirrors the existing `MetadataService` pattern (static methods, in-memory caches). TMDB items reuse the existing `Movie`/`MovieDetail`/`MovieSection` models: catalog items get `id: 'tmdb:<id>'` and `addonBaseUrl: 'tmdb'` (sentinel), details resolve IMDb IDs via TMDB `external_ids` so stream scraping keeps working. Every consumer routes on the sentinel `addonBaseUrl == 'tmdb'` and falls back to the existing Cinemeta path only while no API key is configured.

**Tech Stack:** Dart/Flutter, `http` (existing), `rootBundle` asset-based `.env` (no new package), TMDB API v3.

**Spec:** User requirements from session: "Full replacement — TMDB replaces everything including addon catalog browsing; user Stremio addons would only provide streams, never catalogs or metadata." Key handling: "just use .env i will add it later."

## Global Constraints

- Never commit the real `.env`; commit `.env.example` with `TMDB_API_KEY=` placeholder. Add `.env` to `.gitignore`.
- All TMDB requests use `language=en-US` and v3 auth (`api_key` query param).
- A missing/empty key must not crash or empty the app: consumers fall back to the existing Cinemeta/Stremio path until the key is added.
- TMDB-sourced catalog items must preserve the Stremio id convention: movies/series `tmdb:<numeric id>`; details must expose the IMDb id (`tt…`) because scrapers resolve by IMDb.
- `flutter analyze` must end with zero errors/warnings and no new infos vs the 33-info baseline; existing tests must stay at their baseline pass/fail state.
- Error isolation: every TMDB fetch returns empty/`null` on failure — never throws across a page boundary.

## Review Focus

- **Missing/invalid API key** (401 from TMDB): pages must fall back to the legacy Cinemeta path, not show empty grids or crash. Covered in Task 2 tests (401 → `isConfigured` stays true but fetch returns `[]`; empty key → `isConfigured == false`).
- **Old persisted items** (watch history / My List / Continue Watching stored with `tt…` or addon ids from Cinemeta days): the details page must still resolve them via the legacy path. Covered in Task 7's routing test (id prefixes route correctly).
- **Series without IMDb ids in TMDB** (rare, new shows): details must still render and episodes must load; scraping may be skipped (same as today's behavior when no IMDb id). Covered in Task 3's details fixture test.
- **Pagination duplicates** (TMDB trending lists shift between pages): catalog paging must dedupe by id like the current catalog does; covered in Task 6 tests.
- **Slow TMDB responses on Home**: sections must still stream progressively (yield as each arrives), not block on the slowest request; covered in Task 4 (async* preserved).

---

### Task 1: `.env` loading infrastructure

**Files:**
- Create: `lib/services/config/env_service.dart`
- Create: `.env.example`
- Modify: `pubspec.yaml` (assets: add `.env`)
- Modify: `.gitignore` (add `.env`)
- Modify: `lib/main.dart` (load before `runApp`)
- Test: `test/env_service_test.dart`

**Interfaces:**
- Produces: `EnvService.load()` → `Future<void>` (call once in `main` before `runApp`); `EnvService.get(String key)` → `String?`; `EnvService.isLoaded` → `bool`.

- [ ] **Step 1: Write the failing test** (`test/env_service_test.dart`): a pure parser test — parse a multi-line string `TMDB_API_KEY=abc123\n# comment\nEMPTY=` into a map; assert `get('TMDB_API_KEY') == 'abc123'`, comment lines ignored, quotes stripped (`KEY="quoted"` → `quoted`). Expose the parser as `@visibleForTesting static Map<String, String> parse(String contents)` so the test needs no asset bundle.
- [ ] **Step 2: Run test to verify it fails** — `flutter test test/env_service_test.dart`; expect compile error (EnvService undefined).
- [ ] **Step 3: Implement `EnvService`** — static `load()` reads asset `.env` via `rootBundle.loadString('assets/.env')` wrapped in try/catch (missing asset → no keys, `isLoaded=false`, no crash); `parse` splits lines, trims, skips `#`/empty, splits on first `=`, strips surrounding quotes. Also create `.env.example` with a single line `TMDB_API_KEY=`, add `.env` under `flutter: assets:` in pubspec, add `.env` to `.gitignore`.
- [ ] **Step 4: Wire `main`** — in `lib/main.dart` `main()` (before `runApp`, alongside existing init calls) add `await EnvService.load();`.
- [ ] **Step 5: Run test → pass; analyze; commit** — `flutter test test/env_service_test.dart` PASS; `flutter analyze` no new issues. Commit: `feat(env): load TMDB key from .env asset`.

### Task 2: TmdbService core + catalog list endpoints + Movie mapping

**Files:**
- Create: `lib/services/metadata/tmdb_service.dart`
- Modify: `lib/models/movie/movie.dart` (add `Movie.fromTmdb` factory)
- Test: `test/tmdb_service_test.dart`

**Interfaces:**
- Consumes: `EnvService.get('TMDB_API_KEY')` (Task 1).
- Produces: `TmdbService.kSentinel` (`'tmdb'`); `TmdbService.isConfigured` → `bool`; `TmdbService.fetchList(String listId, {int page = 1})` → `Future<List<Movie>>` where `listId` ∈ `trending_day`, `trending_week`, `popular_movie`, `popular_series`, `top_rated_movie`, `top_rated_series`, `now_playing`, `upcoming`, `genre_movie_<genreId>`, `genre_series_<genreId>`; `TmdbService.catalogTitle(String listId)` → display title; `Movie.fromTmdb(Map json, String mediaType)`.

- [ ] **Step 1: Write the failing test** — fixture maps (inline Dart maps, no network): a trending-style item (`media_type: 'movie', id: 123, title: 'Test', poster_path: '/x.jpg', release_date: '2024-05-01', vote_average: 7.2, popularity: 50.3, genre_ids: [28]`) and a series item (`media_type: 'tv', name: 'Show', first_air_date: '2023-01-01'`). Assert: id → `tmdb:123`, type → `movie`/`series`, poster → `https://image.tmdb.org/t/p/w500/x.jpg`, year → `'2024'`, imdbRating → `'7.2'`, popularity parsed. Also assert `Movie.fromTmdb` sets `addonBaseUrl: TmdbService.kSentinel`.
- [ ] **Step 2: Run test to verify it fails** — `flutter test test/tmdb_service_test.dart`; expect undefined errors.
- [ ] **Step 3: Implement** — `TmdbService`: private `_get(String path, {Map<String, String> query})` that returns parsed JSON or `null` on any failure (non-200, network error, missing key — never throws); a static `Map<String, List<Movie>>` cache keyed by path+page (clear via `clearCache()`); endpoint mapping for each `listId` (`/trending/movie/day|week`, `/movie/popular`, `/tv/popular`, `/movie/top_rated`, `/tv/top_rated`, `/movie/now_playing`, `/movie/upcoming`, `/discover/movie|tv?with_genres=<id>&sort_by=popularity.desc`), always with `language=en-US`; result mapping via `Movie.fromTmdb`. `catalogTitle` returns human titles ("Trending Today", "Popular Movies", …) used for section headers.
- [ ] **Step 4: Run test → pass; analyze; commit** — Commit: `feat(tmdb): core service with list endpoints and Movie mapping`.

### Task 3: TMDB search, details (external_ids + credits), find-by-IMDb, recommendations, season episodes

**Files:**
- Modify: `lib/services/metadata/tmdb_service.dart`
- Modify: `lib/models/movie/movie_detail.dart` (add `MovieDetail.fromTmdb` factory)
- Test: `test/tmdb_service_test.dart` (extend)

**Interfaces:**
- Produces: `TmdbService.searchMulti(String query, {int page = 1})` → `Future<List<Movie>>`; `TmdbService.fetchDetails(String type, String tmdbId)` → `Future<MovieDetail?>` (uses `append_to_response=external_ids,credits,videos,recommendations`); `TmdbService.resolveByImdb(String imdbId)` → `Future<({String type, String tmdbId})?>` via `/find/{imdb}?external_source=imdb_id`; `TmdbService.fetchRecommendations(String type, String tmdbId)` → `Future<List<Movie>>`; `TmdbService.fetchSeasonEpisodes(String tmdbId, int season)` → `Future<List<Video>>`; `MovieDetail.fromTmdb(Map json, String type)` with `id` = IMDb id (fallback `tmdb:<id>`), `tmdbId` = numeric id.

- [ ] **Step 1: Write failing tests** — details fixture (movie JSON with `external_ids.imdb_id: 'tt123'`, `credits.cast`, `credits.crew`, `videos.results`, `genres`, `overview`, `runtime`, `poster_path`, `backdrop_path`): assert `MovieDetail.id == 'tt123'`, cast/director names extracted, description = overview, `tmdbId == '123'`. A series fixture without `imdb_id`: assert `id == 'tmdb:456'` (no crash). Season fixture: assert episode count and first episode's season/episode numbers map into `Video`.
- [ ] **Step 2: Run to verify failure; Step 3: Implement** — all fetches reuse `_get` (null-safe); details maps `poster_path`→w500 poster, `backdrop_path`→original background, `logo` from `/images` skipped unless trivially available via `videos`/`images` append — omit logo if absent (field nullable). `searchMulti` maps `/search/multi` results with `media_type` filtering to movie/tv.
- [ ] **Step 4: Run tests → pass; analyze; commit** — Commit: `feat(tmdb): search, details with IMDb mapping, find, recommendations, episodes`.

### Task 4: Home sections via TMDB

**Files:**
- Modify: `lib/services/addon/addon_manager.dart` (`streamHomeSections`, lines ~350-460)
- Test: existing home behavior via `flutter analyze` + manual smoke; unit-test the section list mapping if `streamHomeSections` internals are pure enough — otherwise verify by fixture-level test of `TmdbService.fetchList` paging (already covered in Task 2).

**Interfaces:**
- Consumes: `TmdbService.fetchList`, `TmdbService.kSentinel`, `TmdbService.catalogTitle`, `TmdbService.isConfigured`.
- Produces: same `Stream<MovieSection>` signature; sections emitted progressively.

- [ ] **Step 1: Implement** — at the top of `streamHomeSections()`: if `TmdbService.isConfigured`, yield TMDB sections **as each resolves** (wrap each `fetchList` future, yield on completion — preserve the progressive `async*` behavior): Trending Today (`trending_day`), Trending This Week (`trending_week`), Popular Movies (`popular_movie`), Popular Series (`popular_series`), Top Rated Movies (`top_rated_movie`), Now Playing (`now_playing`), Upcoming (`upcoming`). Each section: `addonBaseUrl: TmdbService.kSentinel`, `catalog: AddonCatalog(type: <movie|series|mixed>, id: <listId>, name: title)`, empty list yields nothing (error isolation). When not configured → existing Cinemeta code path unchanged.
- [ ] **Step 2: Verify** — `flutter analyze` clean; run app on Windows, confirm Home shows TMDB-backed sections with correct posters/ratings, "See All" opens catalog (grid may show error until Task 6 — acceptable mid-branch state; note it in the commit).
- [ ] **Step 3: Commit** — Commit: `feat(home): TMDB-backed home sections with Cinemeta fallback`.

### Task 5: Search page — TMDB multi-search

**Files:**
- Modify: `lib/pages/search/search_page.dart` (search flow, ~lines 250-300)

**Interfaces:**
- Consumes: `TmdbService.searchMulti`, `TmdbService.kSentinel`.

- [ ] **Step 1: Implement** — in `_performSearch`, when `TmdbService.isConfigured`: replace the `AddonManager.searchAll` section with a TMDB section built from `searchMulti(query)` (movies + series merged; build two sections "Movies" / "Series" if the page groups by type, matching the existing section style used for addon results). Keep the CloudStream search sections (stream sources). When not configured → existing addon search path.
- [ ] **Step 2: Verify** — analyze clean; smoke: search "fight club" shows TMDB results with posters; tapping a result opens details via Task 7 routing.
- [ ] **Step 3: Commit** — Commit: `feat(search): TMDB multi-search replaces addon metadata search`.

### Task 6: Discover + Catalog (See All) via TMDB

**Files:**
- Modify: `lib/pages/discover/discover_page.dart`
- Modify: `lib/pages/catalog/catalog_page.dart`
- Modify: `lib/services/metadata/tmdb_service.dart` (add `fetchGenres(String type)` if missing — `/genre/movie/list`, `/genre/tv/list`)

**Interfaces:**
- Consumes: `TmdbService.fetchList` paging, `TmdbService.kSentinel`, `Movie.fromTmdb` id format.
- Produces: `TmdbService.fetchGenres(String type)` → `Future<List<({int id, String name})>>`.

- [ ] **Step 1: Implement Discover** — when `TmdbService.isConfigured`, replace the addon-catalog chips/grid source: default catalog = popular movies/series browsing, genre chips from `fetchGenres`; grid items via `TmdbService.fetchList('genre_movie_<id>', page:)`. Genre/movie sections carry `addonBaseUrl: kSentinel` so the grid fetch router knows the source. Fallback unchanged when unconfigured.
- [ ] **Step 2: Implement Catalog page router** — in `CatalogPage`'s load method: if `widget.section.addonBaseUrl == TmdbService.kSentinel` → `TmdbService.fetchList(widget.section.catalog.id, page: (_items.length / 40).floor() + 1)`, dedupe by `movie.id` before appending, `_hasMore = false` when page returns empty; else legacy `MetadataService.fetchCatalog`.
- [ ] **Step 3: Verify** — analyze clean; smoke: Discover shows TMDB genres/grid; Home "See All" pages correctly; second page loads without duplicates.
- [ ] **Step 4: Commit** — Commit: `feat(discover): TMDB browsing for discover and See All catalogs`.

### Task 7: Details page — TMDB details + recommendations routing

**Files:**
- Modify: `lib/pages/details/details_page.dart` (meta fetch flow ~lines 300-350, `_fetchSimilarContent`, episode/season loading)

**Interfaces:**
- Consumes: `TmdbService.fetchDetails`, `TmdbService.fetchRecommendations`, `TmdbService.fetchSeasonEpisodes`, `TmdbService.resolveByImdb` (Task 3).

- [ ] **Step 1: Implement routing** — in the meta load flow: if `effectiveId.startsWith('tmdb:')` → `TmdbService.fetchDetails(effectiveType, numericId)`; episodes for series via `fetchSeasonEpisodes`; `_fetchSimilarContent` → `TmdbService.fetchRecommendations`. Legacy ids (`tt…`, addon ids, bestsimilar) keep the existing Cinemeta path — old persisted history items must keep resolving.
- [ ] **Step 2: Preserve scraping** — after TMDB details, `_detail.id` is the IMDb id (Task 3 guarantee), so existing `imdbId: _detail!.id.startsWith('tt')` scraping calls work unchanged. If `id` is `tmdb:` (no IMDb available), scraping is skipped exactly like today.
- [ ] **Step 3: Verify** — analyze clean; smoke: open a TMDB movie → cast/description/seasons render, stream sources resolve, related grid shows recommendations; open an old Continue Watching item (IMDb id) → still resolves via legacy path.
- [ ] **Step 4: Commit** — Commit: `feat(details): TMDB details, seasons, and recommendations with IMDb scraping bridge`.

### Task 8: My List / Continue Watching recommendations

**Files:**
- Modify: `lib/pages/home/home_page.dart` (BestSimilar-backed "Because you have…" sections) and/or `lib/services/metadata/bestsimilar_scraper.dart` call sites — locate via `grep -rn "BestSimilar\|bestsimilar" lib/pages lib/services` first.

**Interfaces:**
- Consumes: `TmdbService.resolveByImdb`, `TmdbService.fetchRecommendations`, `TmdbService.isConfigured`.

- [ ] **Step 1: Implement** — when configured, replace the BestSimilar section: take the first My List (and first Continue Watching) item, resolve to TMDB (items with `tmdb:` id skip resolution; `tt…` via `resolveByImdb`; unresolved → section skipped), fetch recommendations, emit as the existing "Because you have X" section shape. Unconfigured → BestSimilar path unchanged.
- [ ] **Step 2: Verify** — analyze clean; smoke with ≥1 My List item.
- [ ] **Step 3: Commit** — Commit: `feat(home): TMDB recommendations replace BestSimilar sections`.

### Task 9: Cleanup, attribution, final verification

**Files:**
- Modify: `lib/pages/settings/about_settings_page.dart` (TMDB attribution line)
- Modify: `lib/pages/settings/settings_page.dart` ONLY if it lists metadata-related copy that no longer applies.
- Possibly delete: now-dead addon-catalog browsing helpers in `addon_manager.dart` (`getAvailableDiscoverCatalogs`, `searchAll` metadata usage) — only if analyze confirms no remaining references.

- [ ] **Step 1: Add TMDB attribution** — one line in the About page credits: "This product uses the TMDB API but is not endorsed or certified by TMDB." (TMDB terms requirement).
- [ ] **Step 2: Full verification** — `flutter analyze` (zero errors/warnings, ≤33 infos); `flutter test` full suite compared to the known baseline (network scraper tests fail as baseline; nothing new fails); create `.env` locally with the placeholder only (do NOT commit) and confirm the app boots with fallback metadata; smoke-run `flutter run -d windows` checking Home, Discover, Search, Details, and an old Continue Watching item.
- [ ] **Step 3: Commit** — Commit: `feat(tmdb): final cleanup and attribution`.
