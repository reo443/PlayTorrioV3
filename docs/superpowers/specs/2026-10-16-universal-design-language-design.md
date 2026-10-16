# Universal Design Language (UDL) — Design

Date: 2026-10-16
Status: Draft for approval
Scope: App-wide visual design system for PlayTorrio V3 (Flutter)

---

## 1. Intent and why

PlayTorrio V3 grew feature-by-feature across five media domains (movies/TV,
anime, manga/books, audiobooks, music) plus settings, player, IPTV, and
downloads. Styling is currently ad-hoc: colors, font sizes, radii, and spacing
are written inline on each screen. A quick census of `lib/`:

- ~2,085 hardcoded `Color(0x…)` literals
- ~1,294 `BorderRadius.circular(...)` calls
- ~1,643 inline `fontSize:` values
- 343 Dart files

The result is that superficially similar UI (posters, chips, section headers,
dialogs, empty states) drifts between screens. The goal is a single,
theme-driven design language that makes every screen feel like one premium,
cinematic product — without changing any feature, data, route, or business
logic.

The app already has the seed of this: `AppThemePalette` +
`AppThemeService` (8 selectable palettes) drives colors in ~60 files, and the
reader has a private `ReaderTokens` (spacing/radius/motion/type constants).
This project generalizes that pattern app-wide.

## 2. Goals

1. One centralized, theme-driven source of truth for color, typography,
   spacing, radii, elevation, and motion.
2. Every accent (navigation, selected tabs, save actions, focus, selection)
   follows the palette selected in Settings. No hardcoded accents anywhere.
3. Shared, reusable component library with documented variants; screens
   compose it instead of re-styling widgets locally.
4. Consistent navigation, cards, controls, dialogs/sheets, and
   loading/empty/error states app-wide.
5. Preserve the existing visual identity (dark cinematic, purple brand) and
   all behavior.
6. Easy to maintain and extend (future themes; possibly light theme later).

## 3. Non-goals

- No changes to data models, API/scraper logic, routing, or playback internals.
- No new features or workflows.
- No replacement of real data with mocks.
- Not a redesign of layouts or information architecture (structure stays;
  only styling/tokens are unified).
- Not removing working functionality to force uniformity.

## 4. Anti-goals (what would make this a failure even if it "works")

- A half-migrated app that looks *less* consistent than before (mixed old/new).
- Introducing hardcoded colors for "special" screens (re-introduces the
  problem).
- A heavy abstract framework that is harder to use than inline styles.
- Visual regressions: clipping, unreadable contrast, broken safe areas,
  stalled/duplicated interactions.
- Breaking the player, playback flow, or any domain's functionality.

## 5. Constraints and decisions already made (by the human partner)

- **Theme-driven, no hardcoded colors.** Every color comes from the palette
  chosen in Settings. The word "blue" in the original brief means "whatever
  the active palette's accent is"; there is no fixed blue.
- **Reuse existing architecture and dependencies.** No new packages; build on
  `AppThemePalette` / `AppThemeService`.
- **Incremental migration**, in this agreed order:
  1. Tokens + theme wiring
  2. Shared components
  3. Movie/TV core (home, discover, details, search, library)
  4. Anime + manga/books
  5. Audiobooks + music
  6. Settings, IPTV, player surfaces
- **Keep the system font decision as:** define a type scale; the app already
  bundles **Poppins** (Regular/Medium/SemiBold/Bold) and the reader uses it, so
  the app-wide UI font becomes Poppins.
- Produce a written design (this doc) → plan → implement.

## 6. The architecture

### 6.1 Color: extend the palette, expose semantic roles via a ThemeExtension

`AppThemePalette` remains the per-theme color source. It already declares
`primaryColor`, `accentColor`, `scaffoldBackgroundColor`,
`cardBackgroundColor`, `appBarBackgroundColor`.

Add two explicit per-theme colors so surfaces can layer correctly:

- `backgroundSecondaryColor` (subtly lighter than scaffold; grouped content)
- `surfaceElevatedColor` (modals/menus/dialogs/elevated panels)

