# UDL Phase 3c — Browse Screens (Home / Discover / Search) Implementation Plan

> **For the executor:** follow this plan task by task. Every task ends with a
> commit. Never start a task before the previous one is green.

**Goal:** Move the three browse surfaces — home, discover, search — off inline
colour literals and onto the token layer, adopting the phase-2 primitives where
a control already has one. 135 literals across 4 files go to 0.

**Architecture:** Colours resolve through `PlayTorrioTokens.of(context)` (palette-
driven) or one of the fixed semantic layers (`AppSemanticColors`,
`AppGlassColors`, `AppSponsorColors`) — never a literal at the call site. Pages
stay transparent over their ambient/backdrop chrome and must render correctly
with `GlassSettings.enabled == false` (the default).

**Tech Stack:** Flutter 3.47.6 / Dart 3.11, no new packages.

**Spec:** the UDL design document was removed from the tree in `5ef603b`; the
binding contract is now the token layer itself (`lib/theme/`), the phase-3a/3b
plans, and `AGENTS.md`. Where this plan makes a visual call, it says so.

---

## Pre-flight

Run from the repo root. Work directly on `main`; no worktree.

```powershell
flutter pub get
flutter analyze                     # expect: 33 issues, 0 errors, 0 warnings
flutter test test/udl test/widgets_ui test/theme
```

Baseline for the whole plan:

- `flutter analyze` → **33 issues (0 errors / 0 warnings)**. This number must not grow.
- `test/udl` + `test/widgets_ui` + `test/theme` → all pass at every commit.
- Full `flutter test` has a documented pre-existing failure baseline (15 tests
  in 7 files) plus network flakes in `movy_scraper_test` /
  `anime_extractors_test`. Gate on **which** tests fail, never on totals.

Literal counts at the start of this phase (guard pattern, comments included):

| File | Literals |
|---|---|
| `lib/pages/home/home_page.dart` | 45 |
| `lib/pages/discover/discover_page.dart` | 30 |
| `lib/pages/search/search_page.dart` | 34 |
| `lib/pages/search/search_filter_sheet.dart` | 26 |

The guard lives in `test/udl/no_inline_colors_test.dart`:

```dart
final _inlineColor = RegExp(r'(?<![A-Za-z0-9_])(?:Color\(\s*0x|Colors\.(?!transparent))');
```

It scans every line of every file in `migratedFiles`, **comments included**, so a
comment like `// was Colors.white70` is an offender. `Colors.transparent` is
allowed and should stay.

### Persistent constraints

1. **No new packages.** No new design tokens either unless this plan says so.
2. **No behaviour changes.** Navigation, queries, filters, focus, paste, and
   debounce logic stay byte-for-byte identical in intent. The only permitted
   deltas are the ones listed per task under "Visual deltas".
3. **Colour only, except where a primitive replaces the control.** Do not
   re-space or re-type a screen beyond the listed adoptions.
4. **Glass off must be correct.** No screen may depend on the glass layer for
   contrast.
5. **Do not touch** `lib/services/theme/app_theme_service.dart`,
   `test/theme/app_theme_service_test.dart` (untracked, unowned), or the two
   untracked plan files.
6. **Push only to `origin`.** Never `upstream`.

### Add to the guard, one file per task, and watch it fail first

`migratedFiles` currently has 22 entries. Each task below starts by appending its
file and running the guard, which must list that file's literals. That RED is the
test for the task. Do not edit production code before you have seen it.

Update the doc comment above `migratedFiles` once (Task 1) so it no longer claims
the list belongs to the phase-2b plans:

```dart
/// Files that have been moved onto the token layer. Add a path here first, watch
/// the guard fail, then migrate the file.
```

---

## Task 1 — Close the `AppTextField` / `AppSearchField` gaps

The filter sheet's numeric fields need `inputFormatters` and a floating label;
the search page needs an alternate trailing action (paste) when the field is
empty. These are additive parameters on the shared primitives.

