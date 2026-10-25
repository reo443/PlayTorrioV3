# UDL Phase 3b — Shared Widgets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the six shared widgets that no later phase owns off inline colour literals — 160 of them across 6 files — onto `PlayTorrioTokens` / `AppSemanticColors` / `AppGlassColors` / `AppElevation`, with the three token-layer additions they need, and let three of the six adopt a shared primitive instead of restating chrome the library already owns.

**Architecture:** These six files are the cross-domain chrome the phase-3c/3d screens depend on: the home page and the movie slider use the sponsor promo, `search_page` embeds the magnet browser, the p2p and update dialogs are opened from home *and* settings, and the scroll track and flag icon are shared by anime/manga/books/IPTV/player. None of them belongs to a later phase, so migrating them first means phase 3c/3d screens do not inherit a partly-coloured widget. Five of the six are ordinary substitutions. The sixth, `support_dev_cards.dart`, is a deliberately gold-branded sponsor promo whose identity *is* its colour; it keeps its gold, but the ramp moves into the token layer as `AppSponsorColors` (the human partner's decision — see "Two ratified decisions" below).

**Tech Stack:** Flutter 3.47.6 / Dart 3.11, `flutter_test`, Material 3. No new packages.

**Spec:** `docs/superpowers/specs/2026-10-16-universal-design-language-design.md` §4 (anti-goals), §6.6 (token access), §6.7 (component vocabulary), §6.8 (compositing/glass/ColorScheme), §9 (migration method), §10 (definition of done), §13 (the fixed-colour allowlist). **That file is deleted from the working tree on purpose — read it with `git show 5ef603b^:docs/superpowers/specs/2026-10-16-universal-design-language-design.md` (353 lines).**

---

## Global Constraints

- **`flutter analyze` → 0 errors, 0 warnings, ≤33 infos** (the current baseline is exactly 33 issues). A new lint *info* violates this plan.
- **Behaviour preserved** — routes, callbacks, listeners, `Navigator` results, settings keys, and every value a caller reads. This is a colour/shape pass.
- **Colour is the deliverable; radii, spacing and type are not.** Do not normalise font sizes or `BorderRadius` values in these files, *except* where a primitive adoption replaces the control outright (then the primitive's own scale applies). Recorded here so the diff stays reviewable — a full §9.1 pass on these six files is a later, separate change.
- **Screens stay transparent (§6.8).** No file may paint an opaque `bgPrimary` as its own fill. `tokens.bgPrimary` appears in this phase only as a *scrim* or base stop inside a gradient that already sits under the ambient layer, plus one inset code block.
- **The token layer may gain exactly three things:** the new `lib/theme/app_sponsor_colors.dart`, one member (`wash`) on `AppGlassColors`, one enum value (`AppBadgeTone.accentSecondary`) on `AppChip`/`AppBadge`. Nothing else changes in `lib/theme/`.
- **`lib/services/theme/app_theme_service.dart` is not touched.** Phase 3a owns it; its 61 literals are the palette definitions.
- **The frozen contracts must keep passing unchanged:** everything in `test/theme/app_theme_service_tokens_test.dart` (primary/secondary/surface/onPrimary/brightness/useMaterial3/page transitions), `test/theme/explicit_colorscheme_test.dart`, `test/theme/builtin_widgets_theme_test.dart`, and the untracked `test/theme/app_theme_service_test.dart`.
- **`test/udl/no_inline_colors_test.dart`'s `migratedFiles` gains the six paths.** That guard is the machine check for this phase: it fails first with the file's literal count as its message, and passes when the migration is complete. **`Colors.transparent` is structural and is exempt** by the guard's own pattern — leave it.
- **Semantic colours are status colours, not fills.** Per the phase-2b precedent (`modern_toast`), `AppSemanticColors.*` colours icons, text, borders and status surfaces (a toast). A *button* takes an `AppButton` variant, never a semantic background with `Colors.black` ink — this design system has no on-semantic ink, and inventing one is out of scope.
- **No new dependencies. No secrets.**
- Commits land directly on `main`; `origin` only (`reo443/PlayTorrioV3`). **Never push to `upstream`.**
- The six files' line numbers below are **pre-edit** anchors. Anchor every edit on the code text, not the number — earlier edits in the same file shift later lines.

### Two ratified decisions this plan implements

Both were put to the human partner before this plan was written:

1. **The sponsor promo keeps its gold**, defined once in the token layer — rather than being recoloured by the palette (§4/§13's strict reading) or left exempt from the guard. Implemented as a **new `AppSponsorColors` class in `lib/theme/app_sponsor_colors.dart`**, not as extra members on `AppSemanticColors`: that class documents itself as "meaning the user must read the same way on every palette" (success/warning/rating/health/download/quality), and a sponsor's branding is not meaning. `app_settings_colors.dart` and `app_glass_colors.dart` are the existing precedent for a fixed, non-semantic group living in its own token-layer class. The observable outcome the partner chose — the gold stays, and it is defined once — is unchanged by the file it lives in.
2. **Dialogs:** `SupportDevHelper.showWhyDialog` becomes `showAppDialog` (it is a plain confirm/cancel dialog); `p2p_warning_dialog.dart` and `update_dialog.dart` keep their bespoke layouts and get token substitutions plus `AppButton` for their actions. The updater's *inner* "Download Complete" dialog is plain too, so it becomes an `AppDialog` shown via `showDialog` (it needs two arbitrary-callback actions, which `showAppDialog`'s confirm/cancel contract cannot express).

### The substitution vocabulary

160 literals must resolve the same way in six files, so these rules are the contract. The per-task tables apply them; where a table deviates it says why.

| Literal shape | Becomes |
|---|---|
| `Colors.white`, `Color(0xFFFFFFFF)` | `tokens.textPrimary` |
| white @ 0.88–0.95 (text) | `tokens.textPrimary` |
| white @ 0.75–0.8 (text) | `tokens.textPrimary.withValues(alpha: 0.75 / 0.8)` — outside 0.1 of every text role's alpha, so the exact alpha is kept (the phase-2b rule) |
| `Colors.white70`, white @ 0.55–0.70 (text) | `tokens.textSecondary` |
| white @ 0.40–0.54 (text) | `tokens.textTertiary` for a placeholder or de-emphasised affordance, otherwise `tokens.textSecondary` — called out per line |
| `Colors.white38`, white @ 0.25–0.38 (text) | `tokens.textTertiary` |
| border @ 0.05–0.09 | `tokens.borderSubtle` |
| border @ 0.10–0.22 | `tokens.borderStrong` |
| neutral translucent **fill** @ 0.04–0.09 | `AppGlassColors.wash` |
| fill that *is* a hover state | `AppGlassColors.fallbackHover.first` |
| glyph/label on glass @ 0.70 | `AppGlassColors.glyphMuted` |
| a neutral drop shadow | `AppElevation.shadowMd` |
| a glow around the accent | `AppElevation.glow(tokens.accent)` |
| accent surface / text / border | `tokens.accent` (+ `.withValues`) |
| `palette.primaryColor` | `tokens.accent` — the 16 phase-2b files read tokens only; `palette.primaryColor` is the same value, and `tokens.accent` is the extension §6.6 requires |
| success / warning / error status colour | `AppSemanticColors.success / warning / destructive` |
| the sponsor ramp (gold, ambers, brand darks) | `AppSponsorColors.*` |
| `#080A0F` (the palette's base colour, aliased inline) | `tokens.bgPrimary` |
| `Colors.transparent` | unchanged (structural) |

`AppSponsorColors.*` and `AppSemanticColors.*` are `const`, so surrounding `const` widget trees survive. `tokens.*` and `.withValues(...)` are **not** const — the tables name every line that must drop its `const`.

## Review Focus

These are the conditions a single-palette happy path does not exercise. Each has a test in the task that owns the code.

1. **The sponsor promo keeps its gold on a palette that would fake it.** Golden Amber (`amber`, accent `#F59E0B`) is warm enough that a palette-driven promo would look *plausible* there; only a cold palette exposes it. The test asserts **equality** across `amber` and `barbie`, not merely that two colours differ.
2. **The scroll thumb follows the palette.** It was the literal `#7C5CFF` — Amethyst's accent — so the test runs on `barbie`, where the old literal fails and the old code would have looked correct on Amethyst alone.
3. **A dialog's surface on a non-default palette.** `P2pWarningDialog` and `UpdateDialog` must resolve `tokens.surfaceElevated` on `barbie` as well as `amethyst`.
4. **Status colours do not follow the palette.** The p2p success toast and the updater's failure/warning toasts stay `AppSemanticColors.*` — *identical* under two palettes.
5. **Correct with effects off and animations disabled.** `CustomScrollTrack` and both dialogs are asserted under `disableAnimations: true`, and nothing in this phase reads a glass wrapper — `GlassSettings.enabled` defaults to false, so the flat path is the one that must be right.

---

## File Structure

| File | Action |
|---|---|
| `lib/theme/app_sponsor_colors.dart` | **create** — the promo's fixed ramp, 13 members |
| `lib/theme/app_glass_colors.dart` | modify — add `wash` (5% white neutral fill) |
| `lib/widgets/ui/app_chip.dart` | modify — add `AppBadgeTone.accentSecondary` + its `_toneColor` case |
| `lib/widgets/common/custom_scroll_track.dart` | modify — 8 literals |
| `lib/widgets/common/flag_icon.dart` | modify — 2 literals |
| `lib/widgets/search/magnet_files_view.dart` | modify — 35 literals + 4 primitive adoptions |
| `lib/widgets/p2p/p2p_warning_dialog.dart` | modify — 25 literals + `AppButton` |
| `lib/widgets/updater/update_dialog.dart` | modify — 31 literals + `AppButton`/`AppDialog` |
| `lib/widgets/home/support_dev_cards.dart` | modify — 59 literals + `showAppDialog` |
| `test/udl/no_inline_colors_test.dart` | modify — the six paths join `migratedFiles`, one task at a time |
| `test/theme/app_sponsor_colors_test.dart` | create — the frozen sponsor ramp |
| `test/widgets_ui/scroll_chrome_test.dart` | create — scroll track + flag icon |
| `test/widgets_ui/p2p_warning_dialog_test.dart` | create |
| `test/widgets_ui/update_dialog_test.dart` | create |
| `test/widgets_ui/sponsor_promo_test.dart` | create |
| `test/widgets_ui/app_chip_test.dart` | modify — the new tone |

---

### Task 1: The sponsor colour vocabulary

**Files:**
- Create: `lib/theme/app_sponsor_colors.dart`
- Test: `test/theme/app_sponsor_colors_test.dart`

**Interfaces:**
- Produces: `abstract final class AppSponsorColors` with `const` members `gold, goldLight, goldPale, amber, amberBright, amberDeep, amberHover, ink, ambientWarm, ambientViolet, cardWarm, cardViolet, cardBase`. Task 6 consumes it and nothing else does.
- Consumes: nothing.

- [ ] **Step 1: Write the failing test**

```dart
// test/theme/app_sponsor_colors_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_sponsor_colors.dart';

void main() {
  // The promo's whole identity is this ramp. Pinning it means a drift in the
  // gold has to be a deliberate edit with a failing test, not a side effect of
  // migrating a call site - which is exactly what the guard expects when the
  // values stop being inline.
  test('the sponsor brand ramp is frozen', () {
    expect(AppSponsorColors.gold, const Color(0xFFFFD700));
    expect(AppSponsorColors.goldLight, const Color(0xFFFFF2A1));
    expect(AppSponsorColors.goldPale, const Color(0xFFFFF0A6));
    expect(AppSponsorColors.amber, const Color(0xFFFFB300));
    expect(AppSponsorColors.amberBright, const Color(0xFFFFA000));
    expect(AppSponsorColors.amberDeep, const Color(0xFFFF8F00));
    expect(AppSponsorColors.amberHover, const Color(0xFFFF9100));
    expect(AppSponsorColors.ink, const Color(0xFF160F02));
    expect(AppSponsorColors.ambientWarm, const Color(0xFF2A1F0A));
    expect(AppSponsorColors.ambientViolet, const Color(0xFF140F1E));
    expect(AppSponsorColors.cardWarm, const Color(0xFF261A07));
    expect(AppSponsorColors.cardViolet, const Color(0xFF14101A));
    expect(AppSponsorColors.cardBase, const Color(0xFF0C0E14));
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/theme/app_sponsor_colors_test.dart`
Expected: compile failure — `app_sponsor_colors.dart` does not exist.

- [ ] **Step 3: Write the class**

Every member's doc comment says *where* it is used, so a later edit knows what it is about to change.

```dart
// lib/theme/app_sponsor_colors.dart
import 'package:flutter/widgets.dart';

/// The fixed colours of the "Support the Dev" sponsor promo.
///
/// The promo is a *branded* surface: its gold is the point of the card, and a
/// palette-driven version of it would read as a different advertisement on every
/// palette. Spec 13 therefore applies exactly as it does to [AppSettingsColors]
/// and [AppGlassColors] - the values are declared once, here, and the widgets
/// reference them instead of repeating literals inline.
///
/// These are deliberately **not** palette-derived, and the widget test that owns
/// the promo asserts that: the gold must be identical on every palette. If the
/// promo should ever follow the palette, that is a design change to this file's
/// contents, not a tweak at a call site.
abstract final class AppSponsorColors {
  /// The brand gold: icons, rims, the "SUPPORT THE DEV" pill, the "100% FREE"
  /// badge, and the card's heading gold.
  static const gold = Color(0xFFFFD700);

  /// Second stop of the hero title's gold gradient.
  static const goldLight = Color(0xFFFFF2A1);

  /// The slider card's italic heading - a touch warmer than [gold].
  static const goldPale = Color(0xFFFFF0A6);

  /// Call-to-action fill: the hero button, the card's CTA pill, its glow.
  static const amber = Color(0xFFFFB300);

  /// Fourth stop of the hero title's gold gradient.
  static const amberBright = Color(0xFFFFA000);

  /// Second stop of the CTA and pill gradients.
  static const amberDeep = Color(0xFFFF8F00);

  /// Hover end of the slider card's animated rim.
  static const amberHover = Color(0xFFFF9100);

  /// Text on an [amber] fill.
  static const ink = Color(0xFF160F02);

  /// First stop of the hero's radial ambience.
  static const ambientWarm = Color(0xFF2A1F0A);

  /// Second stop of the hero's radial ambience.
  static const ambientViolet = Color(0xFF140F1E);

  /// First stop of the slider card's poster gradient.
  static const cardWarm = Color(0xFF261A07);

  /// Second stop of the slider card's poster gradient.
  static const cardViolet = Color(0xFF14101A);

  /// Third stop of the slider card's poster gradient.
  static const cardBase = Color(0xFF0C0E14);
}
```

Note: `AppSettingsColors`/`AppGlassColors` are referenced in the doc comment but not imported — Dart resolves doc-comment references only when they are in scope, and plain text is fine here. Drop the square brackets if the analyzer reports dangling references.

- [ ] **Step 4: Run it and watch it pass**

Run: `flutter test test/theme/app_sponsor_colors_test.dart`
Expected: 1 test, all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/theme/app_sponsor_colors.dart test/theme/app_sponsor_colors_test.dart
git commit -m "feat(theme): give the sponsor promo a token-layer colour ramp"
```

---

### Task 2: Scroll track and flag icon (+ `AppGlassColors.wash`)

The two cheapest files, and the two whose literals are most load-bearing for other domains: `CustomScrollTrack` is used by anime, books, manga and IPTV pages, and `FlagIcon` by the player's subtitle menus.

**Files:**
- Modify: `lib/theme/app_glass_colors.dart`, `lib/widgets/common/custom_scroll_track.dart`, `lib/widgets/common/flag_icon.dart`, `test/udl/no_inline_colors_test.dart`
- Test: `test/widgets_ui/scroll_chrome_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens.of(context)`, `AppGlassColors.wash`, `AppElevation.glow`.
- Produces: `AppGlassColors.wash` (Task 3 consumes it); a literal-free `CustomScrollTrack`/`FlagIcon`; two more guard entries.

- [ ] **Step 1: Add the guard entries first, and watch the guard fail**

Add to `migratedFiles` in `test/udl/no_inline_colors_test.dart`:

```dart
  'lib/widgets/common/custom_scroll_track.dart',
  'lib/widgets/common/flag_icon.dart',
```

Run: `flutter test test/udl/no_inline_colors_test.dart`
Expected: FAIL — the reason lists the 10 offenders (`custom_scroll_track.dart:104`, `:106`, `:175`, `:190`, `:194`, `:236`, `:237`, `:241`, and `flag_icon.dart:208`, `:221`).

- [ ] **Step 2: Write the failing widget tests**

```dart
// test/widgets_ui/scroll_chrome_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/custom_scroll_track.dart';
import 'package:playtorrio/widgets/common/flag_icon.dart';

import 'host.dart';

AppThemePalette get _amethyst => AppThemeService.palettes.first;
AppThemePalette get _barbie =>
    AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');
PlayTorrioTokens _tokens(AppThemePalette p) => PlayTorrioTokens.fromPalette(p);

/// Every decoration colour inside the track, in tree order. The thumb is the
/// one that used to be the literal #7C5CFF.
List<Color?> _decorationColours(WidgetTester tester, Finder finder) => tester
    .widgetList<Container>(
      find.descendant(of: finder, matching: find.byType(Container)),
    )
    .map((c) => (c.decoration as BoxDecoration?)?.color)
    .toList();

void main() {
  testWidgets('the scroll thumb is the palette accent, not a fixed violet', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    // barbie, because the literal this replaces was amethyst's accent: on
    // amethyst the old code would pass this assertion by accident.
    await tester.pumpWidget(
      host(
        CustomScrollTrack(controller: controller),
        palette: _barbie,
        disableAnimations: true,
      ),
    );

    final colours = _decorationColours(tester, find.byType(CustomScrollTrack));
    expect(colours, contains(_tokens(_barbie).accent));
    expect(colours, isNot(contains(const Color(0xFF7C5CFF))));
  });

  testWidgets('the scroll track recolours with the palette', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      host(
        CustomScrollTrack(controller: controller),
        palette: _amethyst,
        disableAnimations: true,
      ),
    );
    final a = _decorationColours(tester, find.byType(CustomScrollTrack));

    await tester.pumpWidget(
      host(
        CustomScrollTrack(controller: controller),
        palette: _barbie,
        disableAnimations: true,
      ),
    );
    final b = _decorationColours(tester, find.byType(CustomScrollTrack));

    expect(a, isNot(b));
  });

  testWidgets('the flag fallback globe follows the palette', (tester) async {
    // An unknown language renders the placeholder globe rather than a network
    // image, which is the only branch that paints a colour of its own.
    await tester.pumpWidget(
      host(const FlagIcon(language: 'klingon'), palette: _amethyst),
    );
    final a = tester.widget<Icon>(find.byType(Icon)).color;

    await tester.pumpWidget(
      host(const FlagIcon(language: 'klingon'), palette: _barbie),
    );
    final b = tester.widget<Icon>(find.byType(Icon)).color;

    expect(a, isNot(b));
    expect(b, _tokens(_barbie).textTertiary);
  });
}
```

- [ ] **Step 3: Run them and watch them fail**

Run: `flutter test test/widgets_ui/scroll_chrome_test.dart`
Expected: FAIL — the thumb is `#7C5CFF` on every palette, and the globe is `#8AFFFFFF` (`Colors.white54`) on every palette.

