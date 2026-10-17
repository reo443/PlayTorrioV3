# UDL Phase 2b-C2 — Settings Controls & Dock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take `settings_controls.dart` and `liquid_dock.dart` off hardcoded colours, giving both a single home for the fixed colours they legitimately need.

**Architecture:** Neither file is palette-tinted. `SettingsText` is a palette-independent grey type ramp declared as `const` styles (which cannot read per-context tokens), and the dock's colours are the glass material (white light refracted through a surface, plus a drop shadow). Both are §13 "fixed colours": they must read the same on every palette, so they move into the token layer — once — rather than becoming palette-derived. `app_liquid_dock.dart` already has zero colour literals and needs no change.

**Tech Stack:** Flutter 3.x / Dart 3.11, `flutter_test`. No new packages.

---

## Global Constraints

- **Public APIs frozen.** `SettingsText`, `SettingsSegmentedControl`, `SettingsToggleSwitch`, `SettingsToggleRow`, `DockItem` and `LiquidDock` keep their signatures.
- **`flutter analyze` → 0 errors, 0 warnings, 33 infos** (the baseline).
- **Zero failures under `test/udl` and `test/widgets_ui`.**
- **No inline colour literals** in the two files — Task 3 extends the guard.
- **User decision (this batch):** settings greys and glass colours stay **fixed**, defined once in the token layer. Palette-derived settings text (an API change that edits settings screens, phase 6) is deliberately **not** done. Only `liquid_dock.dart` is migrated out of the glass layer; `glass_settings.dart`, `performance_liquid_lens.dart` and `player_glass.dart` follow in a later batch.

### Substitution rules

`settings_controls.dart`:

| Today | Becomes |
|---|---|
| `Color(0xFF7E7E8C)` / `0xFFF2F2F5` / `0xFF8C8C98` / `0xFF9D9DAA` | `AppSettingsColors.{sectionLabel,title,description,inactive}` |
| `AppThemeService.currentPalette.value.primaryColor` (×2) | `PlayTorrioTokens.of(context).accent` |
| `Material(color: Colors.transparent)` (×2) | `Material(type: MaterialType.transparency)` |
| `BorderRadius.circular(999)` (×2) | `AppRadii.roundedChip` |
| `color: isSelected ? accent : Colors.transparent` | `color: isSelected ? accent : null` — a null fill paints nothing, so the track's wash still shows through |
| `Colors.white` (selected segment label, on the accent fill) | `tokens.onAccent` |
| `Colors.white.withValues(alpha: 0.05)` (track fill) | `tokens.textPrimary.withValues(alpha: 0.05)` |
| `Colors.white.withValues(alpha: 0.14)` (track border) | `tokens.borderStrong` |
| `Colors.white.withValues(alpha: 0.08)` (disabled track) | `tokens.textPrimary.withValues(alpha: 0.08)` |
| `Colors.white.withValues(alpha: 0.15)` (off track) | `tokens.textPrimary.withValues(alpha: 0.15)` |
| `Colors.white` (switch thumb) | `tokens.textPrimary` — **not** `onAccent`: the thumb must stay light when the switch is off (the off track is a dark wash), so it cannot follow the accent's contrast colour |

`liquid_dock.dart` (values are moved verbatim — **zero** visual change):

| Today | Becomes |
|---|---|
| `Colors.white70` ×2 (scroll arrows) | `AppGlassColors.glyphMuted` |
| `Color(0x66000000)` (shadow) | `AppGlassColors.shadow` |
| `Color(0x24FFFFFF)` (rim) | `AppGlassColors.edge` |
| `Color(0xF2FFFFFF)` (item glyph) | `AppGlassColors.glyph` |
| `[Color(0x38FFFFFF), Color(0x1FFFFFFF)]` | `AppGlassColors.fallbackHover` |
| `[Color(0x24FFFFFF), Color(0x12FFFFFF)]` | `AppGlassColors.fallbackRest` |
| `Color(0x26FFFFFF)` | `AppGlassColors.fallbackBorder` |

### Deliberate visible deltas