**Files**
- Modify: `lib/widgets/ui/app_text_field.dart`
- Test: `test/widgets_ui/app_text_field_test.dart`

**Step 1 — RED tests.** Read the existing test file first and match its host
helper and group style. Add:

```dart
testWidgets('inputFormatters are applied to typed text', (tester) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(host(AppTextField(
    controller: controller,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  )));

  await tester.enterText(find.byType(TextField), '12ab34');
  expect(controller.text, '1234');
});

testWidgets('labelText renders as a floating label', (tester) async {
  await tester.pumpWidget(host(const AppTextField(labelText: 'From (year)')));
  expect(find.text('From (year)'), findsOneWidget);
});

testWidgets('AppSearchField shows emptySuffix only while empty', (tester) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(host(AppSearchField(
    controller: controller,
    emptySuffix: const Icon(Icons.content_paste_rounded),
  )));

  expect(find.byIcon(Icons.content_paste_rounded), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'dune');
  await tester.pump();
  expect(find.byIcon(Icons.content_paste_rounded), findsNothing);
});
```

`host(...)` is `test/widgets_ui/host.dart` — import
`package:flutter/services.dart` for `FilteringTextInputFormatter`.

**Step 2 — run.** `flutter test test/widgets_ui/app_text_field_test.dart`
→ compile failures for the three missing members. That is the RED.

**Step 3 — GREEN.** In `app_text_field.dart`:

- `AppTextField`: add `final List<TextInputFormatter>? inputFormatters;` and
  `final String? labelText;` (import `package:flutter/services.dart`), pass
  `inputFormatters: inputFormatters` to the inner `TextField`, and pass
  `labelText: labelText` in the `InputDecoration`. Keep the existing
  `hintText` behaviour: when both are given Material floats the label and shows
  the hint on focus, which is what the filter sheet wants.
- `AppSearchField`: add `final Widget? emptySuffix;` and, inside the
  `ValueListenableBuilder`, return `emptySuffix ?? const SizedBox.shrink()` when
  the text is empty.

**Step 4 — verify.**

```powershell
flutter test test/widgets_ui/app_text_field_test.dart
flutter test test/udl test/widgets_ui test/theme
flutter analyze
```

**Step 5 — commit.**

```
feat(ui): let text fields take formatters, a label, and an empty-state suffix
```

---

## Task 2 — Search page

`lib/pages/search/search_page.dart` (34 → 0).

**Step 1 — guard RED.** Append `'lib/pages/search/search_page.dart'` to
`migratedFiles`, run `flutter test test/udl/no_inline_colors_test.dart`, confirm
the failure lists 34 lines of this file.

**Step 2 — imports.** Add:

```dart
import '../../theme/playtorrio_tokens.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/app_empty_state.dart';
import '../../widgets/ui/app_text_field.dart';
```

**Step 3 — substitutions.** Line numbers are from the plan date; locate by the
quoted literal.

