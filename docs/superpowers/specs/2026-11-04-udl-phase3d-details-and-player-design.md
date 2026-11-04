# UDL Phase 3d — Details Page + Player Design

**Status:** awaiting approval. No code until this is signed off.

**Trigger:** both surfaces still run on private palettes, so they ignore the
active theme. Reported as "the UDL does not apply to details page nor to the
player".

**Decisions already taken by the user (2026-11-04):**

1. **Two phases.** Details page first (this document, 3d-a), player second
   (3d-b) with its own plan.
2. **Player colour policy is hybrid.** Panels/menus/dialogs adopt the palette;
   over-video chrome (transport, seek bar, skip, volume/brightness HUDs) stays
   neutral white-on-scrim so it never fights the picture.

---

## 1. What "UDL applies" means here

The UDL contract that phases 1–3c established:

- Colours resolve through `PlayTorrioTokens.of(context)` (palette-driven) or a
  documented fixed layer (`AppSemanticColors`, `AppGlassColors`,
  `AppSponsorColors`, `AppSettingsColors`, `AppElevation`).
- No colour literal at a call site; `test/udl/no_inline_colors_test.dart` is the
  enforcement, per file, in `migratedFiles`.
- Surfaces work with glass disabled (§6.8).
- The phase-3c precedent is **colour-only**: no re-spacing, no type-scale
  changes, no behaviour changes, primitives adopted only where the control is
  already one of the shared ones.

This phase follows that precedent exactly.

## 2. Inventory (measured 2026-11-04)

| Surface | Files | Lines | `Color(0x…)` | `Colors.*` | Token use |
|---|---|---|---|---|---|
| Details page | 1 | 2,240 | 19 | 70 | 0 |
| Player | 18 | 11,924 | 174 | 224 | 0 |

Details page private palette: `_Palette.bg #0B0D12`, `surface #15171F`,
`accent #E50914` (Netflix red), `accentDim #9A0710`, `gold #FFC107`, plus six
cast-avatar gradient pairs.

Visible symptoms today:

- Play CTA, My List, rating stars and scroll arrows are red on every theme
  (emerald, amber, sapphire…).
- The My List button is hardcoded **purple** (`#7C5CFF`) while the Play CTA is
  red — two different accents in the same action row.
- The player's panels are purple (`PlayerTheme.accent #7C5CFF`) regardless of
  theme, and its HUDs add cyan/orange/amber literals on top.
- Neither file is in the guard, which is why they never migrated.

## 3. Phase 3d-a — Details page

### 3.1 Delete `_Palette`, read tokens once

`_Palette` is removed. `build()` reads `final tokens = PlayTorrioTokens.of(context)`
and passes it down to the helpers that need colour (`_buildHero`,
`_buildBackdrop`, `_buildMetadataRow`, `_buildActionRow`, `_buildCastRow`,
`_buildSeasonTabs`, `_buildEpisodeSlider`, `_buildRelatedRow`,
`_buildSimilarRow`, `_buildScrollArrow`, `_buildPosterCard`).

### 3.2 Colour mapping

| Today | Becomes | Why |
|---|---|---|
| `_Palette.bg` | `tokens.bgPrimary` | page background follows the palette |
| `_Palette.surface` | `tokens.surface` | poster placeholders, cards |
| `_Palette.accent` | `tokens.accent` | Play CTA, stars row, badges, arrows, spinner |
| `_Palette.accentDim` | `Color.alphaBlend(tokens.bgPrimary.withValues(alpha: 0.45), tokens.accent)` | gradient tail without a literal |
| `_Palette.gold` | `AppSemanticColors.rating` | fixed meaning, existing token |
| `#7C5CFF` (My List) | `tokens.accent` | kills the purple/red mismatch |
| `Colors.white` (text/icons) | `tokens.textPrimary` | |
| `Colors.white70`, `white54` | `tokens.textSecondary` | body copy, metadata |
| `Colors.white38`, `white30`, `white24` | `tokens.textTertiary` | disabled/de-emphasised |
| `Colors.white.withOpacity(0.04–0.10)` fills | `tokens.surfaceElevated` / `tokens.borderSubtle` | chips, tabs, hover fills |
| `Colors.white.withOpacity(0.12–0.25)` borders | `tokens.borderSubtle` / `tokens.borderStrong` | |
| `Colors.black.withOpacity(…)`, `Colors.black45` (scrims/shadows) | `tokens.bgPrimary.withValues(alpha: …)` | same pattern `movie_card.dart` already uses |
| `Colors.black` (gradient fade masks behind rows) | `tokens.bgPrimary` | masks must fade to the page colour, not to black |
| `Colors.black` as text on white/accent | `tokens.onAccent` / `tokens.onSurface` | correct contrast on amber/pink palettes |
| `#1B1E27` poster placeholder | `tokens.surfaceElevated` | |
| `#991A1D26` / `#661A1D26` band scrims | `tokens.bgPrimary.withValues(alpha: 0.60 / 0.40)` | band fades to the page colour |
| `Colors.black` for the "Pure Black" background mode | `AppOverlayColors.pureBlack` | see 3.3 |

### 3.3 Two new fixed layers

Both follow the existing `abstract final class` + doc-comment pattern.

**`lib/theme/app_avatar_colors.dart`**

