# UDL Phase 2b-C1 — The Two Sheets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take `filter_option_sheet` and `advanced_filter_sheet` off hardcoded colours, and give them the phase-2a primitives they should already be using (`AppSearchField`, `AppChip`, `AppButton`).

**Architecture:** Both sheets are *bodies* that `discover_page.dart` hands to `showModalBottomSheet`, so they build their own chrome. `AppSheet` is therefore **not** adopted here — `AppSheet.show` owns the `showModalBottomSheet` call, so adopting it means changing the caller, which belongs to the phase-3 discover-page migration. What changes instead: every literal becomes a token, and the leaf controls become primitives.

**Tech Stack:** Flutter 3.x / Dart 3.11, `flutter_test`. No new packages.

---

## Global Constraints

- **Public APIs frozen.** `FilterOptionSheet<T>`, its `accent` parameter, `AdvancedFilterSheet` and all its methods keep their signatures. Private helpers (`_chip`, `_selector`, `_yearField`, `_buildActionBar`) may change.
- **`flutter analyze` → 0 errors, 0 warnings, 33 infos** (or fewer).
- **Zero failures under `test/udl` and `test/widgets_ui`.**
- **No inline colour literals** in the two files — Task 3 extends the guard.
- **Adopt a primitive only where it can express what the code already does; otherwise tokenise and record the gap.**

### Primitive adoption policy (applied, and why)