| Line | Current | Replace with | Role |
|---|---|---|---|
| 546-548 | `isActive ? const Color(0xFF7C5CFF) : Colors.white.withValues(alpha: 0.06)` | `isActive ? tokens.accent : tokens.surface` | filter button fill |
| 550-553 | `isActive ? const Color(0xFF7C5CFF) : Colors.white.withValues(alpha: 0.1)` | `isActive ? tokens.accent : tokens.borderSubtle` | filter button border |
| 562 | `isActive ? Colors.white : Colors.white70` | `isActive ? tokens.onAccent : tokens.textPrimary` | tune icon |
| 575 | `color: Colors.white` (count badge fill) | `tokens.textPrimary` | badge fill: must read on both `accent` and `surface` |
| 583 | `color: Color(0xFF7C5CFF)` | `tokens.accent` | badge digits |
| 600 | `backgroundColor: const Color(0xFF080A0F)` | `tokens.bgPrimary` | scaffold |
| 614-615 | `const Color(0xFF080A0F).withValues(alpha: …)` | `tokens.bgPrimary.withValues(alpha: …)` (0.90 / 0.60) | app-bar gradient |
| 620 | `Colors.white.withValues(alpha: 0.06)` | `tokens.borderSubtle` | app-bar hairline |
| 629 | `color: Colors.white` (back arrow) | `tokens.textPrimary` | nav glyph |
| 640 | `Colors.white.withValues(alpha: 0.06)` | `tokens.surface` | search field fill |
| 643 | `Colors.white.withValues(alpha: 0.1)` | `tokens.borderSubtle` | search field border |
| 651 | `color: Colors.white` | `tokens.textPrimary` | input text |
| 661 | `Colors.white.withValues(alpha: 0.35)` | `tokens.textTertiary` | hint |
| 668 | `Colors.white38` | `tokens.textTertiary` | search glyph |
| 680 | `Colors.white60` | `tokens.textSecondary` | clear glyph |
| 693 | `Colors.white54` | `tokens.textSecondary` | paste glyph |
| 716 | `color: Color(0xFF7C5CFF)` | `tokens.accent` | loading spinner |
| 734 | `Colors.white.withValues(alpha: 0.2)` | `tokens.textTertiary` | no-results glyph |
| 742 | `Colors.white.withValues(alpha: 0.6)` | `tokens.textSecondary` | no-results copy |
| 752-753 | `backgroundColor: const Color(0xFF7C5CFF), foregroundColor: Colors.white` | delete (button adopted) | clear-filters button |
| 816 | `AlwaysStoppedAnimation<Color>(Color(0xFF7C5CFF))` | `AlwaysStoppedAnimation<Color>(tokens.accent)` | refresh bar |
| 837 | `Colors.white.withValues(alpha: 0.18)` | `tokens.textTertiary` | empty glyph |
| 844 | `Colors.white.withValues(alpha: 0.45)` | `tokens.textSecondary` | empty copy |
| 865 | `Colors.white38` | `tokens.textTertiary` | "RECENT SEARCHES" |
| 876 | `Color(0xFF00E5FF)` | `tokens.accent` | "Clear All" — the cyan is a stray accent |
| 893 | `Colors.white` | `tokens.textPrimary` | history chip label |
| 897 | `Colors.white.withValues(alpha: 0.07)` | `tokens.surface` | history chip fill |
| 898 | `Colors.white.withValues(alpha: 0.1)` | `tokens.borderSubtle` | history chip border |
| 904 | `Colors.white38` | `tokens.textTertiary` | chip delete glyph |

Add `final tokens = PlayTorrioTokens.of(context);` at the top of
`_buildFilterButton`, `build`, and `_buildEmptyState` (each builds its own
subtree; do not thread the value through fields).

**Step 4 — adopt the shared search field.** Replace the bespoke
`Container(height: 42, decoration: …) > TextField(...)` block (lines 637-699)
with:

```dart
AppSearchField(
  controller: _searchController,
  hintText: 'Search movies, series, or paste links',
  autofocus: true,
  onChanged: _onSearchChanged,
  onSubmitted: _performSearch,
  emptySuffix: IconButton(
    icon: const Icon(Icons.content_paste_rounded, size: 17),
    tooltip: 'Paste from clipboard',
    onPressed: _pasteFromClipboard,
  ),
),
```

Replace the whole `Container(height: 42, decoration: …)` wrapper too — not just
the `TextField` inside it. `AppTextField` sizes itself from its own padding
(`AppSpacing.md` vertical), so keeping a fixed 42px parent would clip it. Keep
the surrounding `Align`/`ConstrainedBox(maxWidth: 560)` so the field keeps its
place in the bar.

`AppSearchField` now owns the clear affordance (it clears and fires
`onChanged('')`), so delete the manual clear `IconButton`. `_focusNode` is only
referenced by the old `TextField` and `dispose()` (checked: lines 30, 54, 648) —
delete the field and its `dispose()` line, since `autofocus: true` covers the
open-with-keyboard behaviour.