- [ ] **Step 4: Add `AppGlassColors.wash`**

In `lib/theme/app_glass_colors.dart`, after `edge`:

```dart
  /// A faint neutral wash: translucent panels and de-emphasised chip fills,
  /// where the surface is neither a border nor a hover state.
  static const wash = Color(0x0DFFFFFF);
```

- [ ] **Step 5: Migrate `custom_scroll_track.dart`**

It is a hand-drawn glass surface (`BackdropFilter` over the ambient background), so its neutral values come from the glass class and its accent from the palette. Both state classes already have `context`, so no signatures change.

| Pre-edit line | Now | Becomes |
|---|---|---|
| 104 | `Colors.white.withValues(alpha: 0.05)` — panel fill | `AppGlassColors.wash` |
| 106 | `Colors.white.withValues(alpha: 0.12)` — panel rim | `tokens.borderStrong` |
| 175 | `Colors.white.withValues(alpha: 0.1)` — track groove | `tokens.borderStrong` |
| 190 | `const Color(0xFF7C5CFF)` — the drag thumb | `tokens.accent` |
| 192–198 | `BoxShadow(color: const Color(0xFF7C5CFF).withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)` | `AppElevation.glow(tokens.accent)` |
| 236 | hover `Colors.white.withValues(alpha: 0.15)` / rest `...alpha: 0.05` | `AppGlassColors.fallbackHover.first` / `AppGlassColors.wash` |
| 237 | `Colors.white.withValues(alpha: 0.1)` — arrow rim | `tokens.borderStrong` |
| 241 | `const Color(0xFF7C5CFF)` / `Colors.white70` | `tokens.accent` / `AppGlassColors.glyphMuted` |

