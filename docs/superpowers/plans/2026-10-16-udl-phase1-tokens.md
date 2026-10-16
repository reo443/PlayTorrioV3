# Universal Design Language — Phase 1: Tokens & Theme Wiring — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the centralized, theme-driven token layer for PlayTorrio V3 and wire it into the app theme, with no consumer migration yet.

**Architecture:** Static scale classes (spacing, radii, typography, motion, elevation) plus one fixed-semantic-color allowlist live under `lib/theme/`. A `PlayTorrioTokens` `ThemeExtension` derives all semantic colors from the active `AppThemePalette` and is registered by `AppThemeService.createThemeData`, so `Theme.of(context).extension<PlayTorrioTokens>()` is the single source of truth and recolors live when the palette changes (main.dart already rebuilds `MaterialApp` in a `ValueListenableBuilder`).

**Tech Stack:** Flutter 3.x / Dart 3.11+, Material 3, Poppins (already bundled in `pubspec.yaml`).

**Spec:** `docs/superpowers/specs/2026-10-16-universal-design-language-design.md`

## Global Constraints

- Theme-driven: every accent follows the palette from Settings; there is no fixed blue. (spec §5)
- No new packages; reuse existing dependencies. (spec §5)
- `flutter analyze` must stay at 0 warnings (current baseline: 33 infos). (spec §7)
- `flutter test` must not get worse than the current baseline (pre-existing network/format failures are out of scope). (spec §7)
- Keep LF line endings; the repo has `core.autocrlf=true` and no `.gitattributes`.
- Fixed-semantic colors are the ONLY literal colors allowed outside the token layer (spec §13): `success`, `warning`, `error`, `destructive`, `rating`, `health.*`, `download.*`, `quality.*`.
- Typography styles must NOT bake a `color` (color is applied at call sites from tokens). (spec §6.2)
- Screens must stay transparent over `AnimatedAmbientBackground`; `bgPrimary` is a fallback base only. (spec §6.8)
- Do not change routes, data, API/scraper logic, playback, or persisted settings keys.

## Review Focus

These are the failure modes a person using this software would most likely hit, ranked; each is pinned by a test in the owning task.

1. **Runtime theme switch does not recolor tokens.** Changing palette in Settings must change `PlayTorrioTokens` (per-surface), not stay cached — Task 4/5.
2. **`onAccent` is unreadable on some palette.** Filled controls must pick black or white by luminance on all 8 palettes — Task 4.
3. **A palette built with only the required fields (restored/custom) throws.** New fields must have defaults so tokens still build — Task 5.
4. **Existing theme behavior is lost.** `scaffoldBackgroundColor`, `useMaterial3`, `pageTransitionsTheme`, `appBarTheme` must survive the rewrite — Task 5.
5. **Tokens unreachable in the widget tree.** They must be retrievable via `Theme.of(context).extension<PlayTorrioTokens>()`, not only from the return value of `createThemeData` — Task 5.

---

### Task 1: Static scales — spacing, radii, motion, elevation

**Files:**
- Create: `lib/theme/app_spacing.dart`
- Create: `lib/theme/app_radii.dart`
- Create: `lib/theme/app_motion.dart`
- Create: `lib/theme/app_elevation.dart`
- Test: `test/theme/app_scales_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `AppSpacing` — `xs 4, sm 8, md 12, lg 16, xl 20, xxl 24, xxxl 32, huge 40`, `page 16` (all `static const double`).
  - `AppRadii` — `badge 8, input 12, button 12, card 16, poster 18, sheet 24, chip 999` (`static const double`), plus `BorderRadius` getters `roundedBadge/roundedInput/roundedButton/roundedCard/roundedPoster/roundedSheet/roundedChip`.
  - `AppMotion` — `fast Duration(ms:120), standard Duration(ms:170), sheet Duration(ms:260), themeSwitch Duration(ms:300)`; curves `fastCurve Curves.easeOut, standardCurve Curves.easeOutCubic, sheetCurve Curves.easeOutCubic, themeSwitchCurve Curves.easeInOut`.
  - `AppElevation` — `shadowSm`, `shadowMd` (`static const BoxShadow`); `static BoxShadow glow(Color accent)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/theme/app_scales_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_spacing.dart';
import 'package:playtorrio/theme/app_radii.dart';
import 'package:playtorrio/theme/app_motion.dart';
import 'package:playtorrio/theme/app_elevation.dart';