**Visual deltas:** the search field becomes an `AppTextField` — its own
`surface` fill, `borderSubtle` border, `AppTypography.body` text, and a focus
ring — and the bar grows from 42px to the field's natural height (~48px).

**Step 5 — adopt the empty states.**

- No-results block (lines ~719-767): replace the icon + text + button with

```dart
AppEmptyState(
  icon: _results.isNotEmpty
      ? Icons.filter_alt_off_rounded
      : Icons.search_off_rounded,
  title: _results.isNotEmpty
      ? 'No results match your active filters'
      : 'No results for "$_lastQuery"',
  action: _results.isNotEmpty
      ? AppButton(
          label: 'Clear Filters',
          icon: Icons.filter_alt_off_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () => setState(() => _filters = const SearchFilterState()),
        )
      : null,
)
```

Keep it inside the existing `Center > SingleChildScrollView` padding.

- Pre-search block (`_buildEmptyState`): replace the 56px icon + copy with
  `AppEmptyState(icon: Icons.search_rounded, title: 'Search for movies, series, or paste a link')`
  and keep the recent-searches section below it as today.

**Visual deltas (deliberate):** the shared empty state uses a 32px icon and
`sectionHeading` title (the page used 56-64px and 16px body); "Clear Filters"
is a shared secondary button instead of an accent fill.

**Step 6 — guard GREEN and gates.**

```powershell
flutter test test/udl/no_inline_colors_test.dart
flutter test test/udl test/widgets_ui test/theme
flutter analyze
```

**Step 7 — commit.**

```
refactor(search): move the search page onto tokens and shared states
```

---

## Task 3 — Search filter sheet

`lib/pages/search/search_filter_sheet.dart` (26 → 0). Uses the primitives from
Task 1.

**Step 1 — guard RED.** Append
`'lib/pages/search/search_filter_sheet.dart'`, run the guard, confirm 26 lines.

**Step 2 — imports.** `playtorrio_tokens.dart`, `app_button.dart`,
`app_chip.dart`, `app_text_field.dart` (all `../../theme/…` / `../../widgets/ui/…`).

**Step 3 — drop the `_accent` constant.** Delete

```dart
static const Color _accent = Color(0xFF7C5CFF);
```

and read `PlayTorrioTokens.of(context).accent` inside `build` and each helper
that needs it (`_buildInput`, `_buildChoiceChip`, `_buildSectionHeader`). Any
`const` widget that referenced `_accent` loses its `const`.

**Step 4 — chrome substitutions.**

| Line | Current | Replace with |
|---|---|---|
| 261 | `color: const Color(0xFF12151E)` | `tokens.surfaceElevated` |
| 274 | `Colors.white.withValues(alpha: 0.15)` (handle) | `tokens.borderStrong` |
| 282 | `const Icon(Icons.tune_rounded, color: _accent, …)` | `tokens.accent`, drop `const` |
| 288 | `Colors.white` (title) | `tokens.textPrimary` |
| 295 | `Colors.white70` (close) | `tokens.textSecondary` |
| 301 | `Divider(color: Colors.white.withValues(alpha: 0.06))` | `Divider(color: tokens.borderSubtle)` — dividers stay at `borderSubtle` |
| 327 | `foregroundColor: Colors.white70` | delete (button adopted) |
| 328 | `side: BorderSide(color: Colors.white.withValues(alpha: 0.15))` | delete (button adopted) |
| 345-346 | `backgroundColor: _accent, foregroundColor: Colors.white` | delete (button adopted) |
| 375 | `Colors.white.withValues(alpha: 0.35)` (section label) | `tokens.textTertiary` |

**Step 5 — footer buttons.** Replace the two `OutlinedButton.icon` /
`ElevatedButton.icon` with:

```dart
Expanded(
  child: AppButton(
    label: 'Clear All',
    icon: Icons.filter_alt_off_outlined,
    variant: AppButtonVariant.secondary,
    expand: true,
    onPressed: _clearAll,
  ),
),
const SizedBox(width: 12),
Expanded(
  flex: 2,
  child: AppButton(
    label: _activeCount > 0 ? 'Apply ($_activeCount Active)' : 'Apply',
    icon: Icons.check_rounded,
    expand: true,
    onPressed: _apply,
  ),
),
```

**Step 6 — inputs.** Replace `_buildInput`'s `TextField` with

```dart
AppTextField(
  controller: controller,
  labelText: label,
  keyboardType: keyboardType,
  inputFormatters: inputFormatters,
)
```

and delete the rest of the method body. The `_buildInput` signature does not
change, so its six call sites stay as they are.

**Step 7 — chips.** Replace `_buildChoiceChip`'s body with

```dart
AppChip(label: label, selected: selected, onTap: onSelected);
```

and keep the method as a thin adapter (three call sites pass `onSelected`).

**Step 8 — remaining literals.** Sweep by role — the genres "N selected" copy and
any other leftover `Colors.white…` in the sections become
`tokens.textTertiary` (labels/counters) or `tokens.textSecondary` (body). Do not
invent new tokens.

**Sheet presentation stays unchanged.** `showSearchFilterSheet` keeps its
`showModalBottomSheet` with its own container, handle, and keyboard inset: the
sheet owns a `Flexible` scroll region and a max-height clamp that
`AppSheet.show`'s `Column(mainAxisSize.min)` cannot host. Record this in the
commit body.

**Visual deltas (deliberate):** the sheet body is `surfaceElevated` instead of
`#12151E`; numeric fields use the shared input (own fill, focus ring, radius);
type/genre/sort chips use `AppChip` (selected = accent label on
`surfaceSelected`, no 25% accent fill); the footer uses shared buttons.

**Step 9 — guard GREEN and gates.** Same three commands as Task 2.

**Step 10 — commit.**

```
refactor(search): move the filter sheet onto tokens, AppChip and AppTextField
```

---

## Task 4 — Discover page

`lib/pages/discover/discover_page.dart` (30 → 0).

**Step 1 — guard RED.** Append `'lib/pages/discover/discover_page.dart'`, run the
guard, confirm 30 lines.

**Step 2 — imports.** `playtorrio_tokens.dart`, `app_button.dart`,
`app_dialog.dart`, `app_empty_state.dart`, `app_text_field.dart`.

**Step 3 — delete the bar palette constants.** Remove

```dart
static const Color _kBarSurface = Color(0xFF1B2231);
static const Color _kBarMuted = Color(0xFF9AA6B8);
```

and read `tokens` in `_buildTypeSegmented`, `_segmentLabel`, `_iconButton`,
`_barDivider`.

**Step 4 — control bar.**

| Line | Current | Replace with |
|---|---|---|
| 518 | `Colors.white.withValues(alpha: 0.3)` (empty icon) | replaced by `AppEmptyState` (Step 6) |
| 523 | `Colors.white54` (empty copy) | replaced by `AppEmptyState` |
| 677 / 777 | `color: _kBarSurface` | `tokens.surfaceElevated` |
| 679 / 779 | `Colors.white.withValues(alpha: 0.06)` | `tokens.borderSubtle` |
| 744 | `selected ? Colors.white : _kBarMuted` | `selected ? tokens.textPrimary : tokens.textSecondary` |
| 787 | `Colors.white.withValues(alpha: 0.92)` | `tokens.textPrimary` |
| 807 | `Colors.white` (badge digits) | `tokens.onAccent` — the badge sits on `accent` |
| `_barDivider` (~664) | `Colors.white.withValues(alpha: 0.1)` | `tokens.borderSubtle` |

**Step 5 — gating prompt** (`_buildRequiredExtraGatingPrompt`).