`_buildTrackDragArea` has no `context` parameter but is a method of `_CustomScrollTrackState`, so it can read `PlayTorrioTokens.of(context)` directly — do **not** thread new parameters through `_buildVerticalLayout`/`_buildHorizontalLayout`. `_HoverArrowState.build(BuildContext context)` already has one. Add `import '../../theme/app_elevation.dart';`, `'../../theme/app_glass_colors.dart';`, `'../../theme/playtorrio_tokens.dart';` (the last is new — this file reads no tokens today).

The two intentional value changes: the panel rim and groove go 12%/10% → a single 12% white, and the thumb glow becomes `AppElevation.glow` (accent @ 0.28, blur 22) instead of accent @ 0.6, blur 12, spread 2 — the shared elevation vocabulary, at the cost of a tighter glow.

- [ ] **Step 6: Migrate `flag_icon.dart`**

| Pre-edit line | Now | Becomes |
|---|---|---|
| 208 | `Colors.white54` — the placeholder globe | `tokens.textTertiary` |
| 221 | `Colors.white54` — the `errorWidget` globe | `tokens.textTertiary` |

Both are inside `build(BuildContext context)`, so read `final tokens = PlayTorrioTokens.of(context);` once at its top. Neither `Icon` is in a `const` expression, so no `const` has to move. `textTertiary` (0.42) over the 0.54 it replaces: the globe is a *missing-flag placeholder*, which is the dimmest text role, not secondary text.

- [ ] **Step 7: Run the guard and the tests**

Run: `flutter test test/udl/no_inline_colors_test.dart test/widgets_ui/scroll_chrome_test.dart`
Expected: 3 widget tests pass; the guard passes for both new paths.

- [ ] **Step 8: Commit**

```bash
git add lib/theme/app_glass_colors.dart lib/widgets/common/custom_scroll_track.dart lib/widgets/common/flag_icon.dart test/udl/no_inline_colors_test.dart test/widgets_ui/scroll_chrome_test.dart
git commit -m "refactor(ui): move the scroll track and flag icon onto tokens"
```

---

### Task 3: Magnet file browser

35 literals and four primitive adoptions. `search_page.dart` embeds this widget, so 3c inherits it.

**Files:**
- Modify: `lib/widgets/search/magnet_files_view.dart`, `lib/widgets/ui/app_chip.dart`, `test/udl/no_inline_colors_test.dart`, `test/widgets_ui/app_chip_test.dart`
- Test: `test/widgets_ui/app_chip_test.dart` (extended)

**Interfaces:**
- Consumes: `PlayTorrioTokens`, `AppSemanticColors`, `AppGlassColors.wash`, `AppElevation.shadowMd`, `AppErrorState`, `AppEmptyState`, `AppChip`, `AppBadge` + the new `AppBadgeTone.accentSecondary`, `AppTextField`, `AppButton`.
- Produces: `AppBadgeTone.accentSecondary` (a category accent: "this source is a debrid cloud rather than the swarm").
- **No widget test for the view itself.** `initState` performs a real debrid/torrent lookup with no injectable seam, so driving it into its error or filtered state in a test would mean mocking the service. The task's automated check is therefore the guard entry plus the `AppBadgeTone` test below; the view's own states are verified visually in Task 7. This is a recorded gap, not an oversight.