| Candidate | Decision |
|---|---|
| `AppSheet` | **Not adopted.** It owns the `showModalBottomSheet` call; these widgets are the sheet's body. Adopting it would double the chrome and requires a caller change (phase 3). |
| `AppSearchField` (filter option sheet) | **Adopted.** It is exactly a search input with a clear affordance. |
| `AppChip` (advanced sheet's `_chip`) | **Adopted.** `AppChip` signals selection by surface + border + semantics; today's `_chip` signals it by colour alone, which the design explicitly rejects. |
| `AppButton` (action bar) | **Adopted.** `AppButton` has `expand` and `loading`, which the raw `FilledButton` was hand-rolling. |
| `AppTextField` (year fields) | **Not adopted.** It expresses "invalid" through `errorText`; these fields express it through a red border. Adoption would change the affordance. Also needs `inputFormatters`, which `AppTextField` does not expose. Tokenised instead. |
| `_selector` (language/country rows) | **No primitive expresses it** — a full-width form control with a trailing chevron. Tokenised. |

### Colour substitution rules (same as batch A / B1 / B2)

| Today | Becomes |
|---|---|
| `palette.cardBackgroundColor` / `palette.primaryColor` | `tokens.surface` / `tokens.accent` |
| `Colors.white` (primary text) | `tokens.textPrimary` |
| `Colors.white.withValues(alpha: 0.55 … 0.75)`, `Colors.white70`, `Colors.white54` | `tokens.textSecondary` (0.62) |
| `Colors.white.withValues(alpha: 0.35 … 0.42)`, `Colors.white38`, `Colors.white24` | `tokens.textTertiary` |
| `Colors.white.withValues(alpha: 0.2)` (drag handle) | `tokens.borderStrong` |
| `Colors.white.withValues(alpha: 0.1)` (input border) | `tokens.borderSubtle` — matches `AppTextField`'s own precedent |
| `Colors.white.withValues(alpha: 0.06)` (divider / hairline) | `tokens.borderSubtle` (verified identical) |
| `Colors.white.withValues(alpha: 0.08)` (sheet hairline) | `tokens.borderSubtle` |
| `Colors.white.withValues(alpha: 0.12)` (slider track) | `tokens.borderStrong` (verified identical) |
| `Colors.white.withValues(alpha: 0.05)` (input fill) | `tokens.textPrimary.withValues(alpha: 0.05)` — a translucent white wash, not a surface |
| `Colors.redAccent` (year validation) | `AppSemanticColors.error` |
| `BorderRadius.vertical(top: Radius.circular(24))` | `BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))` |

Text alphas snap to the nearest role when within 0.1; otherwise the alpha is kept exactly on `textPrimary`.

**Deliberate visible deltas (3):** filter chips are restyled by `AppChip` (selected = tinted surface + accent label, not an accent fill with white text); the action bar's buttons become `AppButton` (filled/outlined become primary/secondary surfaces); the year-validation red moves from `redAccent` `0xFFFF5252` to `AppSemanticColors.error` `0xFFE5484D`.

## File Structure

| File | Action |
|---|---|
| `lib/widgets/discover/filter_option_sheet.dart` | modify (tokens + `AppSearchField`) |
| `lib/widgets/discover/advanced_filter_sheet.dart` | modify (tokens + `AppChip`/`AppButton`/`AppRadii.sheet`) |
| `test/udl/filter_option_sheet_test.dart` | create |
| `test/udl/advanced_filter_sheet_test.dart` | create |
| `test/udl/no_inline_colors_test.dart` | modify (add the two paths) |

---

### Task 1: `FilterOptionSheet`

**Files:** Modify `lib/widgets/discover/filter_option_sheet.dart`; Test `test/udl/filter_option_sheet_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/filter_option_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/discover/filter_option_sheet.dart';
import 'package:playtorrio/widgets/ui/app_text_field.dart';

import '../widgets_ui/host.dart';

const _options = [
  (value: 'a', label: 'Action'),
  (value: 'c', label: 'Comedy'),
];

String? _picked;

Widget _sheet({
  String? selected,
  bool searchable = false,
  Color? accent,
}) => FilterOptionSheet<String>(
  title: 'Genre',
  options: _options,
  selected: selected,
  accent: accent ?? PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).accent,
  searchable: searchable,
  onSelected: (v) => _picked = v,
);

/// The title's resolved colour.
Color? _titleColor(WidgetTester tester) =>
    tester.widget<Text>(find.text('Genre')).style?.color;

void main() {
  setUp(() => _picked = null);

  testWidgets('title and tiles take their colours from the tokens', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_sheet()));

    expect(_titleColor(tester), tokens.textPrimary);
    final tile = tester.widget<Text>(find.text('Comedy'));
    expect(tile.style?.color, tokens.textPrimary);
  });

  testWidgets('the selected tile is coloured by the accent', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(
      host(
        _sheet(selected: 'a', accent: PlayTorrioTokens.fromPalette(last).accent),
      ),
    );

    final tile = tester.widget<Text>(find.text('Action'));
    expect(tile.style?.color, PlayTorrioTokens.fromPalette(last).accent);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('tapping a tile reports the value and "Any" reports null', (tester) async {
    await tester.pumpWidget(host(_sheet()));

    await tester.tap(find.text('Comedy'));
    expect(_picked, 'c');
    await tester.tap(find.text('Any'));
    expect(_picked, isNull);
  });

  testWidgets('a searchable sheet filters through AppSearchField', (tester) async {
    await tester.pumpWidget(host(_sheet(searchable: true)));

    expect(find.byType(AppSearchField), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'com');
    await tester.pump();

    expect(find.text('Comedy'), findsOneWidget);
    expect(find.text('Action'), findsNothing);
  });

  testWidgets('clearing the search restores the full list', (tester) async {
    await tester.pumpWidget(host(_sheet(searchable: true)));

    await tester.enterText(find.byType(TextField), 'com');
    await tester.pump();
    expect(find.text('Action'), findsNothing);

    // The clear affordance lives in AppSearchField and must re-fire onChanged —
    // otherwise the list would stay filtered behind an empty field.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(find.text('Action'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/udl/filter_option_sheet_test.dart` → FAIL: no `AppSearchField`, and the tile colour is `Colors.white`.

- [ ] **Step 3: Apply the changes.** Add `PlayTorrioTokens`, `AppSearchField` and a `TextEditingController` (disposed in `dispose`), replacing the whole raw `TextField` + `InputDecoration` block:

```dart
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: AppSearchField(
                  controller: _searchController,
                  hintText: 'Search...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
```

and tokenise the remaining literals: the handle (0.2 → `tokens.borderStrong`), the title (`Colors.white` → `tokens.textPrimary`), and `_tile`'s `selected ? widget.accent : Colors.white` → `selected ? widget.accent : tokens.textPrimary` (so `_tile` takes a `PlayTorrioTokens`).

- [ ] **Step 4: Run to verify it passes** — PASS (5/5).

- [ ] **Step 5: Commit** — `git commit -m "refactor(udl): drive FilterOptionSheet from tokens and AppSearchField"`

---

### Task 2: `AdvancedFilterSheet`

**Files:** Modify `lib/widgets/discover/advanced_filter_sheet.dart`; Test `test/udl/advanced_filter_sheet_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/advanced_filter_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/discover/discover_filter_state.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/discover/advanced_filter_sheet.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/ui/app_chip.dart';

import '../widgets_ui/host.dart';

Widget _sheet() => AdvancedFilterSheet(
  mediaType: 'movie',
  initial: DiscoverFilterState.empty,
  countResults: (_) async => 7,
);

/// Pumps the sheet, then disposes it so its 450ms count debounce is cancelled
/// rather than tripping the pending-timer check.
Future<void> _pumpSheet(WidgetTester tester, {AppThemePalette? palette}) async {
  await tester.pumpWidget(host(_sheet(), palette: palette, width: 500));
  await tester.pump();
  addTearDown(() => tester.pumpWidget(const SizedBox()));
}

void main() {
  testWidgets('the action bar is built from AppButton', (tester) async {
    await _pumpSheet(tester);

    final labels = tester
        .widgetList<AppButton>(find.byType(AppButton))
        .map((b) => b.label)
        .toList();
    expect(labels, containsAll(<String>['Reset all', 'Show results']));

    final show = tester
        .widgetList<AppButton>(find.byType(AppButton))
        .firstWhere((b) => b.label.startsWith('Show'));
    expect(show.variant, AppButtonVariant.primary);
    expect(show.expand, isTrue);
  });

  testWidgets('the apply button is disabled while the year range is invalid', (tester) async {
    await _pumpSheet(tester);

    // 2020 -> 2000 is backwards.
    await tester.enterText(find.widgetWithText(TextField, 'From'), '2020');
    await tester.enterText(find.widgetWithText(TextField, 'To'), '2000');
    await tester.pump();

    final show = tester
        .widgetList<AppButton>(find.byType(AppButton))
        .firstWhere((b) => b.label.startsWith('Show'));
    expect(show.onPressed, isNull);
    expect(find.text('Start year is after end year'), findsOneWidget);
  });

  testWidgets('filter chips are AppChips', (tester) async {
    await _pumpSheet(tester);

    final chips = tester.widgetList<AppChip>(find.byType(AppChip)).toList();
    expect(chips.map((c) => c.label), contains('Under 90 min'));
    expect(chips.every((c) => c.onTap != null), isTrue);
  });

  testWidgets('the sheet surface follows the palette', (tester) async {
    final last = AppThemeService.palettes.last;
    await _pumpSheet(tester, palette: last);

    final surface = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.borderRadius != null && d.color != null);
    expect(surface.color, PlayTorrioTokens.fromPalette(last).surface);
    expect(
      surface.color,
      isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).surface),
    );
  });

  testWidgets('renders without throwing', (tester) async {
    await _pumpSheet(tester);

    expect(find.text('Filters'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — FAIL: no `AppButton`/`AppChip`.

- [ ] **Step 3: Apply the changes.**
  - `build`: `AppThemeService.currentPalette.value` → `PlayTorrioTokens.of(context)`; sheet fill → `tokens.surface`; top radius → `AppRadii.sheet`; top hairline → `tokens.borderSubtle`.
  - `_chip` → `AppChip`, and it takes the `accent` already threaded through the callers instead of re-reading the palette. Its four call sites pass `accent:`.
  - `_buildActionBar` → two `AppButton`s: `Reset all` (`AppButtonVariant.secondary`, disabled when there is no input) and the apply button (`AppButtonVariant.primary`, `expand: true`, `loading: _counting && _count == null`, label `Show N results`).
  - Tokenise the remaining literals per the rules table, including `_pickAndClearable`'s palette reads.
  - Add the imports for `playtorrio_tokens`, `app_semantic_colors`, `app_radii`, `../ui/app_button.dart`, `../ui/app_chip.dart`; drop `app_theme_service` once unused.

- [ ] **Step 4: Run to verify it passes** — PASS (5/5).

- [ ] **Step 5: Commit** — `git commit -m "refactor(udl): adopt AppChip and AppButton in AdvancedFilterSheet"`

---

### Task 3: Extend the colour guard

**Files:** Modify `test/udl/no_inline_colors_test.dart`

- [ ] **Step 1: Add the two paths** to `migratedFiles`:

```dart
  'lib/widgets/discover/filter_option_sheet.dart',
  'lib/widgets/discover/advanced_filter_sheet.dart',
```

- [ ] **Step 2: Run** — `flutter test test/udl/no_inline_colors_test.dart` → PASS (2/2).

- [ ] **Step 3: Commit** — `git commit -m "test(udl): extend the inline-colour guard to the filter sheets"`

---

## Verification

- [ ] `flutter analyze` → 0 errors, 0 warnings, ≤33 infos.
- [ ] `flutter test test/udl test/widgets_ui` → all pass.
- [ ] `flutter test` → failures unchanged from the pre-existing live-network set; none under `test/udl` or `test/widgets_ui`.

## Self-Review

- **Spec coverage:** §13 enforced by Task 3. §6.8 unaffected — both widgets are sheet bodies, and the sheet surface is explicitly opaque by design.
- **Deferred:** `AppSheet` adoption needs the caller in `discover_page.dart` to switch to `AppSheet.show` (phase 3). `AppTextField` adoption needs the year fields' invalid affordance decided (border vs error text) and an `inputFormatters` parameter.
- **Typing:** `AppChip`, `AppButton`, `AppButtonVariant.{primary,secondary}`, `AppButtonSize`, `AppButton.expand/.loading`, `AppBadgeTone`, `AppRadii.sheet`, `AppSearchField(controller, hintText, onChanged)` all exist as used.