| Line | Current | Replace with |
|---|---|---|
| 938 | `Colors.white` | `tokens.textPrimary` |
| 948 | `Colors.white.withValues(alpha: 0.7)` | `tokens.textSecondary` |
| 968 | `Colors.white.withValues(alpha: 0.1)` | `tokens.borderSubtle` |
| 979 | `color: Colors.white` (menu item) | `tokens.textPrimary` |
| 999 | `color: Colors.white` (chip label on accent) | `tokens.onAccent` |

Tokenise the `palette.primaryColor` / `palette.cardBackgroundColor` reads in this
method to `tokens.accent` / `tokens.surface` while you are in it (same values,
one source).

**Step 6 — empty state.** Replace the "No catalogs available" block (lines
515-526) with

```dart
AppEmptyState(
  icon: Icons.category_outlined,
  title: 'No catalogs available for "$_selectedType"',
)
```

inside the existing `Center > SingleChildScrollView` padding.

**Step 7 — custom-extra dialog.** Replace `_showCustomExtraDialog`'s
`showDialog > AlertDialog` with an `AppDialog` that keeps the dialog context
(this is the `update_dialog` pattern from 3b):

```dart
final result = await showDialog<String>(
  context: context,
  builder: (dialogContext) => AppDialog(
    title: 'Enter $extraName',
    content: SizedBox(
      width: 340,
      child: AppTextField(
        controller: controller,
        autofocus: true,
        hintText: 'Type $extraName here...',
        onSubmitted: (val) => Navigator.of(dialogContext).pop(val),
      ),
    ),
    actions: [
      AppButton(
        label: 'Cancel',
        variant: AppButtonVariant.tertiary,
        onPressed: () => Navigator.of(dialogContext).pop(),
      ),
      AppButton(
        label: 'Apply',
        onPressed: () => Navigator.of(dialogContext).pop(controller.text),
      ),
    ],
  ),
);
if (result == null) return;
_onCustomExtraSubmitted(extraName, result);
```

Dispose the controller when `result` is handled (add
`controller.dispose()` after the callback; the widget tree no longer uses it).
Keep `MediaQuery.sizeOf` out of it — `AppDialog` already clamps its width.

**Step 8 — legacy scaffold.**

| Line | Current | Replace with |
|---|---|---|
| 1139 | `const TextStyle(color: Colors.white54, …)` | `tokens.textSecondary` |
| 1164 | `Colors.white.withValues(alpha: 0.05)` | `tokens.borderSubtle` |
| 1172 | `Icon(Icons.arrow_back, color: Colors.white)` | `tokens.textPrimary` |
| 1182 | `color: Colors.white` | `tokens.textPrimary` |

**Step 9 — sheet colours, not sheet chrome.** In `_openSortSheet`, replace
`backgroundColor: AppThemeService.currentPalette.value.cardBackgroundColor` with
`tokens.surface`. Do **not** convert either sheet to `AppSheet.show`:

- `FilterOptionSheet` and `AdvancedFilterSheet` were migrated in 2b and already
  paint their own handle + header (and the advanced sheet owns its max-height,
  scroll region, and keyboard inset). Wrapping them would duplicate the chrome
  and break the scroll layout.
- They are already literal-free, so the 2b note "`AppSheet` in
  `discover_page.dart` → phase 3c" is closed by this decision, not by adoption.
  If a future sheet is written from scratch, use `AppSheet.show`.

**Step 10 — spinners.** `palette.primaryColor` in the three
`CircularProgressIndicator`s becomes `tokens.accent`.

**Step 11 — guard GREEN and gates.** Same three commands.

**Step 12 — commit.**

```
refactor(discover): move the browse grid and its chrome onto tokens
```

---

## Task 5 — Home page

`lib/pages/home/home_page.dart` (45 → 0). This is the largest and riskiest task:
it deletes a duplicated scroll track as well as colour work.

**Step 1 — guard RED.** Append `'lib/pages/home/home_page.dart'`, run the guard,
confirm 45 lines.

**Step 2 — imports.** Add `common/custom_scroll_track.dart`,
`ui/app_button.dart`, `theme/playtorrio_tokens.dart`,
`theme/app_semantic_colors.dart`, `theme/app_sponsor_colors.dart`.