- [ ] **Step 1: Add the guard entry and watch it fail**

```dart
  'lib/widgets/search/magnet_files_view.dart',
```

Run: `flutter test test/udl/no_inline_colors_test.dart`
Expected: FAIL listing all 35 offenders.

- [ ] **Step 2: Add the failing tone test**

Append inside the existing `main()` of `test/widgets_ui/app_chip_test.dart` (it already imports `host.dart` and the palette helpers — match the file's existing helper names rather than the ones below if they differ):

```dart
  testWidgets('the accentSecondary tone follows the palette', (tester) async {
    final barbie = AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');

    await tester.pumpWidget(
      host(
        const AppBadge(label: 'Debrid', tone: AppBadgeTone.accentSecondary),
        palette: AppThemeService.palettes.first,
      ),
    );
    final a = tester.widget<Text>(find.text('Debrid')).style?.color;

    await tester.pumpWidget(
      host(
        const AppBadge(label: 'Debrid', tone: AppBadgeTone.accentSecondary),
        palette: barbie,
      ),
    );
    final b = tester.widget<Text>(find.text('Debrid')).style?.color;

    expect(a, isNot(b));
    expect(b, PlayTorrioTokens.fromPalette(barbie).accentSecondary);
  });
```

Run: `flutter test test/widgets_ui/app_chip_test.dart`
Expected: FAIL — `AppBadgeTone.accentSecondary` is not defined.

- [ ] **Step 3: Add the tone**

In `lib/widgets/ui/app_chip.dart`: add `accentSecondary,` to the `AppBadgeTone` enum (after `accent`), and the matching arm to `_toneColor`:

```dart
    AppBadgeTone.accentSecondary => tokens.accentSecondary,
```

Update the enum's doc comment: it currently says everything except `neutral` and `accent` comes from the allowlist. `accentSecondary` is a palette role too — say so.

- [ ] **Step 4: Migrate `magnet_files_view.dart`**

**Structure changes (behaviour-preserving; called out because they are more than substitutions):**

- Delete the `ValueListenableBuilder<AppThemePalette>` wrapper in `build`. `PlayTorrioTokens.of(context)` registers a `Theme` dependency, so the widget still rebuilds when the palette changes (that is how every phase-2b file already works, and `theme_reactivity_test.dart` proves it); the wrapper was the *palette* read this plan is removing. Drop the `app_theme_service.dart` import if nothing else needs it.
- Replace the `AppThemePalette palette` parameter of `_buildTorrentHeaderCard`, `_buildFilterToolbar` and `_buildFileTile` with `PlayTorrioTokens tokens`. `tokens.accent == palette.primaryColor`, so every call site keeps its value.
- Delete `_buildCategoryChip` and `_buildBadge`, and their call sites.

**Substitutions:**

| Pre-edit line(s) | Now | Becomes |
|---|---|---|
| 270–322 loading branch — 280, 282, 287, 297 | `palette.primaryColor` @ 0.12 / 0.3 / 0.25 / 1.0 | `tokens.accent` with the same alphas |
| 305–309 | `Colors.white` title | `tokens.textPrimary` |
| 314–317 | `Colors.white.withValues(alpha: 0.5)` | `tokens.textTertiary` |
| 325–368 error branch | hand-rolled circle + title + message + `ElevatedButton.icon` | `Center(child: AppErrorState(title: 'Failed to Read Magnet', message: _errorMessage, onRetry: _loadMagnetFiles))` — kills 336, 337, 339, 344, 350, 356, 357 |
| 393–402 | `'No files match filter'` + `Colors.white.withValues(alpha: 0.4)` | `AppEmptyState(title: 'No files match the filter')` |
| 415 | `const Color(0xFF131722).withValues(alpha: 0.85)` | `tokens.surfaceElevated.withValues(alpha: 0.85)` |
| 418 | `palette.primaryColor.withValues(alpha: 0.3)` | `tokens.accent.withValues(alpha: 0.3)` |
| 421–427 | `BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 18, offset: Offset(0, 6))` | `AppElevation.shadowMd` |
| 437, 440 | `palette.primaryColor` @ 0.2 / 1.0 | `tokens.accent` with the same alphas |
| 452 | `Colors.white` | `tokens.textPrimary` |
| 464 | `Colors.white.withValues(alpha: 0.4)` — info hash | `tokens.textTertiary` |
| 482–486, 488–492, 494–498, 501–505 | four `_buildBadge(...)` calls | `AppBadge(label: ..., tone: ..., icon: ...)` — provider → `accentSecondary` (debrid) / `accent` (swarm), size and file count → `neutral`, video count → `accent` |
| 513–541 | `_buildBadge` helper | delete (its surface becomes `AppBadge`'s neutral surface, which is the badge's documented contract: "the surface stays the neutral theme surface so a wall of badges never becomes a wall of colour") |
| 547–566 | bordered container + raw `TextField` | `AppTextField(hintText: 'Filter files by name...', prefixIcon: Icons.filter_list_rounded, onChanged: (val) => setState(() => _searchFilter = val))` — kills 550, 552, 555, 559, 560 |
| 571–575 | three `_buildCategoryChip(...)` calls | `AppChip(label: ..., selected: _activeCategory == '<cat>', onTap: () => setState(() => _activeCategory = '<cat>'))` |
| 582–611 | `_buildCategoryChip` helper | delete — kills 590–592, 595–597, 606 |
| 620–622 | `const Color(0xFF161B26).withValues(alpha: 0.75)` / `const Color(0xFF10141C).withValues(alpha: 0.5)` | `tokens.surfaceElevated.withValues(alpha: 0.75)` / `tokens.surface.withValues(alpha: 0.5)` |
| 626–627 | `palette.primaryColor.withValues(alpha: 0.2)` / `Colors.white.withValues(alpha: 0.05)` | `tokens.accent.withValues(alpha: 0.2)` / `tokens.borderSubtle` |
| 638–640 | `palette.primaryColor.withValues(alpha: 0.15)` / `Colors.white.withValues(alpha: 0.05)` | `tokens.accent.withValues(alpha: 0.15)` / `AppGlassColors.wash` |
| 649 | `palette.primaryColor` / `Colors.white54` | `tokens.accent` / `tokens.textTertiary` |
| 665 | `Colors.white` / `Colors.white70` | `tokens.textPrimary` / `tokens.textSecondary` |
| 677 | `Colors.white.withValues(alpha: 0.08)` — extension tag fill | `AppGlassColors.wash` |
| 685 | `Colors.white70` | `tokens.textSecondary` |
| 695 | `Colors.white.withValues(alpha: 0.45)` | `tokens.textTertiary` |
| 707–724 | `ElevatedButton.icon` styled from `palette.primaryColor` | `AppButton(label: 'Play', icon: Icons.play_arrow_rounded, size: AppButtonSize.sm, onPressed: () => _playFile(file))` |
| 726–731 | `Colors.white.withValues(alpha: 0.25)` `'Non-video'` | `tokens.textTertiary` |

Two adopted-primitive visual changes to expect: the file rows' Play button becomes the standard `AppButton.sm`, and the metadata badges lose their tinted fill for `AppBadge`'s neutral surface with a toned label. Both are the component library's documented behaviour.

- [ ] **Step 5: Run everything this task touches**

Run: `flutter test test/udl/no_inline_colors_test.dart test/widgets_ui`
Expected: guard passes for the new path; `app_chip_test.dart`'s new case passes; no regressions in the other suites.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/search/magnet_files_view.dart lib/widgets/ui/app_chip.dart test/udl/no_inline_colors_test.dart test/widgets_ui/app_chip_test.dart
git commit -m "refactor(search): move the magnet browser onto tokens and shared primitives"
```

---

### Task 4: P2P warning dialog

**Files:**
- Modify: `lib/widgets/p2p/p2p_warning_dialog.dart`, `test/udl/no_inline_colors_test.dart`
- Test: `test/widgets_ui/p2p_warning_dialog_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens`, `AppSemanticColors`, `AppElevation.shadowMd`, `AppButton`.
- Produces: a literal-free `P2pWarningDialog` whose surface Task 7's spot check looks at.

- [ ] **Step 1: Add the guard entry and watch it fail**

```dart
  'lib/widgets/p2p/p2p_warning_dialog.dart',
```

Run: `flutter test test/udl/no_inline_colors_test.dart`
Expected: FAIL listing 25 offenders (22 `Colors.*`/`Color(0x…)` plus `_backgroundColor`, `_surfaceColor`, `_warningColor` declarations).

- [ ] **Step 2: Write the failing test**

```dart
// test/widgets_ui/p2p_warning_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/p2p/p2p_warning_dialog.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';

import 'host.dart';

AppThemePalette get _amethyst => AppThemeService.palettes.first;
AppThemePalette get _barbie =>
    AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');

void main() {
  testWidgets('the dialog surface is the palette elevated surface', (
    tester,
  ) async {
    Future<Color?> surfaceFor(AppThemePalette palette) async {
      await tester.pumpWidget(
        host(const P2pWarningDialog(), palette: palette),
      );
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(P2pWarningDialog),
              matching: find.byType(Container),
            )
            .first,
      );
      return (container.decoration as BoxDecoration?)?.color;
    }

    final a = await surfaceFor(_amethyst);
    final b = await surfaceFor(_barbie);

    expect(a, isNot(b));
    expect(b, PlayTorrioTokens.fromPalette(_barbie).surfaceElevated);
  });

  testWidgets('its three actions are shared buttons', (tester) async {
    await tester.pumpWidget(
      host(const P2pWarningDialog(), palette: _amethyst),
    );

    // "Yes, Turn Off P2P" is the emphasised action; the other two are the
    // escape hatches. A hand-rolled ElevatedButton/OutlinedButton/TextButton
    // mix would leave the dialog with three different button shapes.
    expect(find.byType(AppButton), findsNWidgets(3));
    expect(find.widgetWithText(AppButton, 'Yes, Turn Off P2P'), findsOneWidget);
    expect(find.widgetWithText(AppButton, "Don't Show Again"), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Exit'), findsOneWidget);
  });
}
```

Note: `P2pWarningDialog` picks its horizontal or stacked layout from `MediaQuery.sizeOf(context).width < 500`, and `host` centres the child in a 360-wide box by default — the **stacked** branch is the one that renders. Both branches contain the same three actions, so the assertions hold either way; if you want the horizontal branch, pass `width: 900` to `host` and re-run. Use `tester.pump()`, not `pumpAndSettle()`.

- [ ] **Step 3: Run it and watch it fail**

Run: `flutter test test/widgets_ui/p2p_warning_dialog_test.dart`
Expected: FAIL — the surface is `#131722` on both palettes, and there are zero `AppButton`s.

