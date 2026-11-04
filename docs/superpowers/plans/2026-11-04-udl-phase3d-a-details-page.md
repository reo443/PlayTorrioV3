# UDL Phase 3d-a — Details Page Implementation Plan

> **For the executor:** follow this plan task by task. Every task ends with a
> commit. Never start a task before the previous one is green.
>
> **No production code before this plan is approved.**

**Goal:** move `lib/pages/details/details_page.dart` off its private `_Palette`
and 89 inline colour literals onto the token layer, so the details page
recolours with the theme. Colour-only: no re-spacing, no type changes, no
behaviour changes.

**Design:** `docs/superpowers/specs/2026-11-04-udl-phase3d-details-and-player-design.md`

**Tech stack:** Flutter 3.47.6 / Dart 3.11, no new packages.

---

## Pre-flight

```powershell
flutter pub get
flutter analyze                       # expect 33 issues, 0 errors, 0 warnings
flutter test test/udl test/widgets_ui test/theme
```

Baseline that must not move:

- `flutter analyze` → **33 issues (0 errors / 0 warnings)**.
- `flutter test test/udl test/widgets_ui test/theme` → all pass.
- Full `flutter test` → the documented 13 failures in the same files, nothing
  new.

Constraints:

1. No new packages. New tokens only where this plan says so.
2. **Do not run `dart format` on `details_page.dart`** — it rewrites ~900 lines
   of unrelated code.
3. The hero band, the sources/auto-play flow, the episode slider, and every
   callback stay exactly as they are.
4. Work on `main`; commit per task; push only to `origin`, only on request.

---

## Task 1 — Add the two fixed layers

**Files:** `lib/theme/app_avatar_colors.dart` (new),
`lib/theme/app_overlay_colors.dart` (new).

1. `AppAvatarColors.gradients` — the six gradient pairs currently in
   `_Palette.avatarPairs`, verbatim, with the "decorative, name-hash selected,
   must stay stable across themes" doc comment.
2. `AppOverlayColors.pureBlack` — `Color(0xFF000000)`, documented as the
   user-selected `DetailsBackground.black` value, not a palette value.

**Verify:** `flutter analyze` still 33; `flutter test test/udl` green.

**Commit:** `Add fixed layers for cast avatars and pure-black overlays`

---

## Task 2 — Guard first, then migrate the page

**File:** `lib/pages/details/details_page.dart`,
`test/udl/no_inline_colors_test.dart`.

### 2.0 RED

Append `'lib/pages/details/details_page.dart'` to `migratedFiles` and run:

```powershell
flutter test test/udl/no_inline_colors_test.dart
```

It must fail listing this file's ~89 offenders. Do not touch the page before
you have seen that output.

### 2.1 Palette and page shell

- Delete `class _Palette` (keep `_Space`).
- In `build()`, read `final tokens = PlayTorrioTokens.of(context);` and pass it
  to the helpers that need colour.
- `Scaffold.backgroundColor`: `isBlackBg ? AppOverlayColors.pureBlack : tokens.bgPrimary`.
- Loading spinner: `tokens.accent`.
- Replace `_buildError()` with the shared `AppErrorState`
  (`title: 'Details unavailable.'`, existing retry callback). Delete the raw
  `ElevatedButton` and its `styleFrom` literals.

### 2.2 Hero and backdrop band

- Backdrop image alignment/fade unchanged; scrims become
  `tokens.bgPrimary.withValues(alpha: 0.60)` and `…0.40` in place of
  `#991A1D26` / `#661A1D26`.
- Top cap: `tokens.bgPrimary.withValues(alpha: 0.45)` in place of `Colors.black45`.
- Back button chip: fill `tokens.surface.withValues(alpha: 0.55)`, border
  `tokens.borderStrong`, icon `tokens.textPrimary`.
- Poster frame shadow: `tokens.bgPrimary.withValues(alpha: …)` plus
  `tokens.accent.withValues(alpha: 0.16)` glow (matches `movie_card.dart`).