**Step 3 — adopt the shared scroll track.** Replace line 483

```dart
child: _CustomScrollTrack(controller: _scrollController),
```

with

```dart
child: CustomScrollTrack(controller: _scrollController),
```

The shared widget is the same implementation (300px vertical track, drag-to-scrub,
400px arrow steps, hover reveal at 35% opacity) with the 3b glass/token chrome, so
no behaviour changes. Then delete `class _CustomScrollTrack` and
`class _HoverArrow` (lines 1460-1653, to end of file). Leave the `dart:ui`
import only if something else still needs it — `flutter analyze` will tell you
(`ImageFilter` is otherwise unused).

**Step 4 — splash and fallback.**

| Line | Current | Replace with |
|---|---|---|
| 521 | `color: const Color(0xFF080A0F)` (glass-disabled wrapper) | `tokens.bgPrimary` |
| 546 | `color: const Color(0xFF080A0F)` (intro overlay) | `tokens.bgPrimary` |
| 564 | `color: Colors.white` (wordmark) | `tokens.textPrimary` |
| 575 | `color: Colors.white54` (tagline) | `tokens.textSecondary` |

**Step 5 — top bar and hero dots.**

| Line | Current | Replace with |
|---|---|---|
| 442 | `Colors.white.withValues(alpha: 0.75)` (calendar) | `tokens.textSecondary` |
| 465 | `const Color(0xFFFFB300)` (fullscreen active) | `tokens.accent` |
| 466 | `Colors.white.withValues(alpha: 0.75)` | `tokens.textSecondary` |
| 810 | `const Color(0xFFFFD700)` (sponsor dot) | `AppSponsorColors.gold` |
| 810 | `primaryColor` | `tokens.accent` |
| 811/827 | `Colors.white.withValues(alpha: 0.30)` | `tokens.textTertiary` |

**Visual delta:** the active fullscreen glyph stops being amber and becomes the
palette accent — an active state belongs to the accent, and amber is reserved for
the sponsor ramp.

**Step 6 — carousel arrows (lines 904-915).**

| Current | Replace with |
|---|---|
| `Colors.black.withOpacity(0.6)` / `(0.3)` | `tokens.bgPrimary.withValues(alpha: 0.6)` / `(0.3)` |
| `Colors.white.withOpacity(0.6)` / `(0.2)` | `tokens.borderStrong` / `tokens.borderSubtle` |
| `Colors.white` / `Colors.white70` (glyph) | `tokens.textPrimary` / `tokens.textSecondary` |

Replace the deprecated `withOpacity` with `withValues(alpha:)` while editing.

**Step 7 — artwork layers.**

| Line | Current | Replace with |
|---|---|---|
| 1002 / 1004 | `const Color(0xFF151822)` (image placeholder + error) | `tokens.surface` |
| 1045 | `Colors.white` inside the `ShaderMask` gradient | `tokens.textPrimary`, drop `const` on the gradient, and add `// Alpha-only mask: the gradient's colour never reaches the screen.` |
| 1088 | `Colors.black.withValues(alpha: 0.65)` | `tokens.bgPrimary.withValues(alpha: 0.65)` |
| 1119 | `const ColoredBox(color: Color(0xFF151822))` | `ColoredBox(color: tokens.surface)` |

**Step 8 — metadata row (lines 1200-1250).** All four `0xFFFFD700` become
`AppSemanticColors.rating`. `Colors.white.withValues(alpha: 0.55)` (year,
runtime) → `tokens.textSecondary`; the 4px separator dot at `0.25` →
`tokens.textTertiary`.

**Visual delta:** the rating pill's gold shifts from `#FFD700` to the allowlist
rating gold `#FFB800`; every other screen already uses that value.

**Step 9 — hero actions.** Replace the `ElevatedButton.icon` + `OutlinedButton.icon`
row (lines 1323-1390) with a `Wrap` so the pair survives narrow widths and large
text scales:

```dart
Wrap(
  spacing: isCompact ? 8 : 12,
  runSpacing: 12,
  children: [
    AppButton(
      label: 'Watch Now',
      icon: Icons.play_arrow_rounded,
      onPressed: () => _openDetails(context),
    ),
    if (heroStyle != HeroStyle.minimalist)
      AppButton(
        label: 'Details',
        icon: Icons.info_outline_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: () => _openDetails(context),
      ),
  ],
)
```

**Visual delta:** fixed `md` button metrics replace the per-breakpoint padding;
the pair wraps instead of overflowing.

**Step 10 — sweep.** Re-run the guard; any remaining hit is a literal this table
missed — map it by role (fill → `surface`, hairline → `borderSubtle`/`borderStrong`,
body copy → `textSecondary`, labels → `textTertiary`, glyph → `textPrimary`,
positive accent → `accent`) and record the mapping in the commit body.

**Step 11 — gates.**

```powershell
flutter test test/udl/no_inline_colors_test.dart
flutter test test/udl test/widgets_ui test/theme
flutter analyze
```

**Step 12 — commit.**

```
refactor(home): move the hero and browse chrome onto tokens and shared widgets
```

---

## Task 6 — Phase verification

**Step 1 — literal sweep.** None of these may appear in the four migrated files:

```powershell
Select-String -Path lib/pages/home/home_page.dart,lib/pages/discover/discover_page.dart,lib/pages/search/search_page.dart,lib/pages/search/search_filter_sheet.dart -Pattern '0xFF7C5CFF|0xFFFFD700|0xFFFFB300|0xFF00E5FF|0xFF080A0F|0xFF12151E|0xFF0D1017|0xFF151822|0xFF1B2231|0xFF9AA6B8'
```

The guard must report `migratedFiles` = **26 paths** and zero offenders.

**Step 2 — gates.**

```powershell
flutter analyze          # 33 issues, 0 errors, 0 warnings
flutter test test/udl test/widgets_ui test/theme
flutter test             # only the documented baseline may fail
```

**Step 3 — glass-off check.** Run on Windows with glass effects **disabled**
(the default) and confirm every migrated surface reads correctly: the search
bar and its ring, the filter sheet, the discover control bar, the hero text over
artwork, the sponsor dots, and the scroll track.

**Step 4 — visual spot check (user, Windows).** Walk the three screens on at
least two palettes (the default and one warm palette such as Amber):

1. Home: hero actions use the shared primary/secondary buttons; the rating pill
   is the rating gold; the carousel dots mark the sponsor slide in promo gold;
   the scroll track matches the other pages' track; the splash still reads.
2. Discover: the segmented control, sort/filter buttons and badges take the
   palette accent; the gating prompt chips are legible; "Enter custom value"
   opens the shared dialog and still applies.
3. Search: field, filter button badge, spinner, refresh bar and "Clear All" are
   all the palette accent (no cyan, no violet); the no-results and pre-search
   states use the shared empty panel; the paste affordance is still there when
   the field is empty.
4. Filter sheet: chips, numeric fields, and the two footer buttons look like the
   rest of the app; the sheet still scrolls with the keyboard up.

**Step 5 — push.** `git push origin main` (never `upstream`).

**Step 6 — report.** List the four files, the deleted private widgets, the
primitive extensions from Task 1, the two deliberate sheet decisions, and every
visual delta above. Flag anything the executor mapped by role that this plan did
not name.

---

## Out of scope (recorded, do not implement here)

- `lib/pages/home/home_page.dart` has no widget test and cannot get a cheap one
  (it needs addons, continue-watching, my-list, and SharedPreferences). The
  guard plus the manual spot check are its coverage, as in 3b.
- `AppSheet.show` for `FilterOptionSheet`/`AdvancedFilterSheet` — see Task 4,
  Step 9.
- The discover/search filter state models and TMDB query building are untouched.
- Settings, IPTV, player, and library screens belong to phases 3d/4/5/6.