- [ ] **Step 4: Migrate the file**

Delete the three `static const Color` declarations (lines 7–9) and read the palette in `build`: `final tokens = PlayTorrioTokens.of(context);`.

| Pre-edit line(s) | Now | Becomes |
|---|---|---|
| 27 | `color: _surfaceColor` — the dialog body | `tokens.surfaceElevated` |
| 30, 35 | `_warningColor` @ 0.35 rim / 0.15 glow | `AppSemanticColors.warning.withValues(alpha: 0.35)` / `(alpha: 0.15)` |
| 39–43 | `BoxShadow(color: Colors.black.withValues(alpha: 0.70), blurRadius: 30, offset: Offset(0, 10))` | `AppElevation.shadowMd` |
| 57, 58 | `_warningColor` @ 0.22 / 0.04 — header banner gradient | `AppSemanticColors.warning.withValues(...)` |
| 65, 74, 77, 82, 99, 108, 181, 195, 198, 205 | `_warningColor` (badge fill, rims, icons, labels) | `AppSemanticColors.warning` with each line's existing alpha |
| 120 | `Colors.white` — sheet title | `tokens.textPrimary` |
| 128 | `Colors.white60` — close icon | `tokens.textSecondary` |
| 148 | `Colors.white.withValues(alpha: 0.88)` | `tokens.textPrimary` |
| 158 | `_backgroundColor.withValues(alpha: 0.7)` | `tokens.bgPrimary.withValues(alpha: 0.7)` |
| 161, 176, 244 | `Colors.white` @ 0.08 / 0.06 / 0.08 — rims | `tokens.borderSubtle` |
| 168 | `iconColor: const Color(0xFF10B981)` | `AppSemanticColors.success` |
| 215 | `Colors.white.withValues(alpha: 0.95)` | `tokens.textPrimary` |
| 228 | `Colors.white.withValues(alpha: 0.45)` | `tokens.textTertiary` |
| 241 | `_backgroundColor.withValues(alpha: 0.95)` | `tokens.bgPrimary.withValues(alpha: 0.95)` |
| 288 | `Colors.white` | `tokens.textPrimary` |
| 296 | `Colors.white.withValues(alpha: 0.55)` | `tokens.textSecondary` |
| 311–318 | `TextButton` + `foregroundColor: Colors.white60` | `AppButton(label: 'Exit', variant: AppButtonVariant.tertiary, onPressed: ...)` |
| 322–337 | `OutlinedButton` + rim @ 0.20 + `Colors.white70` | `AppButton(label: "Don't Show Again", variant: AppButtonVariant.secondary, onPressed: ...)` |
| 341–368 | `ElevatedButton.icon` @ `_warningColor` + `Colors.black` ink | `AppButton(label: 'Yes, Turn Off P2P', icon: Icons.check_circle_outline_rounded, onPressed: ...)` |
| 349, 387 | `backgroundColor: Color(0xFF10B981)` — success toast | `AppSemanticColors.success` |
| 379–406 | the stacked variant of the same three buttons | same three `AppButton`s, with `expand: true` on "Don't Show Again" (it sits in an `Expanded`) |
| 418, 419 | rim @ 0.20 + `Colors.white70` | absorbed by the `AppButton` above |
| 434 | `foregroundColor: Colors.white60` | absorbed by the tertiary `AppButton` |

Two deliberate consequences, both from the partner's "AppButton for their actions" decision: **"Yes, Turn Off P2P" becomes an accent-filled primary button instead of an amber one** — this design system has no on-warning ink, and a semantic fill with `Colors.black` text is exactly what the vocabulary table forbids — and the buttons lose their bespoke 12px radii and padding for the shared button's.

`_buildHorizontalButtons`/`_buildStackedButtons` already take a `BuildContext`, so they can read tokens directly; `_buildSourceInfoRow` receives its colours as parameters and needs no context.

- [ ] **Step 5: Run it**

Run: `flutter test test/widgets_ui/p2p_warning_dialog_test.dart test/udl/no_inline_colors_test.dart`
Expected: both pass.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/p2p/p2p_warning_dialog.dart test/udl/no_inline_colors_test.dart test/widgets_ui/p2p_warning_dialog_test.dart
git commit -m "refactor(p2p): move the P2P warning dialog onto tokens and AppButton"
```

---

### Task 5: Update dialog

**Files:**
- Modify: `lib/widgets/updater/update_dialog.dart`, `test/udl/no_inline_colors_test.dart`
- Test: `test/widgets_ui/update_dialog_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens`, `AppSemanticColors`, `AppElevation.glow`, `AppGlassColors.wash`, `AppButton`, `AppDialog`.
- Produces: a literal-free `UpdateDialog`. `main.dart:129`, `home_page.dart:108` and `updates_settings_page.dart:30` keep calling it unchanged.

- [ ] **Step 1: Add the guard entry and watch it fail**

```dart
  'lib/widgets/updater/update_dialog.dart',
```

Run: `flutter test test/udl/no_inline_colors_test.dart`
Expected: FAIL listing 31 offenders.

- [ ] **Step 2: Write the failing test**

```dart
// test/widgets_ui/update_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/services/updater/app_updater_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/updater/update_dialog.dart';

import 'host.dart';

UpdateInfo _info() => UpdateInfo(
  currentVersion: '3.0.0',
  latestVersion: '3.1.0',
  downloadUrl: 'https://example.invalid/playtorrio.apk',
  releaseNotes: 'Bug fixes',
  publishedAt: DateTime(2026, 1, 1),
  isMacOS: false,
);