1. **The selected settings segment's label moves from `Colors.white` to `tokens.onAccent`.** `onAccent` is `black` when the accent's relative luminance exceeds 0.2 — which is true of 6 of the 8 built-in palettes (Cyberpunk Neon, Emerald Aurora, Sunset Crimson, Midnight Sapphire, Golden Amber, Pink Barbie). So on those, the selected segment's text becomes black. This matches what `AppButton.primary` already does with the same accent, and it is a contrast fix (black on `#FF2A85` is ~6.2:1, white is ~3.4:1). It is the one change in this batch worth vetoing; reverting it is a one-line change to `tokens.textPrimary`.
2. Switch thumb `Colors.white` → `tokens.textPrimary` (`white@0.95`) — imperceptible.
3. Track alphas keep their exact values except the hairline border, `0.14` → `borderStrong` `0.12` — imperceptible.

## File Structure

| File | Action |
|---|---|
| `lib/theme/app_settings_colors.dart` | create — the fixed settings type ramp |
| `lib/theme/app_glass_colors.dart` | create — the fixed glass material palette |
| `lib/widgets/settings/settings_controls.dart` | modify (0 literals) |
| `lib/widgets/common/liquid_dock.dart` | modify (0 literals) |
| `test/udl/settings_controls_test.dart` | create |
| `test/udl/liquid_dock_test.dart` | create |
| `test/udl/no_inline_colors_test.dart` | modify (add both paths) |

---

### Task 1: Settings controls

**Files:** Create `lib/theme/app_settings_colors.dart`; Modify `lib/widgets/settings/settings_controls.dart`; Test `test/udl/settings_controls_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/settings_controls_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_settings_colors.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/settings/settings_controls.dart';

import '../widgets_ui/host.dart';

PlayTorrioTokens _tokensOf(AppThemePalette palette) =>
    PlayTorrioTokens.fromPalette(palette);

/// The decoration of the widget's outermost [Container].
BoxDecoration _track(WidgetTester tester) =>
    tester.widget<Container>(find.byType(Container).first).decoration!
        as BoxDecoration;

void main() {
  testWidgets('the settings type ramp keeps its fixed greys', (tester) async {
    await tester.pumpWidget(
      host(
        SettingsToggleRow(
          label: 'Autoplay',
          description: 'Play the next episode',
          value: true,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Autoplay')).style?.color,
      AppSettingsColors.title,
    );
    expect(
      tester.widget<Text>(find.text('Play the next episode')).style?.color,
      AppSettingsColors.description,
    );
    // Pinned to the literals: this ramp is palette-independent by design, so a
    // change here must be a deliberate restyle rather than a palette side effect.
    expect(AppSettingsColors.title, const Color(0xFFF2F2F5));
    expect(AppSettingsColors.inactive, const Color(0xFF9D9DAA));
  });

  testWidgets('the type ramp does not follow the palette', (tester) async {
    for (final palette in [
      AppThemeService.palettes.first,
      AppThemeService.palettes.last,
    ]) {
      await tester.pumpWidget(
        host(
          SettingsToggleRow(label: 'Autoplay', value: true, onChanged: (_) {}),
          palette: palette,
        ),
      );

      expect(
        tester.widget<Text>(find.text('Autoplay')).style?.color,
        AppSettingsColors.title,
      );
    }
  });

  testWidgets('the selected segment fills with the accent and uses onAccent', (
    tester,
  ) async {
    final tokens = _tokensOf(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(
        SettingsSegmentedControl<String>(
          values: const ['system', 'light', 'dark'],
          selected: 'dark',
          label: (v) => v,
          onChanged: (_) {},
        ),
      ),
    );

    // The selected pill is filled with the palette accent.
    final fills = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color)
        .toList();
    expect(fills, contains(tokens.accent));

    expect(
      tester.widget<Text>(find.text('dark')).style?.color,
      tokens.onAccent,
    );
    expect(
      tester.widget<Text>(find.text('system')).style?.color,
      AppSettingsColors.inactive,
    );
    // The track keeps a subtle wash so the unselected options stay legible.
    expect(
      _track(tester).color,
      tokens.textPrimary.withValues(alpha: 0.05),
    );
    expect(_track(tester).border?.top.color, tokens.borderStrong);
  });

  testWidgets('the segmented control reports the tapped value', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      host(
        SettingsSegmentedControl<String>(
          values: const ['system', 'light'],
          selected: 'system',
          label: (v) => v,
          onChanged: (v) => picked = v,
        ),
      ),
    );

    await tester.tap(find.text('light'));
    expect(picked, 'light');
  });

  testWidgets('the switch track and thumb come from the tokens', (
    tester,
  ) async {
    final tokens = _tokensOf(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(SettingsToggleSwitch(value: true, onChanged: (_) {})),
    );

    // Exactly two implicit containers: the track, then the thumb.
    final boxes = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => c.decoration! as BoxDecoration)
        .toList();
    expect(boxes, hasLength(2));
    expect(boxes.first.color, tokens.accent);
    expect(boxes.last.color, tokens.textPrimary);
  });

  testWidgets('the off switch uses the wash, not the accent', (tester) async {
    final tokens = _tokensOf(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(SettingsToggleSwitch(value: false, onChanged: (_) {})),
    );

    final track = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .first
        .decoration! as BoxDecoration;
    expect(track.color, tokens.textPrimary.withValues(alpha: 0.15));
    expect(track.color, isNot(tokens.accent));
  });

  testWidgets('tapping the switch reports the flipped value', (tester) async {
    bool? reported;
    await tester.pumpWidget(
      host(SettingsToggleSwitch(value: true, onChanged: (v) => reported = v)),
    );

    await tester.tap(find.byType(SettingsToggleSwitch));
    await tester.pumpAndSettle();

    expect(reported, isFalse);
  });

  testWidgets('a disabled switch does not report', (tester) async {
    await tester.pumpWidget(host(SettingsToggleSwitch(value: true, onChanged: null)));

    await tester.tap(find.byType(SettingsToggleSwitch));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/udl/settings_controls_test.dart` → FAIL: `AppSettingsColors` does not exist, and the segment label is `Colors.white`.

