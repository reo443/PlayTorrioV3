# UDL Phase 3a — Explicit ColorScheme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `ColorScheme.fromSeed` with an explicitly constructed `ColorScheme` whose roles come from the palette and the tokens, so every built-in Material widget on every screen agrees with the design language.

**Architecture:** `AppThemeService.createThemeData` currently calls `ColorScheme.fromSeed(seedColor: palette.primaryColor).copyWith(...)`. The `copyWith` pins eight roles, but every other role — `surfaceContainer*`, `onSurfaceVariant`, `outline`, `outlineVariant`, `secondaryContainer`, `inverseSurface`, `errorContainer` — is *derived from the seed* by Material's tonal algorithm, which is a second colour source (spec §6.8 calls this a violation). Screens then render dialogs, sheets, snackbars, sliders, switches and progress indicators in tones the hand-authored palette never defined. This phase removes the seed entirely and maps every widget-facing role onto an existing palette field or token.

**Tech Stack:** Flutter 3.47.6 / Dart 3.11, `flutter_test`, Material 3. No new packages.

**Spec:** `docs/superpowers/specs/2026-10-16-universal-design-language-design.md` §6.8, §6.1, §7, §10, §11, §13. **This file is deleted from the working tree on purpose — read it with `git show HEAD:docs/superpowers/specs/2026-10-16-universal-design-language-design.md` (353 lines).** §6.8 is the section this plan implements.

---

## Global Constraints

- **`flutter analyze` → 0 errors, 0 warnings, ≤33 infos.** Do **not** reference the deprecated `ColorScheme.background`, `onBackground` or `surfaceVariant` members — on Flutter 3.47 they emit deprecation warnings and would break the gate. Use `surface`/`onSurface`/`surfaceContainerHighest` instead. (Building the scheme explicitly rather than with `fromSeed` removes these already.)
- **Do not change the `PlayTorrioTokens` ThemeExtension.** Its shape is reviewed phase-2a output; this phase only *reads* it.
- **These existing assertions are a frozen contract** — they are pinned by `test/theme/app_theme_service_tokens_test.dart` and `test/theme/app_theme_service_test.dart`, and must keep passing unchanged:
  `brightness == Brightness.dark`, `primary == palette.primaryColor`, `secondary == palette.accentColor`, `surface == palette.cardBackgroundColor`, `onPrimary == PlayTorrioTokens.fromPalette(palette).onAccent`, `useMaterial3 == true`, `scaffoldBackgroundColor == palette.scaffoldBackgroundColor`, `appBarTheme.backgroundColor == palette.appBarBackgroundColor`, the `FadeUpwardsPageTransitionsBuilder` platform map, and `tokens.accent == palette.primaryColor`.
- **`test/theme/app_theme_service_test.dart` is untracked and not ours.** Do not edit it; make it pass.
- **Never add inline colour literals to a *screen or widget*.** `app_theme_service.dart` is the token layer: it legitimately holds the eight palette definitions and may hold derivation constants. Do not add it to `test/udl/no_inline_colors_test.dart`'s `migratedFiles`.
- **Behaviour preserved:** routes, callbacks, listeners, the `_storageKey` preference, and every value in `AppThemePalette`.
- **No new dependencies.**

### Role mapping (the decision this plan exists to record)

`surface`/`onSurface`/`primary`/`onPrimary`/`secondary` keep their current values. The rest are mapped as follows; `blend(c, a)` means `Color.alphaBlend(c.withValues(alpha: a), palette.cardBackgroundColor)`.

