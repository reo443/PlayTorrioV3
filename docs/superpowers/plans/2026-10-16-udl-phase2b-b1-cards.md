# UDL Phase 2b-B1 — The Four Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take the four poster cards off hardcoded colours — `movie_card`, `anime_card`, `manga_card`, `iptv_channel_card` — adopt `AppBadge` where a badge is already a neutral surface with a semantic colour, and delete `manga_card`'s shadowing duplicate `MissingPoster`.

**Architecture:** The card *chrome* (hover scale/translate, vignette, glow, play reveal) stays custom — no phase-2a primitive expresses it, and the design doc's component list has no poster-frame component. What changes is the colour source: every literal becomes a token, and every badge that is already "neutral surface + semantic colour" becomes `AppBadge`. Public APIs are frozen.

**Tech Stack:** Flutter 3.x / Dart 3.11, `flutter_test`. No new packages. Tests reuse `test/widgets_ui/host.dart`.

---

## Global Constraints

- **Public APIs frozen.** `MovieCardSizing`, `MovieCard`, `AnimeCard`, `MangaCardSizing`, `MangaCard`, `IptvChannelCard` keep every parameter. Note `MangaCard`'s local `MissingPoster` is *not* part of the API surface (nothing imports `manga_card.dart` for it — verified: no consumer names it).
- **`flutter analyze` stays at 33 issues / 0 warnings.**
- **Zero failures under `test/udl` and `test/widgets_ui`.**
- **No inline colour literals** in the four files — Task 5 extends the existing guard.
- Cards must stay correct with glass disabled and must not paint an opaque full-screen background.

## Two deliberate non-adoptions (recorded, not silent)

1. **`PosterImage` is not adopted by the cards.** The frames are `Stack(fit: StackFit.expand)` children of an `Expanded`, sized by `*CardSizing` — not by an aspect ratio — and they pass `filterQuality: FilterQuality.medium`, which `PosterImage` cannot express. Adopting it would change poster rendering for no functional gain. The frames already share `PosterSkeleton`/`MissingPoster` (token-based since plan A), which was the real duplication.
2. **Filled accent pills are not converted to `AppBadge`.** `AppBadge` renders a neutral surface with a coloured label; the movie/manga content-type badge, the anime format pill and the IPTV LIVE/category tags are *filled* pills. Converting them would restyle every poster in the app, so they stay custom but take their colour from `tokens`.

## Colour substitution rules (applied to all four files)