Add these values for all 8 existing palettes (hand-authored, matching each
theme's hue).

Everything else is **derived once** in a `ThemeExtension` (`PlayTorrioTokens`)
constructed from the active palette, so the ~2,085 literals collapse to a
handful of semantic getters:

| Token | Source |
|---|---|
| `bgPrimary` | `palette.scaffoldBackgroundColor` |
| `bgSecondary` | `palette.backgroundSecondaryColor` (new) |
| `surface` | `palette.cardBackgroundColor` |
| `surfaceElevated` | `palette.surfaceElevatedColor` (new) |
| `surfaceSelected` | `surface` blended toward `primary` (tint) |
| `borderSubtle` | white @ ~6% |
| `borderStrong` | white @ ~12% |
| `textPrimary` | white @ ~95% |
| `textSecondary` | white @ ~62% |
| `textTertiary` | white @ ~42% |
| `accent` | `palette.primaryColor` |
| `accentSecondary` | `palette.accentColor` |
| `focusRing` | `accent` |
| `destructive` | `Color(0xFFE5484D)` (shared semantic) |
| `success` | `Color(0xFF30A46C)` (shared semantic) |
| `warning` | `Color(0xFFF5A623)` (shared semantic) |
| `error` | `destructive` |
| `onAccent` | computed: black or white, whichever contrasts best with `accent` (WCAG relative luminance) |
| `onSurface` | computed against `surface` the same way |

Status colors (success/warning/error) are shared constants because they carry
meaning and must stay legible regardless of theme; every other color is
theme-derived. `onAccent` is computed per palette from relative luminance so
filled controls stay readable on light-accent themes (`amber`, `barbie`,
`vampire`) rather than always forcing white text.

Rationale for hand-authoring only two new per-theme colors: the two surface
tiers genuinely vary per theme and cannot be derived blindly; the rest are
neutral overlays on the dark base, which the app already computes inline
(`Colors.white.withOpacity(0.52)` etc.). This keeps the derivation in one
place instead of authored 8×N.

### 6.2 Typography

A single `AppTypography` with named styles (all Poppins):

- `display` — 28 / w800 / -0.5 tracking (hero titles)
- `screenTitle` — 22 / w800
- `sectionHeading` — 17 / w700
- `cardTitle` — 15.5 / w700 (1-line ellipsis)
- `body` — 14 / w400 / h1.4
- `bodyStrong` — 14 / w600
- `supporting` — 13 / w400 (secondary text)
- `label` — 13 / w600 (buttons/form labels)
- `caption` / `metadata` — 12 / w500 (years, ratings, codecs)
- `badge` — 10 / w800 / +0.6 tracking (uppercase chips)

`TextStyle` gets font family from the font; color is applied by the token
layer (`textPrimary/Secondary/Tertiary`) at call sites, not baked into the
scale. All titles use `maxLines` + `TextOverflow.ellipsis` (no clipping).

### 6.3 Spacing

`AppSpacing`: `xs 4, sm 8, md 12, lg 16, xl 20, xxl 24, xxxl 32, huge 40`.
Page horizontal padding default = `lg (16)`; section vertical spacing = `xxl`;
card gaps = `md`. Screen-specific values must come from this scale.

### 6.4 Radii

`AppRadii`: `badge 8, chip 999 (pill), input 12, button 12, card 16,
poster 18, sheet 24`. Border width: subtle 1, emphasis 1.35.

### 6.5 Elevation and motion

`AppElevation`: `sm` (soft list card) and `md` (poster / floating) shadows,
plus a single `glow(accent)` used only for focus/selected emphasis. Effects
stay restrained.

`AppMotion`: `fast 120ms`, `standard 170ms`, `sheet 260ms`,
`themeSwitch 300ms` with named curves (`easeOut`, `easeOutCubic`,
`easeInOutCubic`). Same durations/curves as the reader tokens so motion feels
uniform.

### 6.6 Access model

`AppThemeService.createThemeData(palette)` builds a `ThemeExtension`
(`PlayTorrioTokens`) plus `TextTheme`/`AppBarTheme`/`CardTheme`. Because
`main.dart` already rebuilds `MaterialApp` inside a
`ValueListenableBuilder<AppThemePalette>`, changing the palette in Settings
re-themes everything live, including all tokens.

Consumers read tokens via `PlayTorrioTokens.of(context)` (ThemeExtension
lookup). Static spacers/type (spacing/radii/typography/motion) may also be
exposed as plain static classes for use where a `BuildContext` is awkward
(e.g. inside `const` lists), but **color always comes from the extension** so
it stays theme-reactive.

### 6.7 Naming conventions

- Tokens: `bgPrimary`, `surfaceElevated`, `textSecondary`, `accent`,
  `AppSpacing.lg`, `AppRadii.card`, `AppTypography.sectionHeading`.
- Components: `AppButton` (+ `variant`), `AppCard`, `AppChip`,
  `AppBadge`, `PosterImage`, `AppTextField`, `AppSheet`, `AppDialog`,
  `AppEmptyState`, `AppErrorState`, `SkeletonBox`.
- Variants: `primary | secondary | tertiary | destructive` for buttons;
  semantic types for chips/badges.

### 6.8 Compositing, glass, ColorScheme, and contrast (settled by the builder)

These were raised by an independent reviewer of this doc and are decided here:

- **Ambient background layer.** The real background is
  `AnimatedAmbientBackground` (base color + user wallpaper + theme tint +
  moving orbs), with screen content as a transparent child. Migrated screens
  **must stay transparent** over this layer — they must not paint an opaque
  `bgPrimary`. `bgPrimary` is the fallback base color (placeholders,
  non-ambient surfaces, areas outside the layer), not something screens fill.
- **Glass on/off.** Per `AGENTS.md`, UI must work with glass effects disabled
  (`GlassSettings.enabled` defaults to false, with a performance fallback).
  Components in `lib/widgets/ui/` are **flat, token-based by default**; glass
  is an optional decoration applied by the existing glass wrappers where a
  screen already uses them. A component must look correct and complete with
  effects off.
- **Material `ColorScheme`.** `createThemeData` currently uses
  `colorSchemeSeed: primaryColor`, which generates a derived scheme that does
  not match the hand-authored palette (two color sources = violates "one source
  of truth"). Replace the seed with an explicitly constructed `ColorScheme`
  whose `primary/secondary/surface/background/error` come from the palette and
  tokens, so built-in Material widgets (Switch, Slider, Dialog, BottomSheet,
  TextField, SnackBar, ProgressIndicator, ripple) agree with the design
  language.
- **Contrast.** `onAccent`/`onSurface` are computed by luminance (§6.1), so
  filled controls and selection states remain legible on every palette.
- **Reader.** The reader is a **specialized surface**: it keeps its own reading
  typography (type scale, justification) and the user-selectable reading font
  (`ReaderSettings.fontFamily`, default Georgia). It adopts shared tokens for
  color/spacing/radii/chrome only, and its `ReaderTokens` are migrated into (or
  aliased from) the shared scales; reading text is not forced to Poppins.

## 7. Workspace conventions for this repo (must-follow constraints)

From `AGENTS.md` and prior sessions:

- `flutter analyze` must stay at zero warnings (current baseline: 33 infos).
- `flutter test` must keep passing (pre-existing network/format failures are
  out of scope but must not increase).
- Errors must never escape component boundaries; keep error isolation.
- No secrets; no new dependencies.
- Some values are genuinely domain-specific (player overlays, audio-HUD, IPTV
  OSD). Those may keep specialized styling where necessary but should consume
  shared tokens for color/spacing/type where it does not break the feature.
- Codegen/format: repo uses `dart format`-compatible style; keep LF endings.

## 8. Anatomy of the deliverable

New files (proposed):

- `lib/theme/app_tokens.dart` — `PlayTorrioTokens` ThemeExtension (semantic
  colors) + accessor.
- `lib/theme/app_spacing.dart`, `lib/theme/app_radii.dart`,
  `lib/theme/app_typography.dart`, `lib/theme/app_motion.dart`,
  `lib/theme/app_elevation.dart` — static scales.
- `lib/theme/app_theme_extension.dart` — thin registration helpers (or merged
  into `app_tokens.dart`).
- `lib/widgets/ui/` — new shared components (button, chip, badge, card frame,
  poster image, text field, sheet, dialog, empty/error states, skeleton).
- Extend `lib/services/theme/app_theme_service.dart`:
  `AppThemePalette` + 2 fields, and `createThemeData` registers the extension
  + text/appbar/card themes.

Existing files refactored (by phase):

- Phase 2 shared components: `page_top_bar.dart`, `app_liquid_dock.dart` /
  `liquid_dock.dart`, `section_header.dart`, `movie_card.dart`,
  `movie_slider_section.dart`, `poster_skeleton.dart`, `error_view.dart`,
  `modern_toast.dart`, `settings_controls.dart`, `anime_card.dart`,
  `manga_card.dart`, `iptv_channel_card.dart`, `continue_watching_slider.dart`,
  `filter_option_sheet.dart`, `advanced_filter_sheet.dart`.
- Phase 3–6 screens per the agreed order.

## 9. Migration method (per phase)

For each file:

1. Replace inline colors with semantic tokens; replace font sizes with type
   styles; replace radii/spacing with scales.
2. Where a pattern repeats on a screen, prefer extracting to the shared
   component library rather than repeating tokens.
3. Keep behavior identical (routes, callbacks, listeners, settings values).
4. Run `flutter analyze` and `flutter test` after each file/group.
5. Visually self-check the affected screen at ~360px and ~800px widths.

Guardrails: never delete a widget a consumer still uses without grepping;
never change a settings key or persisted value; never touch player/torrent
internals.

## 10. Validation / Definition of done

- `flutter analyze` = 0 warnings (infos ≤ baseline).
- `flutter test` no worse than baseline.
- The same component renders identically across screens.
- Theme switch in Settings recolors every migrated surface (spot-check each
  palette on a migrated screen).
- No text clipping; posters keep correct aspect ratios; safe areas respected.
- Loading/empty/error states exist and match across domains.
- Navigation, search, filters, sort, library, source list, and playback work
  unchanged.
- Deliverables: token system, component library, app-wide adoption, summary,
  file list, build/test results.

## 11. Left to the builder (my calls, not agreed with the partner)

- Exact numeric values of the derivation (alphas, tints) and the precise
  `surfaceSelected` blend.
- Whether the static scales live as standalone classes vs. one `AppTokens`
  class — either is fine as long as color stays reactive.
- Component file layout under `lib/widgets/ui/`.
- Precise enum/field names inside components.
- How much of the player/IPTV OSD adopts tokens (tokens where safe, keep
  specialized styling where required).
- Ordering of files within a phase, and batching for reviews.

## 12. Open risks

- Sheer size (~2k color literals): full adoption is multi-session. The
  incremental plan must make each phase independently shippable.
- `withOpacity` (deprecated) vs `withValues`: migration should normalize to
  `withValues`.
- Some screens hardcode near-black overlays (e.g. `0xE6080A0F`) tied to the
  dark theme; tokenizing them must not break on lighter palettes (all current
  palettes are dark).
- Player/HUD readability depends on context-independent high contrast; treat
  as a specialized surface.

## 13. Fixed semantic colors (decided: allowlist)

**Decision (human partner): allowlist.** "No hardcoded colors" means no inline
color literals in screens/widgets; it does **not** mean the palette must own
every color. Chrome and accents follow the palette. A small, documented set of
*semantic/content* colors are fixed constants defined **once** in the token
layer (never inline):

- `status.success` / `status.warning` / `status.error` (+ `destructive`).
- `rating` — star/accent gold.
- `health.good` / `health.mid` / `health.bad` — torrent seed/peer ratio.
- `download.queued` / `download.active` / `download.done` / `download.failed`.
- `quality.*` — resolution/HDR/codec badge colors.
- (Player/IPTV OSD high-contrast overlays remain a specialized surface.)

Categories (Movie / Series / Anime) stay distinguishable via the existing
`accent` vs `accentSecondary` roles plus surface/opacity differences — they are
not fixed colors.

Consequence for the Definition of Done: the migration is complete when no
screen/widget contains an inline color literal; the only literals left live in
the token layer's allowlist (and the specialized player/OSD surfaces).


