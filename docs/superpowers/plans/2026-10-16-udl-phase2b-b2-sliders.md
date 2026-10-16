# UDL Phase 2b-B2 — The Two Sliders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete the duplicated scroll-arrow, tokenise the shared `SliderArrow`, and take `movie_slider_section` and `continue_watching_slider` off hardcoded colours.

**Architecture:** `movie_slider_section.dart:249-329` holds a private `_SliderArrow` that is a byte-for-byte duplicate of `lib/widgets/common/slider_arrow.dart` — which seven other files already import. The duplicate is deleted and the shared widget is used; the shared widget is then tokenised so all nine call sites benefit at once. Everything else is the same colour migration as batch A and B1.

**Tech Stack:** Flutter 3.x / Dart 3.11, `flutter_test`. No new packages.

---

## Global Constraints

- **Public APIs frozen.** `SliderArrow`, `MovieSliderSection`, `ContinueWatchingSlider` keep every parameter. `_SliderArrow` and `_ContinueWatchingCard.palette` are private and may be removed.
- **`flutter analyze` → 0 errors, 0 warnings.** Info count may fall: `slider_arrow.dart` is migrated off the deprecated `withOpacity`, so if any of the 33 baseline infos are that deprecation, the count drops. That is an improvement, not a regression — report the number, don't force it back.
- **Zero failures under `test/udl` and `test/widgets_ui`.**
- **No inline colour literals** in the three files — Task 4 extends the guard.
- Components must stay correct with glass disabled; nothing here paints a full-screen background.

## Colour substitution rules (same as batch A / B1)

| Today | Becomes |
|---|---|
| `palette.primaryColor` / `palette.accentColor` | `tokens.accent` / `tokens.accentSecondary` |
| `Color(0xFF080A0F)` | `tokens.bgPrimary` |
| `Color(0xFF13151F)` (card body) | `tokens.surface` |
| `Color(0xFF1E212E)`, `Color(0xFF1A1D27)` (thumbnail/placeholder) | `tokens.surfaceElevated` |
| `Color(0xFF00E5FF)` (torrent glyph) | `AppSemanticColors.downloadActive` |
| `Color(0xFF10B981)` (stream glyph) | `AppSemanticColors.success` |
| `Colors.white` / `Colors.white24` | `tokens.textPrimary` / `tokens.textTertiary` |
| `Colors.white.withValues(alpha: 0.55 … 0.62)` (secondary text) | `tokens.textSecondary` |
| `Colors.white.withValues(alpha: 0.08)` (resting border) | `tokens.borderSubtle` |
| `Colors.white.withValues(alpha: 0.12)` (border) | `tokens.borderStrong` |
| any other `Colors.white.withValues(alpha: x)` | `tokens.textPrimary.withValues(alpha: x)` |
| any `Colors.black.withValues(alpha: x)` | `tokens.bgPrimary.withValues(alpha: x)` |

Alphas that no token role matches closely are **preserved exactly** on `textPrimary`/`bgPrimary` rather than snapped to a role — this keeps the visual churn of B2 to the minimum while still making every colour palette-derived.

## File Structure

| File | Action |
|---|---|
| `lib/widgets/common/slider_arrow.dart` | modify (tokenise, `withOpacity` → `withValues`) |
| `lib/widgets/movie/movie_slider_section.dart` | modify (delete `_SliderArrow`, use the shared one, tokenise) |
| `lib/widgets/home/continue_watching_slider.dart` | modify (tokenise, drop the `palette` param) |
| `test/udl/slider_arrow_test.dart` | create |
| `test/udl/movie_slider_section_test.dart` | create |
| `test/udl/continue_watching_slider_test.dart` | create |
| `test/udl/no_inline_colors_test.dart` | modify (add the three paths) |

---

### Task 1: `SliderArrow`