- [ ] **Step 3: Create `lib/theme/app_settings_colors.dart`** with the four literals moved verbatim, documented as palette-independent-by-design per spec 13.

- [ ] **Step 4: Apply the substitution table to `settings_controls.dart`** — the four `SettingsText` styles reference `AppSettingsColors`; both `primaryColor` reads become `PlayTorrioTokens.of(context).accent` (dropping the now-unused `app_theme_service` import); `Colors.transparent` becomes `MaterialType.transparency` (Material) or a `null` fill (decoration); the segmented label becomes `tokens.onAccent`; the remaining washes and the pill radius become tokens and `AppRadii.roundedChip`.

- [ ] **Step 5: Run to verify it passes** — PASS (8/8).

- [ ] **Step 6: Commit** — `refactor(udl): move the settings type ramp and controls onto tokens`

---

### Task 2: Liquid dock

**Files:** Create `lib/theme/app_glass_colors.dart`; Modify `lib/widgets/common/liquid_dock.dart`; Test `test/udl/liquid_dock_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/liquid_dock_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_glass_colors.dart';
import 'package:playtorrio/widgets/common/liquid_dock.dart';

import '../widgets_ui/host.dart';

List<DockItem> _items(int count) => [
  for (var i = 0; i < count; i++)
    DockItem(
      icon: i == 0 ? Icons.home_rounded : Icons.podcasts_rounded,
      label: 'Item $i',
      onTap: () {},
    ),
];

Future<void> _pump(WidgetTester tester, {int items = 2, double width = 360}) =>
    tester.pumpWidget(
      host(
        SizedBox(height: 140, child: LiquidDock(items: _items(items))),
        width: width,
      ),
    );

void main() {
  testWidgets('the glass palette is pinned to its fixed literals', (tester) async {
    // Glass is white light; these must not drift with a palette.
    expect(AppGlassColors.shadow, const Color(0x66000000));
    expect(AppGlassColors.glyph, const Color(0xF2FFFFFF));
    expect(AppGlassColors.glyphMuted, const Color(0xB3FFFFFF));
    expect(AppGlassColors.edge, const Color(0x24FFFFFF));
    expect(AppGlassColors.fallbackRest, const [Color(0x24FFFFFF), Color(0x12FFFFFF)]);
    expect(AppGlassColors.fallbackHover, const [Color(0x38FFFFFF), Color(0x1FFFFFFF)]);
    expect(AppGlassColors.fallbackBorder, const Color(0x26FFFFFF));
  });

  testWidgets('the dock renders with glass effects disabled', (tester) async {
    await _pump(tester);

    expect(find.byType(LiquidDock), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the non-glass tiles use the glass palette', (tester) async {
    await _pump(tester);

    // The tiles are the containers carrying both a gradient and a border;
    // the lens' own fallback surface has a gradient but no border.
    final tiles = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.gradient is LinearGradient && d.border != null)
        .toList();
    expect(tiles, hasLength(2));

    expect((tiles.first.gradient! as LinearGradient).colors, AppGlassColors.fallbackRest);
    expect(tiles.first.border, Border.all(color: AppGlassColors.fallbackBorder));

    // The glyph is the glass glyph colour, not a literal.
    expect(
      tester.widget<Icon>(find.byIcon(Icons.home_rounded)).color,
      AppGlassColors.glyph,
    );
  });

  testWidgets('the dock casts its shadow from the glass palette', (tester) async {
    await _pump(tester);

    final shadows = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .expand((d) => d.boxShadow ?? const <BoxShadow>[])
        .map((s) => s.color)
        .toList();

    expect(shadows, contains(AppGlassColors.shadow));
  });

  testWidgets('the scroll arrows use the muted glass glyph colour', (
    tester,
  ) async {
    // 12 items overflow the available width, so the arrows appear.
    await _pump(tester, items: 12);

    expect(
      tester.widget<Icon>(find.byIcon(Icons.chevron_left_rounded)).color,
      AppGlassColors.glyphMuted,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.chevron_right_rounded)).color,
      AppGlassColors.glyphMuted,
    );
  });

  testWidgets('the tiles do not follow the palette', (tester) async {
    await _pump(tester);

    final tile = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.gradient is LinearGradient && d.border != null);

    expect(
      (tile.gradient! as LinearGradient).colors,
      AppGlassColors.fallbackRest,
    );
    expect(tile.color, isNull);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — FAIL: `AppGlassColors` does not exist.

- [ ] **Step 3: Create `lib/theme/app_glass_colors.dart`** with the seven literals moved verbatim, documented as the glass material palette.

- [ ] **Step 4: Apply the substitution table to `liquid_dock.dart`.** The values are moved unchanged, so this is a pure de-duplication with no visual delta.

- [ ] **Step 5: Run to verify it passes** — PASS (6/6).

- [ ] **Step 6: Commit** — `refactor(udl): give the glass material one home and adopt it in LiquidDock`

---

### Task 3: Extend the colour guard

**Files:** Modify `test/udl/no_inline_colors_test.dart`

- [ ] **Step 1: Add both paths** to `migratedFiles`:

```dart
  'lib/widgets/settings/settings_controls.dart',
  'lib/widgets/common/liquid_dock.dart',