void main() {
  test('spacing scale is the agreed 4pt ladder', () {
    expect([AppSpacing.xs, AppSpacing.sm, AppSpacing.md, AppSpacing.lg,
      AppSpacing.xl, AppSpacing.xxl, AppSpacing.xxxl, AppSpacing.huge],
      [4, 8, 12, 16, 20, 24, 32, 40]);
    expect(AppSpacing.page, 16);
  });

  test('radii scale matches the spec', () {
    expect([AppRadii.badge, AppRadii.input, AppRadii.button,
      AppRadii.card, AppRadii.poster, AppRadii.sheet],
      [8, 12, 12, 16, 18, 24]);
    expect(AppRadii.chip, 999);
    expect(AppRadii.roundedCard, BorderRadius.circular(16));
  });

  test('motion durations and curves match the spec', () {
    expect(AppMotion.fast, const Duration(milliseconds: 120));
    expect(AppMotion.standard, const Duration(milliseconds: 170));
    expect(AppMotion.sheet, const Duration(milliseconds: 260));
    expect(AppMotion.themeSwitch, const Duration(milliseconds: 300));
    expect(AppMotion.sheetCurve, Curves.easeOutCubic);
  });

  test('elevation glow uses the accent color', () {
    final g = AppElevation.glow(const Color(0xFF7C5CFF));
    expect(g.color.r, closeTo(0x7C / 255, 0.01));
    expect(AppElevation.shadowMd.blurRadius, 16);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/app_scales_test.dart`
Expected: FAIL — `Target of URI doesn't exist` for the four `lib/theme/...` imports.

- [ ] **Step 3: Implement the four scale files**

Create the files with the exact constants in the Interfaces block. `AppRadii` `BorderRadius` getters are `static final` (BorderRadius is const-constructible, but `BorderRadius.circular` is not `const`, so use `static final`). `AppElevation.shadowMd` = `BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0,4))`; `shadowSm` = `BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0,2))`; `glow(accent)` = `BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 22, spreadRadius: 0)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/theme/app_scales_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/theme/app_spacing.dart lib/theme/app_radii.dart lib/theme/app_motion.dart lib/theme/app_elevation.dart test/theme/app_scales_test.dart
git commit -m "feat(theme): add spacing, radii, motion, elevation scales"
```

---

### Task 2: Typography scale

**Files:**
- Create: `lib/theme/app_typography.dart`
- Test: `test/theme/app_typography_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `AppTypography` — `static const TextStyle display, screenTitle, sectionHeading, cardTitle, body, bodyStrong, supporting, label, caption, badge`. All use `fontFamily: 'Poppins'`, no `color`.

- [ ] **Step 1: Write the failing test**

```dart
// test/theme/app_typography_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_typography.dart';

void main() {
  test('type scale uses Poppins and fixes no color', () {
    for (final s in [AppTypography.display, AppTypography.screenTitle,
      AppTypography.sectionHeading, AppTypography.cardTitle, AppTypography.body,
      AppTypography.bodyStrong, AppTypography.supporting, AppTypography.label,
      AppTypography.caption, AppTypography.badge]) {
      expect(s.fontFamily, 'Poppins');
      expect(s.color, isNull);
    }
  });

  test('sizes and weights follow the spec', () {
    expect(AppTypography.display.fontSize, 28);
    expect(AppTypography.display.fontWeight, FontWeight.w800);
    expect(AppTypography.screenTitle.fontSize, 22);
    expect(AppTypography.sectionHeading.fontSize, 17);
    expect(AppTypography.cardTitle.fontSize, 15.5);
    expect(AppTypography.body.fontSize, 14);
    expect(AppTypography.supporting.fontSize, 13);
    expect(AppTypography.caption.fontSize, 12);
    expect(AppTypography.badge.fontSize, 10);
    expect(AppTypography.badge.letterSpacing, 0.6);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/app_typography_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Implement `AppTypography`**

Exact values (all `fontFamily: 'Poppins'`, all `color: null`):
`display` 28/w800/−0.5 · `screenTitle` 22/w800/−0.3 · `sectionHeading` 17/w700/−0.2 · `cardTitle` 15.5/w700/−0.25, height 1.15 · `body` 14/w400, height 1.4 · `bodyStrong` 14/w600 · `supporting` 13/w400 · `label` 13/w600 · `caption` 12/w500 · `badge` 10/w800, letterSpacing 0.6.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/theme/app_typography_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/theme/app_typography.dart test/theme/app_typography_test.dart
git commit -m "feat(theme): add Poppins-based typography scale"
```

---

### Task 3: Fixed semantic colors (allowlist)

**Files:**
- Create: `lib/theme/app_semantic_colors.dart`
- Test: `test/theme/app_semantic_colors_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `AppSemanticColors` — `static const Color success, warning, error, destructive, rating, healthGood, healthMid, healthBad, downloadQueued, downloadActive, downloadDone, downloadFailed, quality4k, qualityHd, qualitySd`.

- [ ] **Step 1: Write the failing test**

```dart
// test/theme/app_semantic_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_semantic_colors.dart';

void main() {
  test('semantic colors are fixed, distinct constants', () {
    expect(AppSemanticColors.success, const Color(0xFF30A46C));
    expect(AppSemanticColors.warning, const Color(0xFFF5A623));
    expect(AppSemanticColors.error, const Color(0xFFE5484D));
    expect(AppSemanticColors.destructive, AppSemanticColors.error);
    expect(AppSemanticColors.rating, const Color(0xFFFFB800));
    expect(AppSemanticColors.healthGood, AppSemanticColors.success);
    expect(AppSemanticColors.healthBad, AppSemanticColors.error);
    expect(AppSemanticColors.downloadFailed, AppSemanticColors.error);
    expect(
      {AppSemanticColors.quality4k, AppSemanticColors.qualityHd,
       AppSemanticColors.qualitySd}.length, 3);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/app_semantic_colors_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Implement `AppSemanticColors`**

Exact values: `success 0xFF30A46C`, `warning 0xFFF5A623`, `error 0xFFE5484D`, `destructive 0xFFE5484D`, `rating 0xFFFFB800`, `healthGood 0xFF30A46C`, `healthMid 0xFFF5A623`, `healthBad 0xFFE5484D`, `downloadQueued 0xFF9AA6B8`, `downloadActive 0xFF3B82F6`, `downloadDone 0xFF30A46C`, `downloadFailed 0xFFE5484D`, `quality4k 0xFF7C5CFF`, `qualityHd 0xFF3B82F6`, `qualitySd 0xFF9AA6B8`. Add a class doc comment stating these are the only permitted literal colors and why (semantic meaning, see spec §13).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/theme/app_semantic_colors_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/theme/app_semantic_colors.dart test/theme/app_semantic_colors_test.dart
git commit -m "feat(theme): add fixed semantic color allowlist"
```

---

### Task 4: `PlayTorrioTokens` ThemeExtension

**Files:**
- Create: `lib/theme/playtorrio_tokens.dart`
- Test: `test/theme/playtorrio_tokens_test.dart`

**Interfaces:**
- Consumes: `AppThemePalette` (`lib/services/theme/app_theme_service.dart`), `AppSemanticColors`.
- Produces:
  - `PlayTorrioTokens extends ThemeExtension<PlayTorrioTokens>` with `final Color` fields: `bgPrimary, bgSecondary, surface, surfaceElevated, surfaceSelected, borderSubtle, borderStrong, textPrimary, textSecondary, textTertiary, accent, accentSecondary, focusRing, destructive, success, warning, error, onAccent, onSurface`.
  - `factory PlayTorrioTokens.fromPalette(AppThemePalette palette)`.
  - `static PlayTorrioTokens of(BuildContext context)` → reads the extension (falls back to `fromPalette(AppThemeService.currentPalette.value)` if absent).
  - `copyWith(...)`, `lerp(...)` overriding `ThemeExtension`.

- [ ] **Step 1: Write the failing test**

```dart
// test/theme/playtorrio_tokens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/theme/app_semantic_colors.dart';

void main() {
  final amethyst = AppThemeService.palettes[0]; // primary 0xFF7C5CFF
  final amber = AppThemeService.palettes.firstWhere((p) => p.id == 'amber');

  test('derives surfaces/accents from the palette', () {
    final t = PlayTorrioTokens.fromPalette(amethyst);
    expect(t.bgPrimary, amethyst.scaffoldBackgroundColor);
    expect(t.surface, amethyst.cardBackgroundColor);
    expect(t.accent, amethyst.primaryColor);
    expect(t.accentSecondary, amethyst.accentColor);
    expect(t.borderSubtle.a, closeTo(0.06, 0.01));
    expect(t.error, AppSemanticColors.error);
    expect(t.success, AppSemanticColors.success);
  });

  test('onAccent picks a readable foreground on every palette', () {
    for (final p in AppThemeService.palettes) {
      final t = PlayTorrioTokens.fromPalette(p);
      final luminance = t.accent.computeLuminance();
      final expected = luminance > 0.5 ? Colors.black : Colors.white;
      expect(t.onAccent, expected, reason: 'palette ${p.id}');
    }
    expect(PlayTorrioTokens.fromPalette(amber).onAccent, Colors.black);
    expect(PlayTorrioTokens.fromPalette(amethyst).onAccent, Colors.white);
  });

  test('two palettes yield different tokens (no shared cache)', () {
    expect(
      PlayTorrioTokens.fromPalette(amethyst).surface,
      isNot(PlayTorrioTokens.fromPalette(amber).surface));
  });

  test('lerp interpolates between two token sets', () {
    final a = PlayTorrioTokens.fromPalette(amethyst);
    final b = PlayTorrioTokens.fromPalette(amber);
    final mid = a.lerp(b, 0.5) as PlayTorrioTokens;
    expect(mid.accent, Color.lerp(a.accent, b.accent, 0.5));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/playtorrio_tokens_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Implement `PlayTorrioTokens`**

Derivation (exact):
- `bgPrimary = palette.scaffoldBackgroundColor`
- `bgSecondary = palette.backgroundSecondaryColor`
- `surface = palette.cardBackgroundColor`
- `surfaceElevated = palette.surfaceElevatedColor`
- `surfaceSelected = Color.alphaBlend(palette.primaryColor.withValues(alpha: 0.20), palette.cardBackgroundColor)`
- `borderSubtle = Colors.white.withValues(alpha: 0.06)`, `borderStrong = Colors.white.withValues(alpha: 0.12)`
- `textPrimary = Colors.white.withValues(alpha: 0.95)`, `textSecondary = Colors.white.withValues(alpha: 0.62)`, `textTertiary = Colors.white.withValues(alpha: 0.42)`
- `accent = palette.primaryColor`, `accentSecondary = palette.accentColor`, `focusRing = palette.primaryColor`
- `destructive/success/warning/error` from `AppSemanticColors`
- `onAccent = (palette.primaryColor.computeLuminance() > 0.5) ? Colors.black : Colors.white`
- `onSurface = (palette.cardBackgroundColor.computeLuminance() > 0.5) ? Colors.black : Colors.white`

This task references `palette.backgroundSecondaryColor` / `palette.surfaceElevatedColor`, which Task 5 adds **with defaults**; therefore add those two fields to `AppThemePalette` in this task's change (fields + defaults only; per-palette values are Task 5). Keep the `AppThemePalette` diff minimal: two `final Color` fields with defaults `Color(0xFF0D1017)` and `Color(0xFF171A23)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/theme/playtorrio_tokens_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/theme/playtorrio_tokens.dart test/theme/playtorrio_tokens_test.dart lib/services/theme/app_theme_service.dart
git commit -m "feat(theme): add PlayTorrioTokens theme extension"
```

---

### Task 5: Wire tokens into the app theme

**Files:**
- Modify: `lib/services/theme/app_theme_service.dart` (add per-palette values for the two new fields; rewrite `createThemeData`)
- Test: `test/theme/app_theme_service_tokens_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens`, `AppSemanticColors`, `AppTypography`.
- Produces: `AppThemeService.createThemeData(AppThemePalette)` whose result exposes `Theme.of(context).extension<PlayTorrioTokens>()` and a Poppins font family; `AppThemePalette` gains explicit `backgroundSecondaryColor`/`surfaceElevatedColor` per palette.

- [ ] **Step 1: Write the failing test**

```dart
// test/theme/app_theme_service_tokens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';

void main() {
  final amethyst = AppThemeService.palettes[0];
  final amber = AppThemeService.palettes.firstWhere((p) => p.id == 'amber');

  test('createThemeData registers the token extension', () {
    final theme = AppThemeService.createThemeData(amethyst);
    expect(theme.extension<PlayTorrioTokens>(), isNotNull);
    expect(theme.extension<PlayTorrioTokens>()!.accent, amethyst.primaryColor);
  });

  test('colorScheme roles come from the palette, not a blind seed', () {
    final theme = AppThemeService.createThemeData(amethyst);
    expect(theme.colorScheme.primary, amethyst.primaryColor);
    expect(theme.colorScheme.secondary, amethyst.accentColor);
    expect(theme.colorScheme.surface, amethyst.cardBackgroundColor);
    expect(theme.colorScheme.onPrimary,
        PlayTorrioTokens.fromPalette(amethyst).onAccent);
  });

  test('existing behavior is preserved', () {
    final theme = AppThemeService.createThemeData(amethyst);
    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, amethyst.scaffoldBackgroundColor);
    expect(theme.appBarTheme.backgroundColor, amethyst.appBarBackgroundColor);
    expect(theme.pageTransitionsTheme.builders[TargetPlatform.android],
        isA<FadeUpwardsPageTransitionsBuilder>());
  });

  test('a palette with only required fields still builds tokens', () {
    const bare = AppThemePalette(id: 'x', name: 'X',
        primaryColor: Color(0xFF7C5CFF), accentColor: Color(0xFF00E5FF));
    final t = PlayTorrioTokens.fromPalette(bare);
    expect(t.surfaceElevated, const Color(0xFF171A23));
    expect(AppThemeService.createThemeData(bare).extension<PlayTorrioTokens>(),
        isNotNull);
  });

  testWidgets('tokens are reachable via Theme.of(context)', (tester) async {
    late PlayTorrioTokens tokens;
    await tester.pumpWidget(MaterialApp(
      theme: AppThemeService.createThemeData(amber),
      home: Builder(builder: (context) {
        tokens = PlayTorrioTokens.of(context);
        return const SizedBox();
      }),
    ));
    expect(tokens.accent, amber.primaryColor);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/app_theme_service_tokens_test.dart`
Expected: FAIL — `createThemeData` does not register an extension / `colorScheme.primary` is the seeded tonal value.

- [ ] **Step 3: Implement**

1. Add explicit `backgroundSecondaryColor` / `surfaceElevatedColor` to all 8 palettes (each a shade between `scaffoldBackgroundColor` and `cardBackgroundColor`; e.g. amethyst `0xFF0C0F16` / `0xFF171A23`, sapphire `0xFF0A1220` / `0xFF141F31`, and analogous per palette).
2. In `createThemeData`: build `final tokens = PlayTorrioTokens.fromPalette(palette);` then return `ThemeData` with:
   - `fontFamily: 'Poppins'`
   - `colorScheme: ColorScheme.fromSeed(seedColor: palette.primaryColor, brightness: Brightness.dark).copyWith(primary: palette.primaryColor, onPrimary: tokens.onAccent, secondary: palette.accentColor, onSecondary: tokens.onAccent, surface: palette.cardBackgroundColor, onSurface: tokens.onSurface, surfaceTint: Colors.transparent, error: tokens.error)`
   - keep `scaffoldBackgroundColor`, `useMaterial3: true`, `appBarTheme`, `cardTheme`, `pageTransitionsTheme` exactly as they are now
   - `extensions: [tokens]`

Rationale (spec §6.8): every visible `ColorScheme` role is overridden from the palette/tokens; the seed only fills unspecified roles, and `surfaceTint` is transparent so tonal tinting can't fight the flat look.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/theme/app_theme_service_tokens_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Run the full suite and analyze**

Run: `flutter analyze`
Expected: 0 errors/warnings, infos ≤ 33.
Run: `flutter test`
Expected: no new failures versus baseline (pre-existing network/format failures only).

- [ ] **Step 6: Commit**

```bash
git add lib/services/theme/app_theme_service.dart test/theme/app_theme_service_tokens_test.dart
git commit -m "feat(theme): wire tokens, Poppins, and palette-driven ColorScheme"
```

---

## Self-Review

**1. Spec coverage (Phase 1 portion of the spec):**
- §6.1 color palette / semantic roles → Tasks 3, 4, 5.
- §6.2 typography → Task 2.
- §6.3 spacing → Task 1. §6.4 radii → Task 1. §6.5 elevation/motion → Task 1.
- §6.6 access model (ThemeExtension, live rebuild) → Tasks 4, 5.
- §6.7 naming → used verbatim.
- §6.8 compositing/glass/ColorScheme/contrast → onAccent (Task 4), ColorScheme (Task 5); ambient/glass/reader are consumer-migration concerns deferred to later-phase plans.
- §13 allowlist → Task 3.
- Component library (§4/§8) and screen migration (§9/§10) are intentionally **not** in this plan; they get their own phase plans.

**2. Step scan:** every step is one action with a checkable result; no "handle edge cases" filler. Code steps pin exact signatures/values; bodies are left to the implementer except where the spec fixes values (done).

**3. Type consistency:** `PlayTorrioTokens` field names and `fromPalette`/`of`/`copyWith`/`lerp` are used identically in Tasks 4 and 5. `AppThemePalette.backgroundSecondaryColor`/`surfaceElevatedColor` are introduced in Task 4 and given per-palette values in Task 5.

**4. Review Focus:** each of the five lines has a test in the owning task (Tasks 4 and 5).

**5. Proportion:** plan is comparable to the Phase 1 slice of the spec; code blocks are test bodies and derivations, not implementations.