void main() {
  testWidgets('the dialog body paints the palette elevated surface', (
    tester,
  ) async {
    final barbie = AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');

    await tester.pumpWidget(
      host(UpdateDialog(updateInfo: _info()), palette: barbie),
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(UpdateDialog),
            matching: find.byType(Container),
          )
          .first,
    );

    expect(
      (container.decoration as BoxDecoration?)?.color,
      PlayTorrioTokens.fromPalette(barbie).surfaceElevated,
    );
  });

  testWidgets('its two footer actions are shared buttons', (tester) async {
    await tester.pumpWidget(
      host(UpdateDialog(updateInfo: _info()), palette: AppThemeService.palettes.first),
    );

    expect(find.widgetWithText(AppButton, 'Later'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Update Now'), findsOneWidget);
  });
}
```

Run: `flutter test test/widgets_ui/update_dialog_test.dart`
Expected: FAIL — the body is `#12151E` (the deleted `_surfaceColor`) on every palette and there are no `AppButton`s. Use `tester.pump()`, never `pumpAndSettle()`.

- [ ] **Step 3: Migrate the file**

Delete the three `static const Color` declarations (26–28). `build` gets `final tokens = PlayTorrioTokens.of(context);`. The two download methods also reference `_accentColor`/`_surfaceColor`/`_backgroundColor`, and they run **after awaits** — read the tokens inside their existing `if (mounted)` blocks (the same guard that already lets them use `context`), so no `use_build_context_synchronously` info is added.

| Pre-edit line(s) | Now | Becomes |
|---|---|---|
| 46 | `backgroundColor: Colors.transparent` — the `Dialog` | unchanged (the inner `Container` paints the surface) |
| 50 | `color: _surfaceColor` | `tokens.surfaceElevated` |
| 52–55 | `_accentColor` @ 0.3 rim | `tokens.accent.withValues(alpha: 0.3)` |
| 56–62 | `BoxShadow(color: _accentColor @ 0.2, blurRadius: 40, spreadRadius: 5)` | `AppElevation.glow(tokens.accent)` |
| 71–76 | header gradient `_accentColor` @ 0.2 / 0.05 | `tokens.accent.withValues(alpha: 0.2)` / `(alpha: 0.05)` |
| 87, 92, 107, 279 | `_accentColor` (icon fills, icon, label) | `tokens.accent` (with each line's alpha at 87) |
| 116 | `Colors.white` | `tokens.textPrimary` |
| 136 | `Colors.white.withValues(alpha: 0.05)` — version panel | `AppGlassColors.wash` |
| 139, 217 | `Colors.white.withValues(alpha: 0.08)` — rims | `tokens.borderSubtle` |
| 152, 178, 206 | `Colors.white38` | `tokens.textTertiary` |
| 162, 225, 287, 339, 574, 597, 613 | `Colors.white70` | `tokens.textSecondary` |
| 237, 240 | `Colors.orange` @ 0.1 fill / 0.3 rim | `AppSemanticColors.warning.withValues(alpha: 0.1)` / `(alpha: 0.3)` |
| 247, 258 | `Colors.orange.shade300` / `.shade200` | `AppSemanticColors.warning` (one warning colour replaces two ad-hoc ambers) |
| 295–304 | `LinearProgressIndicator(backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(_accentColor))` | `backgroundColor: tokens.borderStrong`, `valueColor: AlwaysStoppedAnimation<Color>(tokens.accent)` — drop the `const` on the animation |
| 319–343 | `TextButton` "Later" + rim @ 0.15 | `AppButton(label: 'Later', variant: AppButtonVariant.secondary, expand: true, onPressed: ...)` |
| 345–370 | `ElevatedButton` "Update Now" + `Row(Text, Icon(download_rounded))` @ `_accentColor`/white | `AppButton(label: 'Update Now', trailingIcon: Icons.download_rounded, expand: true, onPressed: _handleUpdate)` |
| 443 | `backgroundColor: Colors.orange` — permission toast | `AppSemanticColors.warning` |
| 457, 475, 488 | `backgroundColor: Colors.redAccent` — failure toasts | `AppSemanticColors.destructive` |
| 554–626 | inner `AlertDialog` "Download Complete" (icon @ `Colors.green`, path box @ `_backgroundColor` @ 0.5, path text @ `_accentColor`, `TextButton` "Open Folder", `ElevatedButton` "OK") | `showDialog(context: context, builder: (_) => AppDialog(title: 'Download Complete', content: <see below>, actions: [AppButton(label: 'Open Folder', variant: AppButtonVariant.tertiary, onPressed: ...), AppButton(label: 'OK', onPressed: () => Navigator.of(context).pop())]))` |

The completion dialog's content keeps its parts and loses its literals:

```dart
content: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        const Icon(
          Icons.check_circle,
          color: AppSemanticColors.success,
          size: 28,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('Update downloaded.', style: AppTypography.supporting.copyWith(color: tokens.textPrimary)),
      ],
    ),
    const SizedBox(height: AppSpacing.md),
    Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tokens.bgPrimary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: SelectableText(
        filePath,
        style: AppTypography.supporting.copyWith(color: tokens.accent, fontFamily: 'monospace'),
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    Text(
      Platform.isWindows
          ? 'Close PlayTorrio and run the installer to update.'
          : 'Make the file executable and run it:\nchmod +x "$fileName"\n./$fileName',
      style: AppTypography.supporting.copyWith(color: tokens.textSecondary),
    ),
  ],
),
```

This is the one place in the phase that touches spacing/radius values, and only because the whole `AlertDialog` is being replaced by a primitive (the plan's Global Constraints allow that). Import `app_semantic_colors.dart`, `app_dialog.dart`, `app_spacing.dart`, `app_radii.dart`, `app_typography.dart`, `app_button.dart`, `app_glass_colors.dart`, `app_elevation.dart`, `playtorrio_tokens.dart` as needed.

- [ ] **Step 4: Run it**

Run: `flutter test test/widgets_ui/update_dialog_test.dart test/udl/no_inline_colors_test.dart`
Expected: both pass.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/updater/update_dialog.dart test/udl/no_inline_colors_test.dart test/widgets_ui/update_dialog_test.dart
git commit -m "refactor(updater): move the update dialog onto tokens, AppButton and AppDialog"
```

---

### Task 6: Sponsor promo

The largest file (712 lines) and the only one that keeps fixed colours. Task 1's ramp is its vocabulary.

**Files:**
- Modify: `lib/widgets/home/support_dev_cards.dart`, `test/udl/no_inline_colors_test.dart`
- Test: `test/widgets_ui/sponsor_promo_test.dart`

**Interfaces:**
- Consumes: `AppSponsorColors` (Task 1), `AppSemanticColors.destructive`, `tokens.bgPrimary` / `textPrimary` / `textSecondary` / `textTertiary` / `borderStrong`, `showAppDialog`.
- Produces: `SupportDevHelper.showWhyDialog(BuildContext)` changes from `static void` to `static Future<void>`. Its only call site is internal (`support_dev_cards.dart:401`); the external call at `support_dev_settings_page.dart:175` is `openSponsorLink`, which is unchanged. `SupportHeroSlide({required double screenWidth})` and `SupportSliderCard({required double cardWidth})` keep their signatures — `home_page.dart:785` and `movie_slider_section.dart:195` are untouched.

- [ ] **Step 1: Add the guard entry and watch it fail**

```dart
  'lib/widgets/home/support_dev_cards.dart',
```

Run: `flutter test test/udl/no_inline_colors_test.dart`
Expected: FAIL listing all 59 offenders.

- [ ] **Step 2: Write the failing test**

```dart
// test/widgets_ui/sponsor_promo_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_sponsor_colors.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/home/support_dev_cards.dart';

import 'host.dart';

AppThemePalette get _barbie =>
    AppThemeService.palettes.firstWhere((p) => p.id == 'barbie');
AppThemePalette get _amber =>
    AppThemeService.palettes.firstWhere((p) => p.id == 'amber');

void main() {
  // The promo is a branded surface: the ratified decision is that its gold is
  // fixed, not palette-derived. Asserted on Golden Amber - whose accent,
  // #F59E0B, is warm enough that a palette-driven promo would still look
  // plausible - AND on Pink Barbie, where it would obviously not.
  testWidgets('the promo keeps its gold on every palette', (tester) async {
    Future<Color?> badgeFor(AppThemePalette palette) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            height: 300,
            child: SupportSliderCard(cardWidth: 180),
          ),
          palette: palette,
          disableAnimations: true,
        ),
      );
      // Never pumpAndSettle here: the card's glow controller repeats forever.
      await tester.pump();
      return tester.widget<Text>(find.text('100% FREE')).style?.color;
    }

    final warm = await badgeFor(_amber);
    final cold = await badgeFor(_barbie);

    expect(warm, AppSponsorColors.gold);
    expect(cold, AppSponsorColors.gold);
    expect(warm, cold);
    // ...and specifically not the palette, which is what the old inline
    // literals would have been replaced by had the promo been "themed".
    expect(cold, isNot(PlayTorrioTokens.fromPalette(_barbie).accent));
  });

  testWidgets('the hero slide keeps its brand darks off the palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(width: 800, height: 400, child: SupportHeroSlide(screenWidth: 800)),
        palette: _barbie,
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(find.text('SUPPORT THE DEV • \$0 SUBSCRIPTION'), findsOneWidget);
    expect(
      tester
          .widget<Icon>(find.byIcon(Icons.diamond_rounded))
          .color
          ?.toARGB32(),
      isNot(PlayTorrioTokens.fromPalette(_barbie).accent.toARGB32()),
    );
  });
}
```

Both widgets read `HomePageSettings.heroStyle` / `cardHoverZoom`, which are synchronously-defaulted `ValueNotifier`s (`HeroStyle.immersive`, `1.08`) — no `SharedPreferences` setup is needed.

- [ ] **Step 3: Run it and watch it fail**

Run: `flutter test test/widgets_ui/sponsor_promo_test.dart`
Expected: FAIL — `AppSponsorColors` is referenced before any call site uses it, and the diamond's colour is the literal-derived `#59FFD700`.