**Files:** Modify `lib/widgets/common/slider_arrow.dart`; Test `test/udl/slider_arrow_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/slider_arrow_test.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/slider_arrow.dart';

import '../widgets_ui/host.dart';

Widget _arrow({VoidCallback? onTap}) => Center(
  child: SliderArrow(icon: Icons.arrow_forward_ios_rounded, onTap: onTap ?? () {}),
);

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(of: find.byType(SliderArrow), matching: find.byType(AnimatedContainer)),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('resting fill and border come from the tokens', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_arrow()));

    final decoration = _decoration(tester);
    expect(decoration.color, tokens.bgPrimary.withValues(alpha: 0.5));
    expect((decoration.border! as Border).top.color, tokens.textPrimary.withValues(alpha: 0.1));
  });

  testWidgets('hover lifts the fill and border', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_arrow()));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(SliderArrow)));
    await tester.pumpAndSettle();

    final decoration = _decoration(tester);
    expect(decoration.color, tokens.textPrimary.withValues(alpha: 0.15));
    expect((decoration.border! as Border).top.color, tokens.textPrimary.withValues(alpha: 0.3));
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('resting fill follows the selected palette', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(host(_arrow(), palette: last));

    expect(
      _decoration(tester).color,
      PlayTorrioTokens.fromPalette(last).bgPrimary.withValues(alpha: 0.5),
    );
    expect(
      _decoration(tester).color,
      isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).bgPrimary.withValues(alpha: 0.5)),
    );
  });

  testWidgets('tap fires the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_arrow(onTap: () => taps++)));

    await tester.tap(find.byType(SliderArrow));
    await tester.pump();

    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/udl/slider_arrow_test.dart` → FAIL: fill is `0xFF080A0F` and the palette test can't differ.

- [ ] **Step 3: Apply the substitution rules**, migrating `withOpacity` to `withValues` at the same time and adding `import '../../theme/playtorrio_tokens.dart';`. Read `final tokens = PlayTorrioTokens.of(context);` at the top of `build`.

- [ ] **Step 4: Run to verify it passes** — PASS (4/4).

- [ ] **Step 5: Commit** — `git commit -m "refactor(udl): drive SliderArrow from tokens"`

---

### Task 2: `MovieSliderSection`