- Poster error/placeholder fill: `tokens.surface`.
- Title logo shadow: `tokens.bgPrimary.withValues(alpha: 0.7)`.

### 2.3 Metadata row, rating, genres

- Year / runtime / genre text → `tokens.textPrimary` / `tokens.textSecondary`.
- Separator dots → `tokens.textTertiary`.
- Rating pill fill `tokens.surfaceElevated`, border `tokens.borderStrong`,
  value `tokens.textPrimary`.
- Star icon → `AppSemanticColors.rating`.
- Genre pills: fill `tokens.surfaceElevated`, border `tokens.borderSubtle`,
  label `tokens.textSecondary`.

### 2.4 Action row

- Play CTA gradient: `[tokens.accent, _accentDim(tokens)]` where
  `_accentDim(t) => Color.alphaBlend(t.bgPrimary.withValues(alpha: 0.45), t.accent)`.
- Play CTA label/icon: `tokens.onAccent` (not white — fixes contrast on light
  accents).
- Play CTA glow: `tokens.accent.withValues(alpha: 0.35)`.
- My List button: the three `#7C5CFF` literals → `tokens.accent`; its idle
  fill/border → `tokens.surfaceElevated` / `tokens.borderStrong`; idle
  icon/label → `tokens.textPrimary`.

### 2.5 Synopsis, section headers, cast row

- Synopsis text → `tokens.textSecondary`; "Read more"/"Show less" →
  `tokens.textPrimary`.
- Section header title → `tokens.textPrimary`.
- Cast avatar initials → `tokens.textPrimary` on the fixed gradient; avatar
  border → `tokens.borderSubtle`; cast name → `tokens.textSecondary`;
  character → `tokens.textTertiary`.

### 2.6 Season tabs, episodes, scroll arrows

- Season tab selected: fill `tokens.textPrimary`, label
  `tokens.surface`; idle: fill `tokens.surfaceElevated`, border
  `tokens.borderSubtle`, label `tokens.textPrimary`.
- Episode list edge masks (`Colors.black` stops) → `tokens.bgPrimary`.
- Scroll arrow chip: fill `tokens.bgPrimary.withValues(alpha: 0.6)`, border
  `tokens.borderStrong`, icon `tokens.textPrimary`.
- "Watched"/accent episode badge → `tokens.accent`.

### 2.7 Related / similar rows and poster cards

- Card fill `tokens.surface`, hover border `tokens.borderStrong`,
  shadow `tokens.bgPrimary.withValues(alpha: 0.4)`, placeholder
  `tokens.surfaceElevated`.
- Card gradient overlay → `tokens.bgPrimary.withValues(alpha: 0.75)`.
- Card title `tokens.textPrimary`, year `tokens.textSecondary`.
- Play glyph on the card: circle `tokens.textPrimary`, icon `tokens.surface`.

### 2.8 GREEN

```powershell
flutter test test/udl/no_inline_colors_test.dart   # 2/2, no offenders
flutter analyze                                    # 33 issues, 0/0
```

**Commit:** `Move the details page onto the theme tokens`

---

## Task 3 — Verify the real thing

1. `flutter test` → the same 13 baseline failures, nothing new.
2. `flutter build apk --debug` → succeeds.
3. Install and check on **Emerald Aurora, Golden Amber, Sunset Crimson**:
   Play CTA, My List, stars, season tabs, cast avatars, poster cards, and the
   backdrop band. Then repeat with glass effects off.
4. Confirm the sources flow still behaves (details → auto-pick → player) and
   the "Pure Black" background mode is still true black.

No code changes expected; if a check fails, fix and amend before moving on.

**Commit:** only if the verification produced changes; otherwise record the
result in the summary.

---

## Done when

- `details_page.dart` is in the guard with 0 offenders and `_Palette` is gone.
- Every accent on the page follows the active palette; My List and Play agree.
- Analyze 33/0/0, guard 2/2, test baseline unchanged, APK builds.
- Checked on three palettes, glass on and off.