- [ ] **Step 4: Replace `showWhyDialog` with `showAppDialog`**

```dart
  static Future<void> showWhyDialog(BuildContext context) async {
    final confirmed = await showAppDialog(
      context,
      title: 'Why 1 Click?',
      message:
          'PlayTorrio is completely free with zero subscriptions and zero paywalls.\n\n'
          'I build and maintain this project on my own. Tapping this opens 1 quick sponsor ad in your default browser — every click helps support me so I can keep developing PlayTorrio and pay for uni!\n\n'
          'Thank you so much for the support! ❤️',
      confirmLabel: 'Support Now',
      cancelLabel: 'Close',
    );
    if (confirmed == true && context.mounted) {
      await openSponsorLink(context);
    }
  }
```

This deletes the hand-rolled `AlertDialog` (lines 35–95). Consequences the partner accepted: the dialog loses its gold rim, its gold heart badge and its amber "Support Now" button for the shared dialog chrome, and the call site at line 401 becomes `onPressed: () => SupportDevHelper.showWhyDialog(context)` — an arrow body that discards the future, exactly as `openSponsorLink`'s call site already does.

- [ ] **Step 5: Migrate the rest of the file**

| Pre-edit line(s) | Now | Becomes |
|---|---|---|
| 27 | `Color(0xFFE50914)` — the "could not open browser" toast | `AppSemanticColors.destructive` |
| 38, 41, 48, 51, 57, 69, 77, 87, 88 | the why-dialog's chrome, gold badge and amber button | deleted with the `AlertDialog` above |
| 148 | `Color(0xFF2A1F0A)` | `AppSponsorColors.ambientWarm` |
| 149 | `Color(0xFF140F1E)` | `AppSponsorColors.ambientViolet` |
| 150 | `Color(0xFF080A0F)` | `tokens.bgPrimary` |
| 179, 189, 267, 272, 280, 287 | `Color(0xFFFFD700)` at 0.6 / 0.35 / 0.45 / 0.25 / 1.0 / 1.0 | `AppSponsorColors.gold` with each line's alpha |
| 180 | `Color(0xFFFF8F00).withValues(alpha: 0.2)` | `AppSponsorColors.amberDeep.withValues(alpha: 0.2)` |
| 181, 210, 228 | `Colors.transparent` — gradient tails | unchanged |
| 208, 209 | `Color(0xFF080A0F)` @ 0.95 / 0.75 — the left readability wash | `tokens.bgPrimary.withValues(alpha: 0.95 / 0.75)` |
| 226, 227 | `Color(0xFF080A0F)` / `@0.85` — the bottom wash | `tokens.bgPrimary` / `tokens.bgPrimary.withValues(alpha: 0.85)` |
| 261 | `Color(0x38FFD700)` — pill gradient start (alpha 0x38 = 0.2196) | `AppSponsorColors.gold.withValues(alpha: 0.22)` |
| 262 | `Color(0x1FFF8F00)` — pill gradient end (0x1F = 0.1216) | `AppSponsorColors.amberDeep.withValues(alpha: 0.12)` |
| 305 | `Color(0xFFFFFFFF)` — title gradient start | `tokens.textPrimary` |
| 306, 307, 308 | `Color(0xFFFFF2A1)` / `gold` / `Color(0xFFFFA000)` | `AppSponsorColors.goldLight` / `.gold` / `.amberBright` |
| 322, 691 | `Colors.white` | `tokens.textPrimary` |
| 340, 405, 412 | `Colors.white` @ 0.75 / 0.8 / 0.8 | `tokens.textPrimary.withValues(alpha: 0.75 / 0.8)` |
| 364 | `Color(0xFFFFB300)` @ `0.45 + pulse * 0.25` | `AppSponsorColors.amber.withValues(alpha: 0.45 + (_pulseController.value * 0.25))` |
| 385, 386 | `Color(0xFFFFB300)` / `Color(0xFF160F02)` — hero CTA | `AppSponsorColors.amber` / `.ink` |
| 424 | `Colors.white.withValues(alpha: 0.22)` — outlined CTA rim | `tokens.borderStrong` |
| 523, 524, 525 | `Color(0xFF261A07)` / `Color(0xFF14101A)` / `Color(0xFF0C0E14)` — card poster gradient | `AppSponsorColors.cardWarm` / `.cardViolet` / `.cardBase` |
| 530, 531 | `gold @ 0.5` / `Color(0xFFFF9100) @ 0.8` — animated rim lerp | `AppSponsorColors.gold.withValues(alpha: 0.5)` / `AppSponsorColors.amberHover.withValues(alpha: 0.8)` |
| 538 | `Color(0xFFFFB300)` @ `glowOpacity` | `AppSponsorColors.amber.withValues(alpha: glowOpacity)` |
| 560, 575, 578, 607, 609 | `Color(0xFFFFD700)` @ 0.15 / 0.2 / 0.4 / 0.12 / 0.25 | `AppSponsorColors.gold` with each line's alpha |
| 584, 591, 614 | `Color(0xFFFFD700)` — badge bolt, badge label, heart | `AppSponsorColors.gold` |
| 630 | `Color(0xFFFFF0A6)` — card heading | `AppSponsorColors.goldPale` |
| 639 | `Colors.white70` | `tokens.textSecondary` |
| 653 | `[Color(0xFFFFB300), Color(0xFFFF8F00)]` — CTA gradient | `[AppSponsorColors.amber, AppSponsorColors.amberDeep]` |
| 658 | `Color(0xFFFFB300).withValues(alpha: 0.4)` | `AppSponsorColors.amber.withValues(alpha: 0.4)` |
| 669 | `Color(0xFF160F02)` — CTA label | `AppSponsorColors.ink` |
| 700 | `Color(0xFFFFD700).withValues(alpha: 0.8)` | `AppSponsorColors.gold.withValues(alpha: 0.8)` |

**`const` that must move** (everything else in this file keeps it, because the brand members are `const`): line 143's `BoxDecoration` (its third stop is `tokens.bgPrimary`), line 259's `LinearGradient` and line 301's `shaderCallback` gradient (both use `.withValues`), line 305's gradient (uses `tokens.textPrimary`), and line 686's `const Text` (uses `tokens.textPrimary`). Add imports: `../../theme/app_sponsor_colors.dart`, `../../theme/app_semantic_colors.dart`, `../../theme/playtorrio_tokens.dart`, `../ui/app_dialog.dart`.