**Files:** Modify `lib/widgets/movie/movie_slider_section.dart`; Test `test/udl/movie_slider_section_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/movie_slider_section_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/movie/movie.dart';
import 'package:playtorrio/models/movie/movie_section.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/slider_arrow.dart';
import 'package:playtorrio/widgets/movie/movie_slider_section.dart';

import '../widgets_ui/host.dart';

MovieSection _section() => MovieSection(
  title: 'Popular',
  subtitle: 'Trending now',
  contentType: 'movie',
  addonBaseUrl: '',
  catalog: 'top',
  movies: [
    Movie(id: 'tt1', name: 'Dune', type: 'movie', addonBaseUrl: '', year: '2021'),
    Movie(id: 'tt2', name: 'Arrival', type: 'movie', addonBaseUrl: '', year: '2016'),
  ],
);

/// The desktop-only arrows are the proof the private duplicate is gone: they
/// only render as the shared [SliderArrow].
void _useDesktop() {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
}

void main() {
  testWidgets('the slider uses the shared SliderArrow, not a private copy', (tester) async {
    _useDesktop();
    await tester.pumpWidget(host(MovieSliderSection(section: _section())));

    expect(find.byType(SliderArrow), findsNWidgets(2));
  });

  testWidgets('the calendar chip takes its icon from the palette accent', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(
      host(
        MovieSliderSection(section: _section(), showCalendarButton: true),
        palette: last,
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.calendar_month_rounded));
    expect(icon.color, PlayTorrioTokens.fromPalette(last).accent);
    expect(icon.color, isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).accent));
  });

  testWidgets('renders the section title and its cards', (tester) async {
    await tester.pumpWidget(host(MovieSliderSection(section: _section())));

    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — FAIL: `SliderArrow` finds 0 (the private `_SliderArrow` renders instead).

- [ ] **Step 3: Delete `_SliderArrow` and `_SliderArrowState` (lines 249-329)**, add `import '../common/slider_arrow.dart';`, replace both `_SliderArrow(` call sites with `SliderArrow(`, and apply the substitution rules to the calendar chip (`Colors.white.withValues(alpha: 0.08)` → `tokens.textPrimary.withValues(alpha: 0.08)`, border 0.12 → `tokens.borderStrong`, `AppThemeService.currentPalette.value.primaryColor` → `tokens.accent`, `Colors.white` text → `tokens.textPrimary`). Remove the now-unused `dart:ui` and `AppThemeService` imports.

- [ ] **Step 4: Run to verify it passes** — PASS (3/3).

- [ ] **Step 5: Commit** — `git commit -m "refactor(udl): delete the duplicated slider arrow and tokenise the section"`

---

### Task 3: `ContinueWatchingSlider`

**Files:** Modify `lib/widgets/home/continue_watching_slider.dart`; Test `test/udl/continue_watching_slider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/continue_watching_slider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/continue_watching/continue_watching_item.dart';
import 'package:playtorrio/services/continue_watching/continue_watching_service.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/home/continue_watching_slider.dart';

import '../widgets_ui/host.dart';

ContinueWatchingItem _item() => ContinueWatchingItem(
  id: 'tt1',
  title: 'Dune',
  type: 'movie',
  year: '2021',
  positionSeconds: 600,
  totalDurationSeconds: 1200,
  lastWatchedAt: DateTime(2026, 1, 1),
  isTorrent: false,
  addonName: 'Stream',
);

void _withItems(List<ContinueWatchingItem> items) {
  final previous = ContinueWatchingService.activeItems.value;
  ContinueWatchingService.activeItems.value = items;
  addTearDown(() => ContinueWatchingService.activeItems.value = previous);
}

/// The accent bar is the only 4x18 container in the header.
BoxDecoration _accentBar(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere((c) => c.constraints?.maxWidth == 4 && c.constraints?.maxHeight == 18);
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('renders nothing when there is nothing to continue', (tester) async {
    _withItems(const []);
    await tester.pumpWidget(host(const ContinueWatchingSlider()));

    expect(find.text('Continue Watching'), findsNothing);
  });

  testWidgets('the accent bar uses the palette accent', (tester) async {
    final last = AppThemeService.palettes.last;
    _withItems([_item()]);
    await tester.pumpWidget(host(const ContinueWatchingSlider(), palette: last));

    expect(_accentBar(tester).color, PlayTorrioTokens.fromPalette(last).accent);
    expect(
      _accentBar(tester).color,
      isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).accent),
    );
  });

  testWidgets('renders the title, count and card', (tester) async {
    _withItems([_item()]);
    await tester.pumpWidget(host(const ContinueWatchingSlider()));

    expect(find.text('Continue Watching'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card body uses a token surface', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    _withItems([_item()]);
    await tester.pumpWidget(host(const ContinueWatchingSlider()));

    final card = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, tokens.surface.withValues(alpha: 0.75));
    expect((decoration.border! as Border).top.color, tokens.borderSubtle);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — FAIL: the accent bar is `0xFF7C5CFF` and the card body is `0xFF13151F`.

- [ ] **Step 3: Apply the substitution rules.** `_ContinueWatchingCard` loses its `palette` field and constructor argument; `_ContinueWatchingSliderState.build` loses `final palette = AppThemeService.currentPalette.value;` and the `palette: palette,` argument; `_ContinueWatchingCard.build` and `_buildPlaceholder` read `PlayTorrioTokens.of(context)` (so `_buildPlaceholder` gains a `BuildContext`). Remove the `AppThemeService` import.

- [ ] **Step 4: Run to verify it passes** — PASS (4/4).

- [ ] **Step 5: Commit** — `git commit -m "refactor(udl): drive ContinueWatchingSlider from tokens"`

---

### Task 4: Extend the colour guard

**Files:** Modify `test/udl/no_inline_colors_test.dart`

- [ ] **Step 1: Add the three paths** to `migratedFiles`:

```dart
  'lib/widgets/common/slider_arrow.dart',
  'lib/widgets/movie/movie_slider_section.dart',
  'lib/widgets/home/continue_watching_slider.dart',
```

- [ ] **Step 2: Run** — `flutter test test/udl/no_inline_colors_test.dart` → PASS (2/2).

- [ ] **Step 3: Commit** — `git commit -m "test(udl): extend the inline-colour guard to the sliders"`

---

## Verification

- [ ] `flutter analyze` → 0 errors, 0 warnings.
- [ ] `flutter test test/udl test/widgets_ui` → all pass.
- [ ] `flutter test` → failures unchanged from the pre-existing live-network set; none under `test/udl` or `test/widgets_ui`.
- [ ] `grep -c "_SliderArrow" lib/widgets/movie/movie_slider_section.dart` → 0.

## Self-Review

- **Duplication:** the private arrow is deleted, so nine call sites now share one widget.
- **Deliberate visible delta:** the torrent glyph goes cyan `0xFF00E5FF` → `AppSemanticColors.downloadActive` (blue), because the allowlist has no cyan and the glyph means "download".
- **Deferred:** `movie_slider_section` and `continue_watching_slider` still build their own section headers instead of using `SectionHeader`; their headers differ (accent bar + count pill vs. title/subtitle/See-All), so unifying them is a design decision, not a colour migration.