```dart
/// Fixed gradients for name-derived cast avatars.
///
/// Decorative, not semantic: the point is that two people side by side look
/// different, which a palette-derived gradient cannot do. Chosen by name hash,
/// so they must stay stable across themes.
abstract final class AppAvatarColors {
  static const List<List<Color>> gradients = [ … six existing pairs, verbatim … ];
}
```

**`lib/theme/app_overlay_colors.dart`**

```dart
/// Fixed colours for overlays that sit on artwork rather than on an app
/// surface, and for the user-selected "Pure Black" background.
abstract final class AppOverlayColors {
  /// DetailsBackground.black — a user choice, not a palette value.
  static const pureBlack = Color(0xFF000000);
}
```

Nothing else moves into it: image scrims use `tokens.bgPrimary` so they fade
into whatever the page background is.

### 3.4 One primitive adoption

`_buildError()` (broken-image icon + text + raw `ElevatedButton`) is replaced by
the shared `AppErrorState` with title "Details unavailable." and the existing
retry callback. Same behaviour, one fewer bespoke control, and it is already
token-correct.

Everything else stays bespoke for now — see 3.5.

### 3.5 Explicitly out of scope (and why)

- **`_Space` → `AppSpacing`.** The ladders differ (8/12/16/24/32/48 vs
  4/8/12/16/20/24/32/40); mapping them re-spaces the page. That is a layout
  pass, not a colour pass, and phase 3c deliberately excluded it.
- **Type scale.** The page uses raw `TextStyle(fontSize: …)` in ~30 places.
  Moving to `AppTypography` changes sizes and weights. Separate pass.
- **Adopting `SectionHeader` / `AppButton` / `AppChip` for the bespoke
  controls.** The Play CTA is a gradient pill, the season tabs are a custom
  tab strip, the section headers use a 20 px bold style that `SectionHeader`
  does not have. Swapping them changes the look; not in a colour migration.
- **Layout, glass, animation, behaviour.** Untouched. The hero band, the
  sources flow, the episode slider and every callback stay as they are.
- **Opaque background.** The details page keeps its own opaque backdrop; it
  does not become transparent over `AnimatedAmbientBackground`. That is
  deliberate — it owns the image — and the `DetailsBackground` setting still
  drives it (Cinematic = hero band, Dark = `tokens.bgPrimary`, Pure Black =
  `AppOverlayColors.pureBlack`).

### 3.6 Enforcement and gates

1. `lib/pages/details/details_page.dart` is appended to `migratedFiles`; the
   guard must list its ~89 offenders first (that RED is the test).
2. Migrate until the guard is green, with `flutter analyze` unchanged at
   **33 issues (0 errors / 0 warnings)**.
3. Full `flutter test`: the documented baseline failures must be the *same
   tests*, not merely the same count.
4. `flutter build apk --debug` succeeds; visual check on at least three
   palettes (Emerald Aurora, Golden Amber, Sunset Crimson) because the accent
   now changes.
5. No `dart format` on this file — it produces ~900 lines of unrelated churn.

### 3.7 Risks

- **Contrast on light accents.** Golden Amber (`#F59E0B`) behind white text is
  weak. Using `tokens.onAccent` (luminance-derived) for text/icons on accent
  surfaces fixes it rather than making it worse; this is a real bug fix, not
  just a recolour.
- **Red → theme accent is a visible identity change.** The Play CTA stops
  being Netflix red unless the palette is Vampire Red. That is the point of
  the migration, but it is the one change the user should expect to notice.
- **`Colors.black` in the "Pure Black" mode** needs the new fixed entry;
  without it the guard would fail or the mode would silently become
  `bgPrimary`.

---

## 4. Phase 3d-b — Player (outline only, planned after 3d-a ships)

**Policy:** hybrid.

- **Panels/menus/dialogs** — sources, episodes, quality, audio, subtitles,
  speed, aspect, sub-style, `PlayerGlassCard` — resolve surfaces, text, borders
  and selection from `PlayTorrioTokens`. Selection accent becomes
  `tokens.accent` instead of `PlayerTheme.accent` (`#7C5CFF`).
- **Over-video chrome** — transport, seek bar, skip button, top bar over video,
  volume/brightness/seek HUDs — keeps a fixed neutral layer
  (`PlayerOverlayColors`: ink, muted ink, scrim, edge), documented like
  `AppGlassColors`. No palette accent here.
- **Status HUDs** — volume boost orange/red, brightness cyan/amber — move to
  the fixed layer with their meaning documented (they are state, not theme).
- `PlayerTheme` is split into `PlayerPanelTheme` (built from tokens, not
  const) and `PlayerOverlayColors` (fixed const). Every one of the 18 files is
  appended to the guard in its own task, RED first.
- No behaviour changes: playback, source ranking, gestures, and the panel's
  cache-following logic stay byte-for-byte identical.

Expected shape: ~10–14 tasks, one file (or one tightly coupled group) per
commit, same gates as 3d-a plus an on-device check that the panel still follows
`PlaybackSourceCache.revision`.

---

## 5. Acceptance for 3d-a

- [ ] `details_page.dart` in the guard, 0 offenders.
- [ ] `_Palette` deleted; no private palette left in the file.
- [ ] Play CTA, My List, stars, tabs, arrows, badges all follow the palette.
- [ ] My List and Play no longer disagree on accent.
- [ ] Pure Black mode still renders true black.
- [ ] Guard 2/2, analyze 33/0/0, test baseline identical, APK builds.
- [ ] Checked on three palettes with glass both on and off.