| Role | Value |
|---|---|
| `brightness` | `Brightness.dark` |
| `primary` / `onPrimary` | `palette.primaryColor` / `tokens.onAccent` *(unchanged)* |
| `primaryContainer` / `onPrimaryContainer` | `blend(palette.primaryColor, 0.20)` / `tokens.textPrimary` |
| `secondary` / `onSecondary` | `palette.accentColor` / `tokens.onAccent` — **carried over unchanged from today's code; Task 2 replaces it with `_onColor(palette.accentColor)`** |
| `secondaryContainer` / `onSecondaryContainer` | `blend(palette.accentColor, 0.20)` / `tokens.textPrimary` |
| `tertiary` / `onTertiary` | `palette.accentColor` / `tokens.onAccent` — **same as `secondary`; Task 2 replaces this too** |
| `error` / `onError` | `tokens.error` / `_onColor(tokens.error)` |
| `errorContainer` / `onErrorContainer` | `blend(tokens.error, 0.20)` / `tokens.textPrimary` |
| `surface` / `onSurface` | `palette.cardBackgroundColor` / `tokens.onSurface` *(unchanged)* |
| `onSurfaceVariant` | `tokens.textSecondary` |
| `surfaceContainerLowest` | `palette.scaffoldBackgroundColor` |
| `surfaceContainerLow` | `palette.appBarBackgroundColor` |
| `surfaceContainer` | `palette.cardBackgroundColor` |
| `surfaceContainerHigh` / `surfaceContainerHighest` | `palette.surfaceElevatedColor` |
| `outline` / `outlineVariant` | `tokens.borderStrong` / `tokens.borderSubtle` |
| `inverseSurface` / `onInverseSurface` | `palette.surfaceElevatedColor` / `tokens.textPrimary` |
| `inversePrimary` | `palette.primaryColor` |
| `surfaceTint` | `Colors.transparent` *(unchanged — it is what stops M3 from tinting elevated surfaces away from the palette)* |
| `shadow`, `scrim` | **left to Material's defaults** — both are plain black in M3 and no palette field is a truthful substitute; document this in the plan, not in a fake token |

`_onColor(Color background)` returns `background.computeLuminance() > 0.2 ? Colors.black : Colors.white` — the same rule `PlayTorrioTokens.fromPalette` already uses for `onAccent`/`onSurface`. It is duplicated in the theme layer rather than added to the reviewed token class.

## Review Focus

These are the conditions the spec implies but a single-palette happy path does not exercise. Each has a test in the task that owns the code.

1. **A bright palette.** Amethyst's accent is white-on-`0xFF7C5CFF`, but Golden Amber (`0xFFF59E0B`) and Cyberpunk Neon (`0xFFFF2A85`) are light enough to need black text. A mapping validated only on Amethyst silently produces unreadable text on three palettes.
2. **A palette with only the required fields**, e.g. `AppThemePalette(id:, name:, primary:, accent:)` — the bare palette's default surface fields must still yield a complete, palette-consistent scheme.
3. **A light surface.** `onSurface`/`onAccent` are chosen by luminance, so a light `cardBackgroundColor` must flip them to black. Nothing today proves the choice inverts.
4. **Switching palettes at runtime** — a dialog or snackbar already on screen must recolour, not just the tokens.
5. **`surfaceTint` left non-transparent** — M3 would tint every elevated surface with `primary`, and the hand-authored `surfaceElevatedColor` would never actually be seen. The role must stay transparent.

---

## File Structure

| File | Action |
|---|---|
| `lib/services/theme/app_theme_service.dart` | modify — add `_buildColorScheme` + `_onColor`, replace the `colorScheme:` argument (~lines 152-164) |
| `test/theme/explicit_colorscheme_test.dart` | create — the role mapping, all 8 palettes, bare and light palettes |
| `test/theme/builtin_widgets_theme_test.dart` | create — built-in Material widgets and live recolouring |

---

### Task 1: Build the scheme explicitly, off the seed

