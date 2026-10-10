Instructions for AI coding agents (OpenCode and compatible tools) working on this
repository. Read this file fully before touching any code.

## Rule #1 — Ask, don't guess

**Never assume what the user means. If a request is ambiguous or incomplete, ask
clarifying questions before writing any code.**

- If a request can be interpreted in more than one way, list your questions and
  wait for answers. Do not silently pick an interpretation.
- Requests like "improve X", "fix the player", or "make it faster" are not specs.
  Ask what specifically is wrong, what the expected behavior is, and how the user
  will verify the result.
- When multiple implementation approaches exist, present them briefly (with
  trade-offs) and let the user choose.
- If a request conflicts with the existing architecture or with anything in this
  file, surface the conflict and ask how to proceed — don't improvise around it.
- If new ambiguity appears mid-task, stop and ask. Never keep building on an
  assumption.
- When finished, summarize what changed, which files were touched, and explicitly
  flag anything you were unsure about.

One clarifying question costs seconds. A wrong guess costs a rewrite.

## Project overview

PlayTorrio V3 is a Flutter media streaming app: movies & TV (45+ VOD scrapers,
torrent streaming via native libtorrent, Stremio addon support), anime (13
extractors), manga (WeebCentral reader), audiobooks (9-source aggregator), and
music (Octave API).

- **Framework:** Flutter 3.x / Dart 3.11+
- **Platforms:** Windows, macOS, Linux, Android, iOS (all fully supported)
- **License:** GPL-3.0

## Commands

```bash
flutter pub get            # install dependencies (always run first)
flutter analyze            # static analysis — must pass with zero warnings
flutter test               # test suite — must pass
flutter run                # run on a connected device/emulator
flutter run -d windows     # target a specific platform (macos, linux, android, ios)
```

## Project layout

```
lib/
├── main.dart                 # entry point
├── models/                   # data classes (movie, stream, subtitle, manga, audiobook, music)
├── services/
│   ├── addon/                # Stremio addon manager
│   ├── metadata/             # Stremio metadata client + recommendations
│   ├── stream/               # stream aggregation + torrent engine (stream_service.dart)
│   ├── scraper/              # StreamScraper base class + manager + 45+ implementations
│   │   └── sites/            # individual VOD scrapers
│   ├── anime/                # anime service + 13 extractors
│   ├── subtitles/            # subtitle service + providers (Subdl)
│   ├── manga/                # WeebCentral scraper + progress tracking
│   ├── audiobook/            # 9-source aggregator + progress service
│   └── music/                # Octave API client + library + player controller
├── pages/                    # UI screens
├── widgets/                  # reusable components (cards, dock, scroll track)
└── utils/                    # torrent filename parser, relevance scorer, route transitions
assets/scrapers/              # JS scrapers + sources.json registry
```

## Architecture rules

- **Plugin architecture.** Scrapers are independent and run concurrently. The
  stream manager already handles concurrency, timeouts, deduplication, and error
  isolation — never reimplement these inside a scraper.
- **Error isolation is non-negotiable.** A single failing scraper/provider must
  never crash the app or affect other sources. Wrap network and parsing code
  defensively and return empty results on failure.
- **Follow existing patterns.** Services are singletons; helpers are static
  utility classes. Match the surrounding code before introducing anything new.
- **Caching.** Reuse the existing LRU cache pattern for network responses.
- **Streaming flow.** Scraper results stream to the UI as they arrive; do not
  block on "all sources finished".
- **Cross-platform.** Changes must work on all five platforms; guard any
  platform-specific code.
- **UI.** The glassmorphism effects (`liquid_glass_easy`) have a settings toggle
  and performance fallback — UI changes must still work with effects disabled.
  Use the existing route transitions (`LiquidRevealRoute`,
  `CinematicSlideRoute`) where the app already does.
- **Persistence.** Watch history, manga reading position, and audiobook position
  persist via `SharedPreferences`.

## Code style

- Prefer `const` constructors where possible.
- Use `final` over `var` unless the variable is reassigned.
- Handle errors gracefully; never let an exception escape a scraper or provider
  boundary.
- Match existing naming and file organization conventions.

## How to add a VOD scraper

1. Create the file in `lib/services/scraper/sites/`, extending the `StreamScraper`
   abstract class:

   ```dart
   import '../stream_scraper.dart';
   import '../../../models/stream/stream_model.dart';

   class MyScraper extends StreamScraper {
     @override
     String get name => 'MyScraper';

     @override
     Future<List<StreamSource>> scrape({
       required String type,
       required String title,
       int? year,
       int? season,
       int? episode,
       String? imdbId,
     }) async {
       // scraping logic — return a List<StreamSource>
     }
   }
   ```

2. Register it in `lib/services/stream/stream_service.dart` inside
   `_registerScrapers()`.
3. Add the corresponding JS file in `assets/scrapers/` and an entry in
   `assets/scrapers/sources.json`.
4. Test it against a known-good title (a movie and an episode of a show) before
   reporting the task done.

## How to add a subtitle provider

1. Create the file in `lib/services/subtitles/providers/`, implementing the
   `SubtitleProvider` abstract class.
2. Register it in `lib/services/subtitles/subtitle_service.dart`.

## Security & legal

- **Never commit API keys, tokens, or secrets.** Use the `secrets.example.dart`
  pattern.
- The app hosts no content — everything comes from third-party sources. Do not
  add code that bundles, stores, or redistributes content.

## Definition of done

Before calling any task complete:

- [ ] `flutter analyze` — zero warnings
- [ ] `flutter test` — all tests pass
- [ ] New scrapers/providers verified against a real, known-good title
- [ ] No secrets, keys, or tokens in the diff
- [ ] Error isolation intact (a failing scraper cannot crash the app)
- [ ] Changes work on all target platforms (or are properly guarded)
- [ ] Any open questions or uncertainties explicitly flagged to the user