```

- [ ] **Step 2: Run** — `flutter test test/udl/no_inline_colors_test.dart` → PASS (2/2).

- [ ] **Step 3: Commit** — `test(udl): extend the inline-colour guard to the settings controls and dock`

---

## Verification

- [ ] `flutter analyze` → 0 errors, 0 warnings, ≤33 infos.
- [ ] `flutter test test/udl test/widgets_ui` → all pass.
- [ ] `flutter test` → the pre-existing network/model failures only (recorded in the batch report); none under `test/udl` or `test/widgets_ui`.
- [ ] Re-scan all 16 migrated files independently for `Color(0x` / `Colors.`.

## Self-Review

- **Not adopted:** `AppChip`/`AppButton` have no counterpart here — a switch and a segmented track are neither. `AppTextField` is not used; there is no text input.
- **Spec coverage:** §13 — the two new files are the single home for these fixed colours, and the guard now covers both consumers. §6.8 — unaffected: `SettingsToggleRow` is a row, and the dock is an overlay, not a screen background.
- **Deferred:** `glass_settings.dart` (8), `performance_liquid_lens.dart` (1) and `player_glass.dart` (2) still hold inline glass literals; they now have an obvious home in `AppGlassColors`. Settings text stays palette-independent until the phase-6 settings screens decide otherwise.
- **Typing:** `MaterialType.transparency`, `AppRadii.roundedChip`, `tokens.onAccent`, `tokens.textPrimary`, `tokens.borderStrong`, `LinearGradient.colors`, `BoxDecoration.border`/`boxShadow` all exist as used.