**Files:**
- Modify: `lib/services/theme/app_theme_service.dart`
- Test: `test/theme/explicit_colorscheme_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens.fromPalette(AppThemePalette)`, whose fields are `bgPrimary, bgSecondary, surface, surfaceElevated, surfaceSelected, borderSubtle, borderStrong, textPrimary, textSecondary, textTertiary, accent, accentSecondary, focusRing, destructive, success, warning, error, onAccent, onSurface`.
- Produces: `static ColorScheme _buildColorScheme(AppThemePalette palette, PlayTorrioTokens tokens)` and `static Color _onColor(Color background)`, both private to `AppThemeService`. Task 2 and Task 3 rely on the produced `ColorScheme` roles only, never on the helper names.

- [ ] **Step 1: Write the failing test**

```dart
// test/theme/explicit_colorscheme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';

ColorScheme _schemeOf(AppThemePalette p) =>
    AppThemeService.createThemeData(p).colorScheme;

void main() {
  final amethyst = AppThemeService.palettes[0];
  final amethystTokens = PlayTorrioTokens.fromPalette(amethyst);

  test('every widget-facing role is available and palette-derived', () {
    final cs = _schemeOf(amethyst);
    final tokens = amethystTokens;

    expect(cs.surface, amethyst.cardBackgroundColor);
    expect(cs.onSurface, tokens.onSurface);
    expect(cs.onSurfaceVariant, tokens.textSecondary);
    expect(cs.surfaceContainerLowest, amethyst.scaffoldBackgroundColor);
    expect(cs.surfaceContainerLow, amethyst.appBarBackgroundColor);
    expect(cs.surfaceContainer, amethyst.cardBackgroundColor);
    expect(cs.surfaceContainerHigh, amethyst.surfaceElevatedColor);
    expect(cs.surfaceContainerHighest, amethyst.surfaceElevatedColor);
    expect(cs.outline, tokens.borderStrong);
    expect(cs.outlineVariant, tokens.borderSubtle);
    expect(cs.inverseSurface, amethyst.surfaceElevatedColor);
    expect(cs.onInverseSurface, tokens.textPrimary);
    expect(cs.inversePrimary, amethyst.primaryColor);
    expect(cs.error, tokens.error);
    // M3 tints elevated surfaces with primary unless this is transparent, which
    // would hide palette.surfaceElevatedColor entirely.
    expect(cs.surfaceTint, Colors.transparent);
  });

  test('palette-derived roles do not come from a seed', () {
    // A seed would tint these with primary; the palette says otherwise.
    // Note: tokens.borderStrong/borderSubtle are white alphas, identical on
    // every palette, so `outline` is deliberately *not* compared here.
    for (final p in AppThemeService.palettes) {
      final cs = _schemeOf(p);
      final blend = Color.alphaBlend(
        p.accentColor.withValues(alpha: 0.20),
        p.cardBackgroundColor,
      );
      expect(cs.surfaceContainerHigh, p.surfaceElevatedColor, reason: p.id);
      expect(cs.secondaryContainer, blend, reason: p.id);
    }

    // Two palettes with different accents cannot share a container tint.
    final amber = AppThemeService.palettes.firstWhere((p) => p.id == 'amber');
    expect(
      _schemeOf(amethyst).secondaryContainer,
      isNot(_schemeOf(amber).secondaryContainer),
    );
  });

  test('a bright palette gets a palette-consistent scheme', () {
    for (final p in AppThemeService.palettes) {
      final cs = _schemeOf(p);
      final tokens = PlayTorrioTokens.fromPalette(p);
      expect(cs.primary, p.primaryColor, reason: p.id);
      expect(cs.secondary, p.accentColor, reason: p.id);
      expect(cs.surface, p.cardBackgroundColor, reason: p.id);
      expect(cs.surfaceContainerHigh, p.surfaceElevatedColor, reason: p.id);
      expect(cs.onSurface, tokens.onSurface, reason: p.id);
    }
  });

  test('a palette with only the required fields still builds', () {
    const bare = AppThemePalette(
      id: 'bare',
      name: 'Bare',
      primaryColor: Color(0xFF7C5CFF),
      accentColor: Color(0xFF00E5FF),
    );
    final cs = _schemeOf(bare);
    final tokens = PlayTorrioTokens.fromPalette(bare);

    expect(cs.surface, bare.cardBackgroundColor);
    expect(cs.surfaceContainerHigh, bare.surfaceElevatedColor);
    expect(cs.onSurface, tokens.onSurface);
    expect(cs.surfaceTint, Colors.transparent);
  });

  test('a light surface inverts the on-colours', () {
    const light = AppThemePalette(
      id: 'light',
      name: 'Light',
      primaryColor: Color(0xFF7C5CFF),
      accentColor: Color(0xFF00E5FF),
      cardBackgroundColor: Color(0xFFF5F5F7),
      scaffoldBackgroundColor: Color(0xFFFFFFFF),
      surfaceElevatedColor: Color(0xFFFFFFFF),
      appBarBackgroundColor: Color(0xFFEFEFF2),
    );
    final cs = _schemeOf(light);
    final tokens = PlayTorrioTokens.fromPalette(light);

    // onSurface is chosen by luminance, so a light card must read dark.
    expect(tokens.onSurface, Colors.black);
    expect(cs.onSurface, Colors.black);
    expect(cs.onSurface, isNot(tokens.textPrimary));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/theme/explicit_colorscheme_test.dart`