| Today | Becomes |
|---|---|
| `Color(0xFF171A23)` (poster background fill) | `tokens.surfaceElevated` |
| `Color(0xFF11131B)` (play glyph) | `tokens.surface` |
| `Color(0xFF232533)` (manga's own fallback) | *deleted with the class* |
| `Color(0xE6080A0F)` (rating pill) | *replaced by `AppBadge`* |
| `Color(0xFF0D1017)` (IPTV gradient base) | `tokens.bgSecondary` |
| `Color(0xFFFFD700)` / `Color(0xFFFF9E45)` (score/popularity) | `AppBadgeTone.rating` / `AppBadgeTone.warning` |
| `Color(0xFFFF3B30)` (IPTV LIVE) | `AppSemanticColors.error` |
| `palette.primaryColor` / `palette.accentColor` | `tokens.accent` / `tokens.accentSecondary` |
| `Colors.white` on a pill over accent | `tokens.onAccent` |
| `Colors.white` title / `Colors.white70` | `tokens.textPrimary` / `tokens.textSecondary` |
| `Colors.white.withOpacity(0.92)` | `tokens.textPrimary.withValues(alpha: 0.92)` |
| `Colors.white.withOpacity(0.52 … 0.62)` (secondary text) | `tokens.textSecondary` |
| `Colors.white.withOpacity(0.26 … 0.42)` (tertiary text) | `tokens.textTertiary` |
| `Colors.white.withOpacity(0.95)` (play circle) | `tokens.textPrimary` |
| `Colors.white.withOpacity(0.08)` (resting border) | `tokens.borderSubtle` |
| `Colors.white.withOpacity(0.12 … 0.20)` (border/overlay) | `tokens.borderStrong` |
| `Colors.white.withOpacity(0.11)` (hover gradient top) | `tokens.textPrimary.withValues(alpha: 0.11)` |
| `Colors.black.withOpacity(x)` (shadow / vignette / scrim) | `tokens.bgPrimary.withValues(alpha: x)` |
| `AppThemeService.currentPalette.value` | `PlayTorrioTokens.of(context)` (then drop the now-unused import) |

**Shadows stay bespoke in magnitude.** `AppElevation.shadowSm/Md` are far softer than the cards' dramatic depth (0.60 black, 32px blur); adopting them would visibly flatten every poster. Only the shadow *colour* moves to a token.

## File Structure

| File | Action |
|---|---|
| `lib/widgets/movie/movie_card.dart` | modify (colours + rating badge → `AppBadge`) |
| `lib/widgets/anime/anime_card.dart` | modify (colours + score/popularity/EPS badges → `AppBadge`) |
| `lib/widgets/manga/manga_card.dart` | modify (colours, delete local `MissingPoster`, drop `palette` param) |
| `lib/widgets/iptv/iptv_channel_card.dart` | modify (colours only) |
| `test/udl/movie_card_test.dart` | create |
| `test/udl/anime_card_test.dart` | create |
| `test/udl/manga_card_test.dart` | create |
| `test/udl/iptv_channel_card_test.dart` | create |
| `test/udl/no_inline_colors_test.dart` | modify (add the four paths) |

Cards use `Expanded` inside a `Column`, so every test wraps them in a bounded box:
`SizedBox(width: 150, height: 288, child: card)`.

---

### Task 1: `MovieCard`

**Files:** Modify `lib/widgets/movie/movie_card.dart`; Test `test/udl/movie_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/movie_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/movie/movie.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/movie/movie_card.dart';
import 'package:playtorrio/widgets/ui/app_chip.dart';

import '../widgets_ui/host.dart';

Movie _movie({String? poster}) => Movie(
  id: 'tt1',
  name: 'Dune',
  poster: poster,
  year: '2021',
  type: 'movie',
  addonBaseUrl: '',
  imdbRating: '8.0',
);

Widget _card(Movie movie, {VoidCallback? onTap}) => SizedBox(
  width: 150,
  height: 288,
  child: MovieCard(movie: movie, onTap: onTap),
);

Color? _posterFill(WidgetTester tester) => tester
    .widget<ColoredBox>(find.descendant(
      of: find.byType(MovieCard),
      matching: find.byType(ColoredBox),
    ).first)
    .color;

void main() {
  testWidgets('poster background fill uses the token surface', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_card(_movie())));

    expect(_posterFill(tester), tokens.surfaceElevated);
  });

  testWidgets('poster fill follows the selected palette', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(host(_card(_movie()), palette: last));

    expect(_posterFill(tester), PlayTorrioTokens.fromPalette(last).surfaceElevated);
    expect(
      _posterFill(tester),
      isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).surfaceElevated),
    );
  });

  testWidgets('rating is shown through the shared AppBadge', (tester) async {
    await tester.pumpWidget(host(_card(_movie())));

    final badge = tester.widget<AppBadge>(find.byType(AppBadge));
    expect(badge.tone, AppBadgeTone.rating);
    // The existing formatter drops the decimal for whole scores.
    expect(badge.label, '8');
  });

  testWidgets('tap fires the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_card(_movie(), onTap: () => taps++)));

    await tester.tap(find.byType(MovieCard));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('a missing poster falls back without throwing', (tester) async {
    await tester.pumpWidget(host(_card(_movie())));

    expect(tester.takeException(), isNull);
    expect(find.text('Dune'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/udl/movie_card_test.dart` → FAIL: fill is `0xFF171A23` and no `AppBadge` exists.

- [ ] **Step 3: Apply the substitution rules to `movie_card.dart`** — the rating pill block becomes:

```dart
            // Rating badge (top-right)
            if (imdbRating != null && imdbRating!.isNotEmpty)
              ValueListenableBuilder<bool>(
                valueListenable: HomePageSettings.showRating,
                builder: (context, showRating, _) {
                  if (!showRating) return const SizedBox.shrink();
                  final parsed = double.tryParse(imdbRating!);
                  final displayRating = parsed != null
                      ? (parsed % 1 == 0
                            ? parsed.toInt().toString()
                            : parsed.toStringAsFixed(1))
                      : imdbRating!;
                  return Positioned(
                    right: 9,
                    top: 9,
                    child: AppBadge(
                      label: displayRating,
                      tone: AppBadgeTone.rating,
                      icon: Icons.star_rounded,
                    ),
                  );
                },
              ),
```

and add to the imports: `import '../ui/app_chip.dart';`, `import '../../theme/playtorrio_tokens.dart';`; remove `import '../../services/theme/app_theme_service.dart';` once `palette` is gone. In `_PosterFrame.build`, replace `final palette = AppThemeService.currentPalette.value;` with `final tokens = PlayTorrioTokens.of(context);`.

- [ ] **Step 4: Run to verify it passes** — `flutter test test/udl/movie_card_test.dart` → PASS (5/5).

- [ ] **Step 5: Commit** — `git commit -m "refactor(udl): drive MovieCard from tokens and AppBadge"`

---

### Task 2: `AnimeCard`

**Files:** Modify `lib/widgets/anime/anime_card.dart`; Test `test/udl/anime_card_test.dart`

Adopts `AppBadge` for the score badge, the popularity badge and the EPS badge (all three are already dark-surface + coloured content).

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/anime_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/anime/anime_media.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/anime/anime_card.dart';
import 'package:playtorrio/widgets/ui/app_chip.dart';

import '../widgets_ui/host.dart';

AnimeMedia _anime({int score = 87, int popularity = 0}) => AnimeMedia(
  id: 1,
  titleRomaji: 'Cowboy Bebop',
  format: 'TV',
  totalEpisodes: 26,
  averageScore: score,
  popularity: popularity,
  seasonYear: 1998,
  genres: const ['Action'],
);

Widget _card(AnimeMedia anime) => SizedBox(
  width: 150,
  height: 288,
  child: AnimeCard(anime: anime, onTap: () {}),
);

void main() {
  testWidgets('score is shown through the shared rating badge', (tester) async {
    await tester.pumpWidget(host(_card(_anime())));

    final badge = tester.widget<AppBadge>(find.byType(AppBadge).first);
    expect(badge.tone, AppBadgeTone.rating);
  });

  testWidgets('popularity falls back to the warning badge', (tester) async {
    await tester.pumpWidget(host(_card(_anime(score: 0, popularity: 4200))));

    final badge = tester.widget<AppBadge>(find.byType(AppBadge).first);
    expect(badge.tone, AppBadgeTone.warning);
  });

  testWidgets('episode count uses the neutral badge', (tester) async {
    await tester.pumpWidget(host(_card(_anime())));

    final eps = tester
        .widgetList<AppBadge>(find.byType(AppBadge))
        .firstWhere((b) => b.label.endsWith('EPS'));
    expect(eps.tone, AppBadgeTone.neutral);
  });

  testWidgets('format pill follows the palette accent', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(host(_card(_anime()), palette: last));

    final pill = tester.widget<Container>(
      find.ancestor(of: find.text('TV'), matching: find.byType(Container)).first,
    );
    final decoration = pill.decoration! as BoxDecoration;
    expect(decoration.color, PlayTorrioTokens.fromPalette(last).accent.withValues(alpha: 0.90));
  });

  testWidgets('tap fires the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(SizedBox(width: 150, height: 288, child: AnimeCard(anime: _anime(), onTap: () => taps++))),
    );

    await tester.tap(find.byType(AnimeCard));
    await tester.pump();

    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/udl/anime_card_test.dart` → FAIL: no `AppBadge`.

- [ ] **Step 3: Apply the substitution rules to `anime_card.dart`** — `_buildCornerBadge` is deleted; the two call sites become `AppBadge(label: anime.formattedScore, tone: AppBadgeTone.rating, icon: Icons.star_rounded)` and `AppBadge(label: anime.formattedPopularity, tone: AppBadgeTone.warning, icon: Icons.local_fire_department_rounded)`, each still wrapped in its `Positioned(top: 9, left: 9, child: …)`. The EPS container becomes `Positioned(bottom: 9, left: 9, child: AppBadge(label: '${anime.totalEpisodes} EPS'))`. Add `import '../ui/app_chip.dart';` and `import '../../theme/playtorrio_tokens.dart';`; drop the `AppThemeService` import once unused.

- [ ] **Step 4: Run to verify it passes** — PASS (5/5).

- [ ] **Step 5: Commit** — `git commit -m "refactor(udl): drive AnimeCard from tokens and AppBadge"`

---

### Task 3: `MangaCard`

**Files:** Modify `lib/widgets/manga/manga_card.dart`; Test `test/udl/manga_card_test.dart`

Deletes the local `MissingPoster` (line 402) so the shared, token-based one is used, and drops the now-unneeded `palette` parameter from the private `_PosterFrame`.

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/manga_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/manga/manga.dart';
import 'package:playtorrio/widgets/common/poster_skeleton.dart';
import 'package:playtorrio/widgets/manga/manga_card.dart';

import '../widgets_ui/host.dart';

Manga _manga({String cover = ''}) => Manga(
  id: '1',
  title: 'Berserk',
  coverSmall: cover,
  coverNormal: cover,
  type: 'manga',
  year: '1989',
  tags: const ['Action'],
);

Widget _card(Manga manga) => SizedBox(
  width: 150,
  height: 288,
  child: MangaCard(manga: manga),
);

void main() {
  testWidgets('missing cover uses the shared poster fallback', (tester) async {
    await tester.pumpWidget(host(_card(_manga())));

    // The shared fallback draws a movie glyph; manga's deleted local copy drew
    // a broken-image glyph, so this pins which class actually rendered.
    expect(
      find.descendant(
        of: find.byType(MissingPoster),
        matching: find.byIcon(Icons.movie_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.broken_image_rounded), findsNothing);
  });

  testWidgets('renders the title and meta line', (tester) async {
    await tester.pumpWidget(host(_card(_manga())));

    expect(find.text('Berserk'), findsOneWidget);
    expect(find.textContaining('1989'), findsOneWidget);
  });

  testWidgets('a cover URL still renders without throwing', (tester) async {
    await tester.pumpWidget(host(_card(_manga(cover: 'https://example.invalid/a.jpg'))));

    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/udl/manga_card_test.dart` → FAIL: `Icons.broken_image_rounded` is found (the local class won).

- [ ] **Step 3: Delete the local `MissingPoster` and apply the substitution rules.** The `_PosterFrame` constructor loses `required this.palette` and its field; `_MangaCardState.build` loses `final palette = AppThemeService.currentPalette.value;` and the `palette: palette,` argument; the `AppThemeService` import goes.

- [ ] **Step 4: Run to verify it passes** — PASS (3/3).

- [ ] **Step 5: Commit** — `git commit -m "refactor(udl): share the poster fallback and tokenise MangaCard"`

---

### Task 4: `IptvChannelCard`

**Files:** Modify `lib/widgets/iptv/iptv_channel_card.dart`; Test `test/udl/iptv_channel_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/iptv_channel_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/iptv/hardcoded_channels.dart';
import 'package:playtorrio/theme/app_semantic_colors.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/iptv/iptv_channel_card.dart';

import '../widgets_ui/host.dart';

Widget _card() => SizedBox(
  width: 150,
  height: 288,
  child: IptvChannelCard(channel: HardcodedChannels.all.first, onTap: () {}),
);

/// The LIVE pill is the only container whose decoration carries a border in
/// the error colour.
BoxDecoration? _livePill(WidgetTester tester) {
  for (final container in tester.widgetList<Container>(find.byType(Container))) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration &&
        decoration.border != null &&
        decoration.border!.top.color == AppSemanticColors.error.withValues(alpha: 0.6)) {
      return decoration;
    }
  }
  return null;
}

void main() {
  testWidgets('LIVE indicator uses the semantic error colour', (tester) async {
    await tester.pumpWidget(host(_card()));

    expect(_livePill(tester), isNotNull);
  });

  testWidgets('gradient ends on the token secondary background', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_card()));

    final decorated = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.gradient is LinearGradient &&
            (d.gradient! as LinearGradient).colors.length == 3);
    expect((decorated.gradient! as LinearGradient).colors.last, tokens.bgSecondary);
  });

  testWidgets('renders the channel name', (tester) async {
    await tester.pumpWidget(host(_card()));

    expect(find.text(HardcodedChannels.all.first.name), findsOneWidget);
  });
}
```

Note: this test imports `AppThemeService` for the palette — add
`import 'package:playtorrio/services/theme/app_theme_service.dart';`.

- [ ] **Step 2: Run to verify it fails** — FAIL: gradient base is `0xFF0D1017` and the LIVE border is `0xFFFF3B30`.

- [ ] **Step 3: Apply the substitution rules** — the LIVE dot/border become `AppSemanticColors.error`, the gradient base becomes `tokens.bgSecondary`, the palette fallbacks become `tokens.accent`/`tokens.accentSecondary`.

- [ ] **Step 4: Run to verify it passes** — PASS (3/3).

- [ ] **Step 5: Commit** — `git commit -m "refactor(udl): drive IptvChannelCard from tokens"`

---

### Task 5: Extend the colour guard

**Files:** Modify `test/udl/no_inline_colors_test.dart`

- [ ] **Step 1: Add the four paths** to `migratedFiles`, after the five from plan A:

```dart
  'lib/widgets/movie/movie_card.dart',
  'lib/widgets/anime/anime_card.dart',
  'lib/widgets/manga/manga_card.dart',
  'lib/widgets/iptv/iptv_channel_card.dart',
```

- [ ] **Step 2: Run** — `flutter test test/udl/no_inline_colors_test.dart` → PASS (2/2). Any `file:line` in the failure output is a literal Tasks 1-4 missed.

- [ ] **Step 3: Commit** — `git commit -m "test(udl): extend the inline-colour guard to the four cards"`

---

## Verification

- [ ] `flutter analyze` → 33 issues, all `info`, 0 warnings.
- [ ] `flutter test test/udl test/widgets_ui` → all pass.
- [ ] `flutter test` → failures unchanged from the pre-existing live-network set; none under `test/udl` or `test/widgets_ui`.
- [ ] `grep -rn "MissingPoster" lib/widgets/manga/manga_card.dart` → no local declaration remains.

## Self-Review

- **Spec coverage:** §13's "no hardcoded colors" is enforced mechanically by Task 5; §6.8 transparency is respected (cards are content-sized, never full-screen).
- **Type consistency:** `AppBadge`, `AppBadgeTone.{neutral,rating,warning}`, `PlayTorrioTokens.of`, `AppSemanticColors.error`, `tokens.surfaceElevated/bgSecondary/accent/accentSecondary/onAccent/textPrimary/textSecondary/textTertiary/borderSubtle/borderStrong` all exist as used.
- **Deferred:** the three `*CardSizing` classes remain three near-identical shapes — unifying them changes public APIs used by the sliders and pages, so it belongs in its own change, not a colour migration.