- [ ] **Step 6: Run it**

Run: `flutter test test/widgets_ui/sponsor_promo_test.dart test/udl/no_inline_colors_test.dart`
Expected: both pass — the promo is gold on `amber` *and* `barbie`.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/home/support_dev_cards.dart test/udl/no_inline_colors_test.dart test/widgets_ui/sponsor_promo_test.dart
git commit -m "refactor(home): move the sponsor promo onto a fixed brand ramp"
```

---

### Task 7: Verification and hand-off

**Files:**
- No source changes unless a gate fails.

- [ ] **Step 1: The literal count actually reached zero**

```powershell
foreach ($f in @('lib/widgets/common/custom_scroll_track.dart','lib/widgets/common/flag_icon.dart','lib/widgets/search/magnet_files_view.dart','lib/widgets/p2p/p2p_warning_dialog.dart','lib/widgets/updater/update_dialog.dart','lib/widgets/home/support_dev_cards.dart')) {
  $hits = (Select-String -Path $f -Pattern 'Color\(0x|(?<![A-Za-z0-9_])Colors\.(?!transparent)' -CaseSensitive).Count
  "{0,-58} {1}" -f $f, $hits
}
```

Expected: `0` for all six. Any non-zero is a literal the guard also sees — fix it before continuing.

- [ ] **Step 2: Analyze**

```bash
flutter analyze
```

Expected: **33 issues, 0 errors, 0 warnings** — byte-for-byte the pre-phase baseline. A new issue is a regression in this phase (most likely an unused import from a deleted helper, or a `use_build_context_synchronously` from reading tokens outside a `mounted` guard).

- [ ] **Step 3: The three suites this phase owns**

```bash
flutter test test/udl test/widgets_ui test/theme
```

Expected: no failures on any path under `test/udl`, `test/widgets_ui` or `test/theme`. (The count moves up; do not gate on a fixed total — live-network tests flake.)

- [ ] **Step 4: The full suite**

```bash
flutter test
```

Expected: **no new failures.** The pre-existing failure set is exactly 15 tests in 7 files — `test/models/my_list_item_test.dart` (5, `uniqueKey`), `test/download_service_test.dart` (1), `test/widgets/anime_search_page_test.dart` (1), `test/chunk1_vyla_test.dart` (4), `test/chunk2_anime_vyla_test.dart` (2), `test/anime_extractors_test.dart` (1), `test/audio_language_detector_test.dart` (1). Nothing this phase touches is in that list. Gate on **which** tests fail, never on the pass total (it drifts run to run).

- [ ] **Step 5: The guard's own report**

```bash
flutter test test/udl/no_inline_colors_test.dart
```

Expected: pass, with `migratedFiles` now holding 22 paths. Confirm `lib/services/theme/app_theme_service.dart` is still **not** in the list.

- [ ] **Step 6: Visual spot check on Windows**

```bash
flutter run -d windows
```

Then walk the five Review Focus conditions with the eye, switching palettes in **Settings → Appearance**:

1. Home → the "Support the Dev" hero slide and the in-feed sponsor card stay **gold**, on every palette, including Golden Amber and Pink Barbie.
2. Anime/books/manga/IPTV pages → the scroll track's thumb and arrow icons take the palette's accent, and the track is still legible at rest and on hover.
3. The player's subtitle menu → the flag fallback globe reads as a muted placeholder, not a bright icon.
4. Search → a magnet result: the file rows' Play button and the metadata badges match the rest of the app; the filter field and chips look like every other search field and chip.
5. Home/settings → the P2P warning dialog and the update dialog sit on the palette's elevated surface, and their buttons match the app's other buttons.
6. With glass effects **disabled** (the default) all of the above still renders completely — no missing fill, no invisible rim.

- [ ] **Step 7: Self-review against the plan's structure**

Before reporting, re-read the six files' diffs and check: no behaviour changed (routes, callbacks, `Navigator.pop` results, the p2p settings writes, the updater's `dismissVersion` calls, the magnet URL launches); no literal was "fixed" by inventing a token; the three token-layer additions are the only ones; and every item in the pre-edit line tables above is accounted for.

- [ ] **Step 8: Report**

```bash
git log --oneline -7
git diff --stat 5ef603b..HEAD -- lib/theme lib/widgets
```

Report to the human partner: the six files and their literal counts before/after; the three token-layer additions; the five primitive adoptions (magnet's error/empty state, search field, chips, badges, p2p/update buttons, two dialogs); the deliberate visual changes (the p2p "Turn Off P2P" button loses its amber fill; the scroll thumb's glow narrows; the badge fills go neutral; the "Why 1 Click?" dialog loses its gold rim and heart badge); the recorded gaps (no widget test for the magnet view's own states; `radii`/type normalisation in these files deferred); and the remaining app-wide literal count.

---

## Self-Review

**Spec coverage.**

- §4 "no hardcoded colours for special screens" → the sponsor promo is the one place that could have violated this; it is resolved by §13's mechanism (fixed values declared once in the token layer) rather than by a new exception, and Task 1's test pins the ramp.
- §6.6 "colour always comes from the extension" → the last `AppThemePalette` reads in widget code (`palette.primaryColor` in the magnet browser, `AppThemeService.currentPalette`'s builder) are removed; the 16 phase-2b files already read tokens only.
- §6.7 component vocabulary → `AppButton`, `AppBadge`, `AppChip`, `AppTextField`, `AppEmptyState`, `AppErrorState`, `AppDialog` are all adopted where a hand-rolled equivalent existed; nothing new is invented.
- §6.8 compositing/glass/ColorScheme → no file paints an opaque `bgPrimary` as a fill; the glass surface's values come from `AppGlassColors`; the two bespoke dialogs now *read* the 3a `ColorScheme`'s surface by using `tokens.surfaceElevated` rather than a private constant.
- §9 "replace inline colours, keep behaviour, prefer the shared component" → the whole plan.
- §10 definition of done → Task 7's gates are its first four bullets; the palette spot check is its fifth.
- §13 allowlist → `AppSemanticColors` is used for status, `AppSponsorColors`/`AppGlassColors` for the two fixed non-semantic groups, and the guard enforces that nothing else remains.

**Placeholder scan.** No `TODO`, no "add tests later", no "similar to Task N" elision: every one of the 160 literals appears in a per-file table with its replacement, and every `const` that must move is named. The one deliberate non-test (the magnet view's own states) is recorded with its reason in Task 3, and the one deferred concern (radii/type) is in the Global Constraints.

**Type consistency.** `PlayTorrioTokens.of(context)` returns the extension (never `.fromPalette` in widget code — that is only for tests); `AppButtonVariant`, `AppButtonSize`, `AppBadgeTone` are used with the enum names `app_button.dart`/`app_chip.dart` actually declare; `AppDialog`'s constructor takes `title/message/content/actions` (not the `showAppDialog` factory's `confirmLabel`), and the plan uses each in the place it fits; `AppGlassColors.wash` is introduced in Task 2 and consumed in Tasks 2, 3 and 5, always with that exact name; `AppSponsorColors`'s thirteen member names are identical in Task 1's class, Task 1's test and Task 6's table.

**Two known risks.** (1) `AppErrorState`/`AppEmptyState`/`AppBadge`/`AppChip`/`AppButton` substitutions in the magnet browser change the look of a screen with no widget test, so Task 7's step 6 is the only thing that can catch a bad fit; if the file rows end up worse, the fallback is to keep the hand-rolled row and pass it token colours (the guard is satisfied either way). (2) Removing the magnet browser's `ValueListenableBuilder` assumes `PlayTorrioTokens.of(context)` re-resolves on a palette switch in the *real* app — true by construction (`main.dart` rebuilds `MaterialApp` on a new palette, and the phase-2b components depend on exactly that) but only proven for the primitives in `theme_reactivity_test.dart`; Task 7 step 6.4 is the check.

**Proportion.** Seven tasks, ~160 literal substitutions, ~10 primitive adoptions, 3 token-layer additions, 5 new/extended test files. The two files with bespoke chrome keep it; the four that restate chrome the library owns stop doing so.