Expected: FAIL on `cs.surfaceContainerHighest` / `cs.onSurfaceVariant` / `cs.outline` — the seed-derived values are not the palette's.

- [ ] **Step 3: Add `_onColor` and `_buildColorScheme` to `AppThemeService`, and replace the `colorScheme:` argument.**

`_buildColorScheme` returns the scheme built from the mapping table above, constructed directly (no `fromSeed`). `_onColor(Color background)` implements the 0.2-luminance rule. In `createThemeData`, replace the whole `colorScheme: ColorScheme.fromSeed(...).copyWith(...)` expression with `colorScheme: _buildColorScheme(palette, tokens)`, leaving `brightness`, `fontFamily`, `scaffoldBackgroundColor`, `useMaterial3`, `appBarTheme`, `cardTheme`, `pageTransitionsTheme` and `extensions` untouched.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/theme/explicit_colorscheme_test.dart`
Expected: PASS (5/5).

- [ ] **Step 5: Confirm the frozen contract still holds**

Run: `flutter test test/theme test/widgets_ui test/udl`
Expected: PASS — including the untouched `app_theme_service_tokens_test.dart` and the untracked `app_theme_service_test.dart`.

- [ ] **Step 6: Commit**

```bash
git add lib/services/theme/app_theme_service.dart test/theme/explicit_colorscheme_test.dart
git commit -m "refactor(theme): build the ColorScheme from the palette instead of a seed"
```

---

### Task 2: Fix the `onSecondary` contrast and prove it on every palette

**Files:**
- Modify: `lib/services/theme/app_theme_service.dart`
- Test: `test/theme/explicit_colorscheme_test.dart`

**Interfaces:**
- Consumes: `_buildColorScheme` and `_onColor` from Task 1.
- Produces: nothing new — this task only corrects the `onSecondary`/`onTertiary` values Task 1 wires up.

- [ ] **Step 1: Write the failing test** (append to `test/theme/explicit_colorscheme_test.dart`)

```dart
  test('onSecondary contrasts with secondary, which is not onPrimary', () {
    // Amethyst is the case that exposes the bug: its primary needs white text
    // but its accent is bright enough to need black.
    final cs = _schemeOf(amethyst);

    expect(cs.onSecondary, Colors.black);
    expect(cs.onPrimary, Colors.white);
    expect(cs.onSecondary, isNot(amethystTokens.onAccent));
  });

  test('each on-colour maximises contrast on its own surface', () {
    double contrast(Color a, Color b) {
      final l1 = a.computeLuminance();
      final l2 = b.computeLuminance();
      final hi = l1 > l2 ? l1 : l2;
      final lo = l1 > l2 ? l2 : l1;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final p in AppThemeService.palettes) {
      final cs = _schemeOf(p);
      final pairs = <String, (Color, Color)>{
        'primary/onPrimary': (cs.primary, cs.onPrimary),
        'secondary/onSecondary': (cs.secondary, cs.onSecondary),
        'error/onError': (cs.error, cs.onError),
        'surface/onSurface': (cs.surface, cs.onSurface),
      };
      pairs.forEach((name, pair) {
        expect(
          contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(4.0),
          reason: '${p.id} $name',
        );
      });
    }
  });

  test('a light palette inverts the on-colours too', () {
    const light = AppThemePalette(
      id: 'light',
      name: 'Light',
      primaryColor: Color(0xFFF5D90A),
      accentColor: Color(0xFF0B4C2A),
      cardBackgroundColor: Color(0xFFF5F5F7),
    );
    final cs = _schemeOf(light);

    // A bright primary takes dark text; a dark secondary takes light text.
    expect(cs.onPrimary, Colors.black);
    expect(cs.onSecondary, Colors.white);
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/theme/explicit_colorscheme_test.dart`
Expected: FAIL — `onSecondary` equals `tokens.onAccent` (white), not black.

- [ ] **Step 3: Change `onSecondary` (and `onTertiary`, which shadows the same colour) to `_onColor(palette.accentColor)`.**

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/theme/explicit_colorscheme_test.dart`
Expected: PASS (8/8).

- [ ] **Step 5: Commit**

```bash
git add lib/services/theme/app_theme_service.dart test/theme/explicit_colorscheme_test.dart
git commit -m "fix(theme): pick onSecondary from the accent instead of reusing onAccent"
```

---

### Task 3: Prove the built-in widgets agree, and recolour live

**Files:**
- Test: `test/theme/builtin_widgets_theme_test.dart`

**Interfaces:**
- Consumes: `AppThemeService.createThemeData` from Tasks 1-2.
- Produces: nothing — verification only.

- [ ] **Step 1: Write the failing test**

```dart
// test/theme/builtin_widgets_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';

const _home = SizedBox(width: 300, height: 300);

Widget _app(Widget child, AppThemePalette palette) => MaterialApp(
  theme: AppThemeService.createThemeData(palette),
  home: Scaffold(body: Builder(builder: (_) => child)),
);

/// The colour of the first [Material] inside [finder]'s subtree.
Color? _fillOf(WidgetTester tester, Finder finder) => tester
    .widget<Material>(find.descendant(of: finder, matching: find.byType(Material)).first)
    .color;

void main() {
  final amethyst = AppThemeService.palettes[0];
  final cs = AppThemeService.createThemeData(amethyst).colorScheme;

  testWidgets('a dialog paints the elevated surface', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const Dialog(child: _home),
            ),
            child: const Text('open'),
          ),
        ),
        amethyst,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(
      _fillOf(tester, find.byType(Dialog)),
      amethyst.surfaceElevatedColor,
    );
  });

  testWidgets('a snackbar paints the inverse surface', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('hi'))),
            child: const Text('show'),
          ),
        ),
        amethyst,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(_fillOf(tester, find.byType(SnackBar)), cs.inverseSurface);
  });

  testWidgets('a bottom sheet paints the low container', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const _home,
            ),
            child: const Text('open'),
          ),
        ),
        amethyst,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(_fillOf(tester, find.byType(BottomSheet)), cs.surfaceContainerLow);
  });

  testWidgets('a dialog recolours when the palette changes', (tester) async {
    final original = AppThemeService.currentPalette.value;
    addTearDown(() => AppThemeService.currentPalette.value = original);
    AppThemeService.currentPalette.value = amethyst;

    await tester.pumpWidget(
      ValueListenableBuilder<AppThemePalette>(
        valueListenable: AppThemeService.currentPalette,
        builder: (context, palette, _) => MaterialApp(
          theme: AppThemeService.createThemeData(palette),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const Dialog(child: _home),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final amber = AppThemeService.palettes.firstWhere((p) => p.id == 'amber');
    AppThemeService.currentPalette.value = amber;
    await tester.pumpAndSettle();

    expect(_fillOf(tester, find.byType(Dialog)), amber.surfaceElevatedColor);
    expect(
      _fillOf(tester, find.byType(Dialog)),
      isNot(amethyst.surfaceElevatedColor),
    );
  });
}
```

- [ ] **Step 2: Run it**

Run: `flutter test test/theme/builtin_widgets_theme_test.dart`
Expected: PASS (4/4). This task writes no production code — Tasks 1-2 already made the scheme palette-derived, so these pass on the first run. That makes Task 3 a *verification* task, not a TDD one; if you want to watch it fail, do it against the pre-Task-1 state (`git stash push test/theme/builtin_widgets_theme_test.dart`, `git checkout HEAD~2 -- lib/services/theme/app_theme_service.dart`), which is the seed-derived behaviour §6.8 calls a violation.

- [ ] **Step 3: If an assertion fails, fix `_buildColorScheme` — not the expectation.**

The expected value (`amethyst.surfaceElevatedColor`, and so on) is the contract; the finder is not. If the finder picks the wrong `Material` — a route scrim rather than the sheet's surface — narrow the finder. If a built-in widget reads a role the mapping missed, assign that role from a palette field or token. Never relax an expectation to the seed-derived colour.

- [ ] **Step 4: Confirm the gate**

Run: `flutter analyze` then `flutter test test/theme test/udl test/widgets_ui`
Expected: 0 errors, 0 warnings, ≤33 infos; all pass.

- [ ] **Step 5: Commit**

```bash
git add test/theme/builtin_widgets_theme_test.dart
git commit -m "test(theme): pin Material widget surfaces to the palette's ColorScheme"
```

---

## Verification

- [ ] `flutter analyze` → 0 errors, 0 warnings, ≤33 infos (watch specifically for `deprecated_member_use` on `ColorScheme`).
- [ ] `flutter test test/theme test/udl test/widgets_ui` → all pass.
- [ ] `flutter test` → the pre-existing live-network/model failures only, and none *new*; failures under `test/udl`, `test/widgets_ui` or `test/theme` are a hard stop.
- [ ] `grep` `app_theme_service.dart` for `fromSeed` → zero hits.
- [ ] `git status` shows `test/theme/app_theme_service_test.dart` still untracked and unmodified.

## Self-Review

**Spec coverage.** §6.8 "replace the seed with an explicitly constructed ColorScheme whose primary/secondary/surface/background/error come from the palette and tokens" → Task 1. §6.8 "so built-in Material widgets (Switch, Slider, Dialog, BottomSheet, TextField, SnackBar, ProgressIndicator, ripple) agree" → Task 3 pins Dialog, BottomSheet, SnackBar and ProgressIndicator. §6.8 "Contrast … onAccent/onSurface are computed by luminance" → Task 2, which also fixes the `onSecondary` mismatch the phase-1 ledger recorded. §13 → no screen or widget gains a literal; the palette definitions stay in the token layer. §10 "theme switch recolors every migrated surface" → the live-recolour test in Task 3.

**Not covered, deliberately.** Switch, Slider and TextField resolve their colours through private defaults (`_SwitchDefaultsM3`, `_SliderDefaultsM3`, `_InputDecoratorDefaultsM3`), and `CircularProgressIndicator.valueColor` is `null` unless set explicitly — none of these is reachable through a public widget property, so Task 3 does not assert them. They read `primary`, `onSurfaceVariant`, `outline` and `surfaceContainerHighest`, every one of which Task 1 asserts directly from the palette. Ripple (`InkWell` splash) also reads `primary`, via `Material`'s defaults. `shadow` and `scrim` are left at Material's black defaults because no palette field is a truthful substitute; this is recorded in the mapping table rather than invented as a token.

**Known deviation, for the human partner.** The 0.2 luminance threshold is not the contrast-optimal crossover (≈0.179). On Amethyst, `onPrimary` is white over `#7C5CFF` = **4.33:1**, just under AA 4.5:1; black would give 4.85:1. The threshold lives in `PlayTorrioTokens.fromPalette` (phase-1, reviewed output, spec §11 calls the exact numbers the builder's call), so this plan does **not** change it — Task 2 asserts ≥ 4.0 and this line records why. Changing the threshold would flip `onAccent` on Amethyst app-wide and belongs in a separate, explicitly-approved change.

**Type consistency.** `_buildColorScheme(AppThemePalette, PlayTorrioTokens) -> ColorScheme` and `_onColor(Color) -> Color`; Task 3 consumes only standard `ColorScheme` getters (`surfaceContainerLow`, `inverseSurface`, `primary`, `surfaceElevatedColor` via `AppThemePalette`). `tokens.textSecondary`, `borderStrong`, `borderSubtle`, `textPrimary`, `error`, `onSurface`, `onAccent` all exist on `PlayTorrioTokens` as used.

**Proportion.** Three tasks, ~30 lines of implementation across one method pair, and three test files that between them pin 24 assertions. The plan is shorter than the code it describes.

---

## Ratified after implementation — do not relitigate

Executed inline on 2026-10-17: commits `16390a6`, `07adf92`, `4fa4cdc` (plus a `5ef603b` chore), pushed to `origin/main`. Every step ran as written except Task 3's test, where the brief's `const _home` was invalid Dart and became plain `_home`. Gate: `flutter analyze` 33 issues (0 errors, 0 warnings — the baseline); `test/theme` + `test/udl` + `test/widgets_ui` 167/167; full suite +442 −15 with the failing set exactly the pre-existing baseline. `fromSeed`: 0 hits.

The human partner then ran the app, reviewed the visible effect, and **explicitly ratified two changes that were offered as reversible**. Later phases inherit these:

- **Dividers stay faint.** `outlineVariant` = `tokens.borderSubtle` (6% white), down from the seed's `#48454E`. This is the broadest change in the phase (80 `Divider`/`VerticalDivider` uses across 35 files, mostly Settings). Accepted as the design language's separator strength — do **not** "restore" divider contrast when migrating Settings (phase 6).
- **Snackbars stay dark.** `inverseSurface` = `palette.surfaceElevatedColor` with `onInverseSurface` = `tokens.textPrimary`, so toasts went from near-white `#E6E1E9` to dark `#171A23` across 27 files. This deliberately gives up M3's inverse-surface convention (a light toast that stands out on a dark theme) so toasts belong to the palette. Do **not** re-add an override that returns them to near-white.

**Tooltips are unaffected**, measured A/B under the old and new schemes: both paint white @ 90% with black text, so Flutter 3.47 resolves the tooltip style from something other than `inverseSurface`. The 215 `Tooltip` / `tooltip:` usages need no follow-up from this phase.

**Still open — not decided, do not assume:**

- Amethyst `onPrimary` is white on `#7C5CFF` = **4.33:1**, just under AA. The fix is moving `PlayTorrioTokens.fromPalette`'s luminance threshold from 0.2 to ≈0.179, which flips `onAccent` app-wide. Offered and not accepted; see "Known deviation" above.
- `primaryContainer` recomputes `tokens.surfaceSelected`'s exact recipe (`alphaBlend(primaryColor@0.20, cardBackgroundColor)`) instead of referencing the token. Value-identical today.

**One stale line above:** the Self-Review's "Spec coverage" paragraph lists ProgressIndicator among Task 3's pinned widgets. The shipped test pins Dialog, BottomSheet and SnackBar plus a live palette recolour — not ProgressIndicator, because `CircularProgressIndicator.valueColor` is `null` by default, as the same section's "Not covered, deliberately" paragraph explains.
