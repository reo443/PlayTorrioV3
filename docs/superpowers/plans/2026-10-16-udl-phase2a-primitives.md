# UDL Phase 2a — Shared UI Primitive Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the reusable primitive component library at `lib/widgets/ui/` that every later UDL phase composes, built entirely from the phase-1 design tokens.

**Architecture:** Ten focused files under `lib/widgets/ui/`, one component family each. Every component is a stateless, token-driven widget with no app-model dependency: color comes from `PlayTorrioTokens.of(context)` (theme-reactive), geometry from the static scales. Filled surfaces are rendered as a `Material` carrying the token color, so ripple/ink works and tests can assert the surface color. Components are flat by default and must render correctly with glass effects disabled.

**Tech Stack:** Flutter 3.x / Dart ^3.11.5, `flutter_test` widget tests, `cached_network_image` (already a dependency) for `PosterImage`. No new packages.

**Spec:** `docs/superpowers/specs/2026-10-16-universal-design-language-design.md` (sections 4, 6.7, 6.8, 13). **Note:** that file is currently deleted in the working tree; retrieve it with `git show HEAD:docs/superpowers/specs/2026-10-16-universal-design-language-design.md`.

**Scope boundary:** This plan builds the library only. It creates no consumers. Migrating the 16 existing shared widgets onto it is phase 2b (a separate plan), and screens are phases 3–6.

## Global Constraints

- No new dependencies. Build on phase-1 tokens: `lib/theme/playtorrio_tokens.dart` (`PlayTorrioTokens`), `app_spacing.dart` (`AppSpacing`), `app_radii.dart` (`AppRadii`), `app_typography.dart` (`AppTypography`), `app_motion.dart` (`AppMotion`), `app_elevation.dart` (`AppElevation`), `app_semantic_colors.dart` (`AppSemanticColors`).
- **No inline color literals** in `lib/widgets/ui/`. Colors come from `PlayTorrioTokens` or, for the design §13 allowlist only (success/warning/error/destructive/rating/health/download/quality), `AppSemanticColors`. No `Color(0x...)` and no `Colors.*` may appear in the new files.
- Geometry: spacing from `AppSpacing`, radii from `AppRadii`, shadow from `AppElevation`, durations/curves from `AppMotion`. No bare numeric literals for these.
- Typography from `AppTypography`; styles carry no color — apply `tokens.textPrimary` / `textSecondary` / `textTertiary` at the call site.
- Font is Poppins. `FontWeight.w800` is synthesized (only 400/500/600/700 are bundled) — acceptable, keep as specified.
- Components must paint **no** opaque `bgPrimary` background: migrated screens sit over `AnimatedAmbientBackground`. `bgPrimary` is only used for placeholder fills.
- `prefer_const_constructors`, `prefer_const_declarations`, `prefer_single_quotes` are enabled lints — write const-correct code.
- `flutter analyze` baseline is **33 issues, all `info`, 0 warnings** — must not increase.
- `flutter test` baseline is **294 passing / 15 failing**, all pre-existing network/format tests — must not increase.
- Phase-1 precedent: the partner commits their own work. Every `git commit` step below must be confirmed with the partner first; if declined, leave the work verified and staged.
- Files use LF endings.

## Review Focus

These are the input classes the spec implies but that the components' own tests would otherwise not exercise. Each gets a test in the owning task (called out below).

1. **Long labels/titles** (e.g. 200 characters): a reasonable person expects truncation, not a `RenderFlex` overflow error. → Task 1, 2, 5, 7.
2. **Large text scale** (system font at 2×): a reasonable person expects a taller control, not clipped or overflowing text. → Task 1, 2, 7.
3. **Missing or failed artwork** (null url, 404): a reasonable person expects a placeholder, never a blank box or a thrown exception. → Task 5.
4. **Animations disabled** (`MediaQuery.disableAnimations`, reduced motion): a reasonable person expects no shimmer and no lingering ticker/timer. → Task 4.
5. **Disabled controls** (`onPressed == null`): a reasonable person expects the action not to fire and the state not to be signalled by color alone. → Task 1.

## File Structure

| File | Responsibility |
|---|---|
| `lib/widgets/ui/app_button.dart` | `AppButton` (4 variants × 2 sizes), `AppIconButton` |
| `lib/widgets/ui/app_chip.dart` | `AppChip` (interactive select), `AppBadge` + `AppBadgeTone` (metadata) |
| `lib/widgets/ui/app_card.dart` | `AppCard` — the shared surface frame (padding, border, elevation, tap) |
| `lib/widgets/ui/skeleton_box.dart` | `SkeletonBox` — shimmer/static loading placeholder |
| `lib/widgets/ui/poster_image.dart` | `PosterImage` + `MediaAspect` — aspect-correct artwork with placeholder/fallback |
| `lib/widgets/ui/app_text_field.dart` | `AppTextField`, `AppSearchField` |
| `lib/widgets/ui/app_empty_state.dart` | `AppEmptyState` |
| `lib/widgets/ui/app_error_state.dart` | `AppErrorState` |
| `lib/widgets/ui/app_sheet.dart` | `AppSheet` chrome + `AppSheet.show<T>()` |
| `lib/widgets/ui/app_dialog.dart` | `AppDialog` chrome + `showAppDialog()` |
| `test/widgets_ui/host.dart` | shared test harness (theme + MediaQuery knobs) |
| `test/widgets_ui/theme_reactivity_test.dart` | proves every component recolors when the palette changes |

`app_motion.dart` is modified once (Task 4) to add a reduced-motion helper.

---

### Task 1: AppButton + AppIconButton

**Files:**
- Create: `lib/widgets/ui/app_button.dart`
- Create: `test/widgets_ui/host.dart`
- Test: `test/widgets_ui/app_button_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens.of(context)` (`accent`, `onAccent`, `surface`, `surfaceElevated`, `borderSubtle`, `textPrimary`, `textTertiary`, `destructive`), `AppSpacing`, `AppRadii.roundedButton`, `AppTypography.label`, `AppMotion.fast` + `fastCurve`, `AppElevation.shadowSm`.
- Produces:
  ```dart
  enum AppButtonVariant { primary, secondary, tertiary, destructive }
  enum AppButtonSize { sm, md }        // heights: sm 36, md 44

  class AppButton extends StatelessWidget {
    const AppButton({
      super.key,
      required this.label,
      this.onPressed,
      this.variant = AppButtonVariant.primary,
      this.icon,
      this.trailingIcon,
      this.size = AppButtonSize.md,
      this.expand = false,
      this.loading = false,
    });
  }

  class AppIconButton extends StatelessWidget {
    const AppIconButton({
      super.key,
      required this.icon,
      required this.tooltip,      // required: accessible label for icon-only controls
      this.onPressed,
      this.size = AppButtonSize.md,
      this.selected = false,
    });
  }
  ```

- [ ] **Step 1: Create the shared test harness**

`test/widgets_ui/host.dart` — wraps a component in the real app theme and exposes the MediaQuery knobs the Review Focus needs:

```dart
Widget host(
  Widget child, {
  AppThemePalette? palette,
  double textScale = 1.0,
  bool disableAnimations = false,
  double width = 360,
});

/// The token color of the first Material inside [finder]'s subtree.
Color? materialColorOf(WidgetTester tester, Finder finder);
```

Implementation notes: `MaterialApp` with `theme: AppThemeService.createThemeData(palette ?? AppThemeService.palettes.first)`, a `builder:` that does `MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: disableAnimations)`, `home:` a `Scaffold(backgroundColor: Colors.transparent, body: Center(child: SizedBox(width: width, child: child)))`. `materialColorOf` takes a **`Finder`** (not a `Type`) so callers can scope to one button: `tester.widget<Material>(find.descendant(of: finder, matching: find.byType(Material)).first).color`.

- [ ] **Step 2: Write the failing tests**

`test/widgets_ui/app_button_test.dart`:

```dart
testWidgets('primary renders its label and uses the theme accent', (tester) async {
  await tester.pumpWidget(host(AppButton(label: 'Play', onPressed: () {})));
  expect(find.text('Play'), findsOneWidget);
  final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
  expect(materialColorOf(tester, find.byType(AppButton)), tokens.accent);
});

testWidgets('secondary and tertiary use a non-accent surface', (tester) async {
  final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
  await tester.pumpWidget(host(AppButton(label: 'Details', variant: AppButtonVariant.secondary, onPressed: () {})));
  expect(materialColorOf(tester, find.byType(AppButton)), isNot(tokens.accent));
});

testWidgets('enabled button fires onPressed once', (tester) async {
  var taps = 0;
  await tester.pumpWidget(host(AppButton(label: 'Play', onPressed: () => taps++)));
  await tester.tap(find.byType(AppButton));
  expect(taps, 1);
});

testWidgets('disabled button is not tappable and announces itself as disabled', (tester) async {
  await tester.pumpWidget(host(const AppButton(label: 'Play')));
  final ink = tester.widget<InkWell>(
    find.descendant(of: find.byType(AppButton), matching: find.byType(InkWell)),
  );
  expect(ink.onTap, isNull);
  final announcesDisabled = tester
      .widgetList<Semantics>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Semantics)),
      )
      .any((s) => s.properties.enabled == false);
  expect(announcesDisabled, isTrue);
});

testWidgets('loading shows a progress indicator and blocks taps', (tester) async {
  var taps = 0;
  await tester.pumpWidget(host(AppButton(label: 'Play', icon: Icons.play_arrow, onPressed: () => taps++, loading: true)));
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await tester.tap(find.byType(AppButton));
  expect(taps, 0);
});

testWidgets('expand fills the available width', (tester) async {
  await tester.pumpWidget(host(AppButton(label: 'Play', onPressed: () {}, expand: true)));
  expect(tester.getSize(find.byType(AppButton)).width, 360);
});

testWidgets('a very long label ellipsizes instead of overflowing', (tester) async {
  await tester.pumpWidget(host(AppButton(label: 'A' * 200, onPressed: () {})));
  expect(tester.takeException(), isNull);
});

testWidgets('survives 2x text scale without overflowing', (tester) async {
  await tester.pumpWidget(host(AppButton(label: 'Play now', icon: Icons.play_arrow, onPressed: () {}), textScale: 2.0));
  expect(tester.takeException(), isNull);
});

testWidgets('icon-only button exposes its tooltip as a semantics label', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(host(AppIconButton(icon: Icons.search, tooltip: 'Search', onPressed: () {})));
  expect(find.bySemanticsLabel('Search'), findsOneWidget);
  handle.dispose();
});
```

- [ ] **Step 3: Run the tests and verify they fail**

Run: `flutter test test/widgets_ui/app_button_test.dart`
Expected: FAIL — `AppButton` is not defined.

- [ ] **Step 4: Implement `lib/widgets/ui/app_button.dart`**

Decisions the signature and tests do not fix:
- Primary = filled `tokens.accent` with `tokens.onAccent` foreground; secondary = `tokens.surfaceElevated` surface + `tokens.borderStrong` border; tertiary = transparent surface + `tokens.textPrimary` label; destructive = `tokens.destructive` + `tokens.onAccent`.
- Disabled = same surface at 45% opacity, `tokens.textTertiary` label, `onPressed: null`, and `Semantics(enabled: false, button: true)`.
- The filled surface is a `Material(color: <token>, borderRadius: AppRadii.roundedButton, clipBehavior: Clip.antiAlias)` wrapping an `InkWell`; padding `EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md)` for `md`, `AppSpacing.lg`/`AppSpacing.sm` for `sm`.
- Label uses `AppTypography.label.apply(color: <foreground>)` with `maxLines: 1`, `overflow: TextOverflow.ellipsis`, wrapped in `Flexible`.
- Animation: `AnimatedContainer` with `AppMotion.fast` / `AppMotion.fastCurve` for surface changes.
- `loading` swaps the leading icon for a 16×16 `CircularProgressIndicator` (`strokeWidth: 2`, color = foreground) and forces `onPressed: null`.
- `AppIconButton` renders a 36×36 (`sm`) / 44×44 (`md`) `Material` surface with the icon centered, wrapped in `Tooltip(message: tooltip)` and `Semantics(label: tooltip, button: true, enabled: onPressed != null, selected: selected)`.

- [ ] **Step 5: Run the tests and verify they pass**

Run: `flutter test test/widgets_ui/app_button_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/ui/app_button.dart test/widgets_ui/host.dart test/widgets_ui/app_button_test.dart
git commit -m "feat(ui): add AppButton and AppIconButton primitives"
```

---

### Task 2: AppChip + AppBadge

**Files:**
- Create: `lib/widgets/ui/app_chip.dart`
- Test: `test/widgets_ui/app_chip_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens` (`surface`, `surfaceSelected`, `borderSubtle`, `borderStrong`, `textPrimary`, `textSecondary`, `accent`, `onAccent`), `AppSemanticColors` (`success`, `warning`, `error`, `rating`, `quality4k`, `qualityHd`, `qualitySd`), `AppSpacing`, `AppRadii.roundedChip` / `roundedBadge`, `AppTypography.label` / `badge`.
- Produces:
  ```dart
  class AppChip extends StatelessWidget {
    const AppChip({
      super.key,
      required this.label,
      this.selected = false,
      this.onTap,
      this.icon,
    });
  }

  enum AppBadgeTone { neutral, accent, success, warning, error, rating, quality4k, qualityHd, qualitySd }

  class AppBadge extends StatelessWidget {
    const AppBadge({super.key, required this.label, this.tone = AppBadgeTone.neutral, this.icon});
  }
  ```
  `tone` → color: `neutral` `tokens.textSecondary`, `accent` `tokens.accent`, `success`/`warning`/`error` `AppSemanticColors.*`, `rating` `AppSemanticColors.rating`, `quality4k`/`qualityHd`/`qualitySd` `AppSemanticColors.quality*`. `rating`/`quality4k` foreground is `Colors.black` (these are light colors); all others `tokens.textPrimary`.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('unselected chip uses the subtle border, selected uses the accent', (tester) async {
  final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
  await tester.pumpWidget(host(AppChip(label: 'Action', onTap: () {})));
  expect(materialColorOf(tester, find.byType(AppChip)), isNot(tokens.surfaceSelected));
  await tester.pumpWidget(host(AppChip(label: 'Action', selected: true, onTap: () {})));
  expect(materialColorOf(tester, find.byType(AppChip)), tokens.surfaceSelected);
});

testWidgets('chip is a labeled button for assistive tech', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(host(AppChip(label: 'Action', onTap: () {})));
  expect(find.bySemanticsLabel('Action'), findsOneWidget);
  handle.dispose();
});

testWidgets('badge tone colors its label with the fixed semantic color', (tester) async {
  await tester.pumpWidget(host(const AppBadge(label: 'HDR', tone: AppBadgeTone.quality4k)));
  final text = tester.widget<Text>(find.text('HDR'));
  expect(text.style?.color, AppSemanticColors.quality4k);
});

testWidgets('a very long chip label does not overflow', (tester) async {
  await tester.pumpWidget(host(AppChip(label: 'A' * 200, onTap: () {})));
  expect(tester.takeException(), isNull);
});

testWidgets('survives 2x text scale without overflowing', (tester) async {
  await tester.pumpWidget(host(const AppBadge(label: '1080p'), textScale: 2.0));
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `flutter test test/widgets_ui/app_chip_test.dart`
Expected: FAIL — `AppChip` is not defined.

- [ ] **Step 3: Implement `lib/widgets/ui/app_chip.dart`**

Decisions: `AppChip` surface = `selected ? tokens.surfaceSelected : tokens.surface`, border `selected ? tokens.borderStrong : tokens.borderSubtle` (1px), radius `AppRadii.roundedChip`, `Material` + `InkWell`, padding `EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm)`, label `AppTypography.label` colored `selected ? tokens.accent : tokens.textPrimary`, optional 14px leading icon, `maxLines: 1` + ellipsis, `Semantics(button: true, selected: selected, label: label)`. `AppBadge` surface is always the neutral `tokens.surface` (a badge must not become a colored block); the `tone` drives the **label and icon color** plus a 1px border of that color at 40% alpha, so `quality4k`/`rating` render `Colors.black` text on their light neutral surface only when the tone color itself is light — otherwise the tone color is used directly as the foreground. Radius `AppRadii.roundedBadge`, padding `EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs)`, label `AppTypography.badge`, `maxLines: 1`, ellipsis. Badges are non-interactive: no `InkWell`, not focusable.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/widgets_ui/app_chip_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/ui/app_chip.dart test/widgets_ui/app_chip_test.dart
git commit -m "feat(ui): add AppChip and AppBadge primitives"
```

---

### Task 3: AppCard

**Files:**
- Create: `lib/widgets/ui/app_card.dart`
- Test: `test/widgets_ui/app_card_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens` (`surface`, `surfaceSelected`, `surfaceElevated`, `borderSubtle`, `borderStrong`), `AppRadii.roundedCard`, `AppSpacing`, `AppElevation.shadowSm`, `AppMotion.fast`.
- Produces:
  ```dart
  class AppCard extends StatelessWidget {
    const AppCard({
      super.key,
      required this.child,
      this.padding,
      this.onTap,
      this.selected = false,
      this.elevated = false,
      this.bordered = true,
      this.radius,
    });
  }
  ```
  Defaults: `padding` → `EdgeInsets.all(AppSpacing.lg)`; `radius` → `AppRadii.roundedCard`.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('renders its child on the surface token color', (tester) async {
  final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
  await tester.pumpWidget(host(const AppCard(child: Text('Hello'))));
  expect(find.text('Hello'), findsOneWidget);
  expect(materialColorOf(tester, find.byType(AppCard)), tokens.surface);
});

testWidgets('elevated and selected change the surface', (tester) async {
  final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
  await tester.pumpWidget(host(const AppCard(elevated: true, child: Text('x'))));
  expect(materialColorOf(tester, find.byType(AppCard)), tokens.surfaceElevated);
  await tester.pumpWidget(host(const AppCard(selected: true, child: Text('x'))));
  expect(materialColorOf(tester, find.byType(AppCard)), tokens.surfaceSelected);
});

testWidgets('onTap fires', (tester) async {
  var taps = 0;
  await tester.pumpWidget(host(AppCard(onTap: () => taps++, child: const Text('x'))));
  await tester.tap(find.byType(AppCard));
  expect(taps, 1);
});

testWidgets('a card with no onTap renders no InkWell', (tester) async {
  await tester.pumpWidget(host(const AppCard(child: Text('x'))));
  expect(find.descendant(of: find.byType(AppCard), matching: find.byType(InkWell)), findsNothing);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `flutter test test/widgets_ui/app_card_test.dart`
Expected: FAIL — `AppCard` is not defined.

- [ ] **Step 3: Implement `lib/widgets/ui/app_card.dart`**

Decisions: `Material(color: elevated ? tokens.surfaceElevated : selected ? tokens.surfaceSelected : tokens.surface, borderRadius: radius, clipBehavior: Clip.antiAlias)`; when `bordered`, wrap content in a `DecoratedBox` with a 1px border `selected ? tokens.borderStrong : tokens.borderSubtle`; when `elevated` **or** `selected`, add `AppElevation.shadowSm` via a `Container` decoration. `onTap != null` wraps the child in `InkWell`; otherwise no `InkWell` is emitted. No opaque `bgPrimary`.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/widgets_ui/app_card_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/ui/app_card.dart test/widgets_ui/app_card_test.dart
git commit -m "feat(ui): add AppCard surface primitive"
```

---

### Task 4: SkeletonBox + reduced-motion helper

**Files:**
- Create: `lib/widgets/ui/skeleton_box.dart`
- Modify: `lib/theme/app_motion.dart`
- Test: `test/widgets_ui/skeleton_box_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens` (`bgSecondary`, `surface`), `AppRadii.roundedCard`, `AppMotion`.
- Produces:
  ```dart
  class SkeletonBox extends StatefulWidget {
    const SkeletonBox({super.key, this.width, this.height, this.radius});
    // radius defaults to AppRadii.roundedCard
  }

  // added to AppMotion:
  static Duration reduce(BuildContext context, Duration duration); // Duration.zero when MediaQuery.disableAnimations
  ```

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('reduce returns Duration.zero when animations are disabled', (tester) async {
  late Duration reduced;
  await tester.pumpWidget(host(Builder(builder: (context) {
    reduced = AppMotion.reduce(context, AppMotion.standard);
    return const SizedBox.shrink();
  }), disableAnimations: true));
  expect(reduced, Duration.zero);
});

testWidgets('reduce passes the duration through when animations are enabled', (tester) async {
  late Duration reduced;
  await tester.pumpWidget(host(Builder(builder: (context) {
    reduced = AppMotion.reduce(context, AppMotion.standard);
    return const SizedBox.shrink();
  })));
  expect(reduced, AppMotion.standard);
});

testWidgets('renders a box of the requested size', (tester) async {
  await tester.pumpWidget(host(const SkeletonBox(width: 100, height: 150)));
  expect(tester.getSize(find.byType(SkeletonBox)), const Size(100, 150));
});

testWidgets('is static when animations are disabled', (tester) async {
  await tester.pumpWidget(host(const SkeletonBox(width: 100, height: 150), disableAnimations: true));
  await tester.pump(const Duration(milliseconds: 400));
  expect(tester.hasRunningAnimations, isFalse);
});

testWidgets('animates when animations are enabled', (tester) async {
  await tester.pumpWidget(host(const SkeletonBox(width: 100, height: 150)));
  expect(tester.hasRunningAnimations, isTrue);
  // A repeating animation never settles, so pump a fixed slice instead of
  // pumpAndSettle (which would time out here).
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.byType(SkeletonBox), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `flutter test test/widgets_ui/skeleton_box_test.dart`
Expected: FAIL — `SkeletonBox` is not defined.

- [ ] **Step 3: Add `AppMotion.reduce` to `lib/theme/app_motion.dart`**

Change the import to `package:flutter/widgets.dart` (re-exports `animation.dart`) and add the static helper. Keep every existing constant untouched.

- [ ] **Step 4: Implement `lib/widgets/ui/skeleton_box.dart`**

Decisions: an `AnimationController` with `repeat(reverse: true)` between 0.35 and 1.0 opacity over `AppMotion.standard` scaled by `AppMotion.reduce(context, ...)`; when the reduced duration is `Duration.zero`, do not start the controller at all (so `hasRunningAnimations` is false and no timer is pending). Fill color `tokens.bgSecondary` blended 50% toward `tokens.surface`, radius `radius ?? AppRadii.roundedCard`. Dispose the controller.

- [ ] **Step 5: Run the tests and verify they pass**

Run: `flutter test test/widgets_ui/skeleton_box_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/ui/skeleton_box.dart lib/theme/app_motion.dart test/widgets_ui/skeleton_box_test.dart
git commit -m "feat(ui): add SkeletonBox and AppMotion.reduce reduced-motion helper"
```

---

### Task 5: PosterImage

**Files:**
- Create: `lib/widgets/ui/poster_image.dart`
- Test: `test/widgets_ui/poster_image_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens` (`bgSecondary`, `surface`, `textTertiary`), `AppRadii.roundedPoster`, `cached_network_image`.
- Produces:
  ```dart
  enum MediaAspect { poster, backdrop, profile, square, thumbnail }

  double aspectRatioOf(MediaAspect aspect); // poster 2/3, backdrop 16/9, profile 1/1, square 1/1, thumbnail 16/9

  class PosterImage extends StatelessWidget {
    const PosterImage({
      super.key,
      this.imageUrl,
      this.aspect = MediaAspect.poster,
      this.radius,
      this.fit = BoxFit.cover,
      this.semanticLabel,
      this.fallbackIcon = Icons.movie_outlined,
      this.placeholder,
      this.fallback,
    });
  }
  ```
  `radius` defaults to `AppRadii.roundedPoster`. When `placeholder`/`fallback` are supplied they replace the built-in ones.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('null url renders the fallback, not a network image', (tester) async {
  await tester.pumpWidget(host(const PosterImage(imageUrl: null)));
  expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
  expect(find.byType(CachedNetworkImage), findsNothing);
  expect(tester.takeException(), isNull);
});

testWidgets('empty url renders the fallback', (tester) async {
  await tester.pumpWidget(host(const PosterImage(imageUrl: '')));
  expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
});

testWidgets('a url renders a cached network image at the aspect ratio', (tester) async {
  await tester.pumpWidget(host(const PosterImage(imageUrl: 'https://example.com/a.jpg')));
  expect(find.byType(CachedNetworkImage), findsOneWidget);
  final size = tester.getSize(find.byType(PosterImage).first);
  expect(size.width / size.height, closeTo(2 / 3, 0.01));
});

testWidgets('backdrop keeps 16:9', (tester) async {
  await tester.pumpWidget(host(const PosterImage(imageUrl: 'https://example.com/a.jpg', aspect: MediaAspect.backdrop), width: 320));
  final size = tester.getSize(find.byType(PosterImage).first);
  expect(size.width / size.height, closeTo(16 / 9, 0.01));
});

testWidgets('a custom fallback replaces the default', (tester) async {
  await tester.pumpWidget(host(const PosterImage(imageUrl: null, fallback: Text('none'))));
  expect(find.text('none'), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `flutter test test/widgets_ui/poster_image_test.dart`
Expected: FAIL — `PosterImage` is not defined.

- [ ] **Step 3: Implement `lib/widgets/ui/poster_image.dart`**

Decisions: `AspectRatio(aspectRatio: aspectRatioOf(aspect))` wrapping a `ClipRRect(borderRadius: radius)`. Null/empty/whitespace url → `fallback ?? DecoratedBox(color: tokens.bgSecondary, child: Center(Icon(fallbackIcon, color: tokens.textTertiary)))`. Otherwise `CachedNetworkImage(imageUrl:, fit:, placeholder: placeholder ?? SkeletonBox(...), errorWidget: fallback ?? <the same fallback>)`. Wrap in `Semantics(image: true, label: semanticLabel)` when `semanticLabel != null`.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/widgets_ui/poster_image_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/ui/poster_image.dart test/widgets_ui/poster_image_test.dart
git commit -m "feat(ui): add PosterImage artwork primitive"
```

---

### Task 6: AppTextField + AppSearchField

**Files:**
- Create: `lib/widgets/ui/app_text_field.dart`
- Test: `test/widgets_ui/app_text_field_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens` (`surface`, `borderSubtle`, `borderStrong`, `focusRing`, `textPrimary`, `textTertiary`, `error`, `accent`, `onAccent`), `AppRadii.roundedInput`, `AppSpacing`, `AppTypography`.
- Produces:
  ```dart
  class AppTextField extends StatelessWidget {
    const AppTextField({
      super.key,
      this.controller,
      this.hintText,
      this.prefixIcon,
      this.suffix,
      this.onChanged,
      this.onSubmitted,
      this.autofocus = false,
      this.obscureText = false,
      this.enabled = true,
      this.errorText,
      this.keyboardType,
      this.textInputAction,
      this.semanticsLabel,
    });
  }

  class AppSearchField extends StatelessWidget {
    const AppSearchField({
      super.key,
      this.controller,
      this.hintText = 'Search',
      this.onChanged,
      this.onSubmitted,
      this.autofocus = false,
      this.onClear,
    });
  }
  ```

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('renders a hint and reports typed text', (tester) async {
  String? value;
  await tester.pumpWidget(host(AppTextField(hintText: 'Title', onChanged: (v) => value = v)));
  expect(find.text('Title'), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'Dune');
  expect(value, 'Dune');
});

testWidgets('disabled field shows the disabled hint color and cannot be typed into', (tester) async {
  await tester.pumpWidget(host(const AppTextField(hintText: 'Title', enabled: false)));
  expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
});

testWidgets('error text is rendered and announced', (tester) async {
  await tester.pumpWidget(host(const AppTextField(hintText: 'Year', errorText: 'Enter a year')));
  expect(find.text('Enter a year'), findsOneWidget);
});

testWidgets('search field shows a clear affordance only with text', (tester) async {
  await tester.pumpWidget(host(AppSearchField(controller: TextEditingController())));
  expect(find.byIcon(Icons.close_rounded), findsNothing);
  await tester.enterText(find.byType(TextField), 'dune');
  await tester.pump();
  expect(find.byIcon(Icons.close_rounded), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `flutter test test/widgets_ui/app_text_field_test.dart`
Expected: FAIL — `AppTextField` is not defined.

- [ ] **Step 3: Implement `lib/widgets/ui/app_text_field.dart`**

Decisions: `TextField` with `InputDecoration(border: InputBorder.none, filled: true, fillColor: enabled ? tokens.surface : tokens.surface at 50% opacity, hintStyle: AppTypography.body.copyWith(color: enabled ? tokens.textTertiary : tokens.textTertiary at 60%), prefixIcon: …, suffixIcon: …)`, wrapped in a 1px `DecoratedBox` border `errorText != null ? tokens.error : (focused ? tokens.focusRing : tokens.borderSubtle)` with radius `AppRadii.roundedInput`. Focus is tracked with a `FocusNode` so the border reflects focus state. `errorText` renders below in `AppTypography.supporting` colored `tokens.error`. `AppSearchField` composes `AppTextField` with `prefixIcon: Icons.search_rounded`, `textInputAction: TextInputAction.search`, and a clear `IconButton` suffix that appears only when the controller has text (via `ValueListenableBuilder` on the controller) and calls `onClear` after clearing.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/widgets_ui/app_text_field_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/ui/app_text_field.dart test/widgets_ui/app_text_field_test.dart
git commit -m "feat(ui): add AppTextField and AppSearchField primitives"
```

---

### Task 7: AppEmptyState + AppErrorState

**Files:**
- Create: `lib/widgets/ui/app_empty_state.dart`
- Create: `lib/widgets/ui/app_error_state.dart`
- Test: `test/widgets_ui/app_states_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens` (`textPrimary`, `textSecondary`, `textTertiary`, `accent`), `AppSpacing`, `AppTypography`, `AppButton` (Task 1).
- Produces:
  ```dart
  class AppEmptyState extends StatelessWidget {
    const AppEmptyState({
      super.key,
      required this.title,
      this.message,
      this.icon = Icons.inbox_rounded,
      this.action,
    });
  }

  class AppErrorState extends StatelessWidget {
    const AppErrorState({
      super.key,
      this.title = 'Something went wrong',
      this.message,
      required this.onRetry,
      this.retryLabel = 'Try again',
    });
  }
  ```
  Both paint **no** background (they sit over `AnimatedAmbientBackground`).

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('empty state renders icon, title and message', (tester) async {
  await tester.pumpWidget(host(const AppEmptyState(title: 'Nothing saved', message: 'Add a title to your library')));
  expect(find.text('Nothing saved'), findsOneWidget);
  expect(find.text('Add a title to your library'), findsOneWidget);
  expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
});

testWidgets('empty state renders an optional action', (tester) async {
  await tester.pumpWidget(host(AppEmptyState(title: 'None', action: AppButton(label: 'Browse', onPressed: () {}))));
  expect(find.text('Browse'), findsOneWidget);
});

testWidgets('error state renders its default title and a retry that fires once', (tester) async {
  var retries = 0;
  await tester.pumpWidget(host(AppErrorState(onRetry: () => retries++)));
  expect(find.text('Something went wrong'), findsOneWidget);
  await tester.tap(find.text('Try again'));
  expect(retries, 1);
});

testWidgets('error state shows a custom message when given', (tester) async {
  await tester.pumpWidget(host(AppErrorState(message: 'No connection', onRetry: () {})));
  expect(find.text('No connection'), findsOneWidget);
});

testWidgets('states wrap long text instead of ellipsizing at 2x scale', (tester) async {
  await tester.pumpWidget(host(
    SingleChildScrollView(
      child: AppEmptyState(title: 'A' * 200, message: 'B' * 400),
    ),
    textScale: 2.0,
  ));
  expect(tester.takeException(), isNull);
  final message = tester.widget<Text>(find.text('B' * 400));
  expect(message.maxLines, isNull, reason: 'body copy must wrap, not be capped');
  expect(message.overflow, isNot(TextOverflow.ellipsis));
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `flutter test test/widgets_ui/app_states_test.dart`
Expected: FAIL — `AppEmptyState` is not defined.

- [ ] **Step 3: Implement both files**

Decisions: both are centered `Column`s with `mainAxisSize: MainAxisSize.min`, `padding: EdgeInsets.all(AppSpacing.xxl)`, title in `AppTypography.sectionHeading` colored `tokens.textPrimary` with `textAlign: TextAlign.center`, message in `AppTypography.supporting` colored `tokens.textSecondary` with `textAlign: TextAlign.center` and no `maxLines` cap (it must wrap, not ellipsize — this is body copy). `AppEmptyState` icon is 32px `tokens.textTertiary`. `AppErrorState` reuses `Icons.error_outline_rounded` and renders `AppButton(label: retryLabel, onPressed: onRetry)` — the retry button reads its label from the parameter so tests can match exactly `'Try again'`.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/widgets_ui/app_states_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/ui/app_empty_state.dart lib/widgets/ui/app_error_state.dart test/widgets_ui/app_states_test.dart
git commit -m "feat(ui): add AppEmptyState and AppErrorState primitives"
```

---

### Task 8: AppSheet

**Files:**
- Create: `lib/widgets/ui/app_sheet.dart`
- Test: `test/widgets_ui/app_sheet_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens` (`surfaceElevated`, `textPrimary`, `textSecondary`, `borderSubtle`), `AppRadii.roundedSheet`, `AppSpacing`, `AppTypography`, `AppMotion.sheet` / `sheetCurve`.
- Produces:
  ```dart
  class AppSheet extends StatelessWidget {
    const AppSheet({super.key, this.title, this.subtitle, required this.child, this.padding, this.leading});
    static Future<T?> show<T>(
      BuildContext context, {
      required WidgetBuilder builder,
      String? title,
      String? subtitle,
      bool isScrollControlled = true,
    });
  }
  ```

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('renders title, subtitle and child', (tester) async {
  await tester.pumpWidget(host(const AppSheet(title: 'Filters', subtitle: '2 active', child: Text('body'))));
  expect(find.text('Filters'), findsOneWidget);
  expect(find.text('2 active'), findsOneWidget);
  expect(find.text('body'), findsOneWidget);
});

testWidgets('renders a drag handle', (tester) async {
  await tester.pumpWidget(host(const AppSheet(child: Text('body'))));
  expect(find.byKey(const Key('app_sheet_handle')), findsOneWidget);
});

testWidgets('show() presents the builder content and pops', (tester) async {
  await tester.pumpWidget(host(Builder(builder: (context) => AppButton(
    label: 'Open',
    onPressed: () => AppSheet.show<void>(context, title: 'Filters', builder: (_) => const Text('sheet body')),
  ))));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  expect(find.text('sheet body'), findsOneWidget);
  Navigator.of(tester.element(find.text('sheet body'))).pop();
  await tester.pumpAndSettle();
  expect(find.text('sheet body'), findsNothing);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `flutter test test/widgets_ui/app_sheet_test.dart`
Expected: FAIL — `AppSheet` is not defined.

- [ ] **Step 3: Implement `lib/widgets/ui/app_sheet.dart`**

Decisions: chrome is a `Material(color: tokens.surfaceElevated)` with top-only radius `AppRadii.sheet`, a 4×32 drag handle keyed `Key('app_sheet_handle')` in `tokens.borderSubtle`, optional title (`AppTypography.sectionHeading`, `tokens.textPrimary`) and subtitle (`AppTypography.supporting`, `tokens.textSecondary`), then `child` inside `SafeArea` with `padding ?? EdgeInsets.all(AppSpacing.xxl)`. `show()` calls `showModalBottomSheet<T>` with `backgroundColor: Colors.transparent` (**the one place `Colors.transparent` is allowed — it is not a color literal in a token sense, only an alpha channel**), `isScrollControlled:`, `useSafeArea: true`, `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)))`, and delegates the animation curve to `sheetAnimationStyle` built from `AppMotion.sheet` + `sheetCurve`.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/widgets_ui/app_sheet_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/ui/app_sheet.dart test/widgets_ui/app_sheet_test.dart
git commit -m "feat(ui): add AppSheet chrome and show helper"
```

---

### Task 9: AppDialog

**Files:**
- Create: `lib/widgets/ui/app_dialog.dart`
- Test: `test/widgets_ui/app_dialog_test.dart`

**Interfaces:**
- Consumes: `PlayTorrioTokens` (`surfaceElevated`, `textPrimary`, `textSecondary`), `AppRadii.roundedSheet`, `AppSpacing`, `AppTypography`, `AppButton` (Task 1).
- Produces:
  ```dart
  class AppDialog extends StatelessWidget {
    const AppDialog({super.key, required this.title, this.message, this.content, this.actions = const []});
  }

  Future<bool?> showAppDialog(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    String confirmLabel = 'OK',
    String? cancelLabel,
    bool destructive = false,
  });
  ```
  `showAppDialog` returns `true` for confirm, `false` for cancel, `null` on dismiss.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('renders title, message and actions', (tester) async {
  await tester.pumpWidget(host(const AppDialog(title: 'Remove?', message: 'This cannot be undone', actions: [Text('OK')])));
  expect(find.text('Remove?'), findsOneWidget);
  expect(find.text('This cannot be undone'), findsOneWidget);
});

testWidgets('showAppDialog returns true on confirm', (tester) async {
  bool? result;
  await tester.pumpWidget(host(Builder(builder: (context) => AppButton(
    label: 'Ask',
    onPressed: () async => result = await showAppDialog(context, title: 'Remove?', message: 'Sure?', cancelLabel: 'Cancel'),
  ))));
  await tester.tap(find.text('Ask'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  expect(result, isTrue);
});

testWidgets('showAppDialog returns false on cancel', (tester) async {
  bool? result;
  await tester.pumpWidget(host(Builder(builder: (context) => AppButton(
    label: 'Ask',
    onPressed: () async => result = await showAppDialog(context, title: 'Remove?', cancelLabel: 'Cancel'),
  ))));
  await tester.tap(find.text('Ask'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();
  expect(result, isFalse);
});

testWidgets('destructive confirm uses the destructive variant', (tester) async {
  final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
  await tester.pumpWidget(host(Builder(builder: (context) => AppButton(
    label: 'Ask',
    onPressed: () => showAppDialog(context, title: 'Remove?', confirmLabel: 'Remove', destructive: true),
  ))));
  await tester.tap(find.text('Ask'));
  await tester.pumpAndSettle();
  final confirm = find.ancestor(of: find.text('Remove'), matching: find.byType(AppButton));
  expect(materialColorOf(tester, confirm), tokens.destructive);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `flutter test test/widgets_ui/app_dialog_test.dart`
Expected: FAIL — `AppDialog` is not defined.

- [ ] **Step 3: Implement `lib/widgets/ui/app_dialog.dart`**

Decisions: `AppDialog` is a `Material(color: tokens.surfaceElevated)` with radius `AppRadii.roundedSheet` and `padding: EdgeInsets.all(AppSpacing.xxl)`; title `AppTypography.sectionHeading` `tokens.textPrimary`; message `AppTypography.supporting` `tokens.textSecondary`; `actions` laid out end-aligned in a `Wrap(spacing: AppSpacing.sm)`. `showAppDialog` uses `showDialog<bool>` with `barrierDismissible: true` and builds `AppDialog` with an `AppButton(variant: destructive ? AppButtonVariant.destructive : AppButtonVariant.primary, label: confirmLabel, onPressed: () => Navigator.pop(context, true))` plus, when `cancelLabel != null`, a `tertiary` cancel button popping `false`.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/widgets_ui/app_dialog_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/ui/app_dialog.dart test/widgets_ui/app_dialog_test.dart
git commit -m "feat(ui): add AppDialog chrome and showAppDialog helper"
```

---

### Task 10: Theme reactivity + library guard

**Files:**
- Test: `test/widgets_ui/theme_reactivity_test.dart`
- Test: `test/widgets_ui/library_guard_test.dart`

**Interfaces:**
- Consumes: every component produced by Tasks 1–9.
- Produces: nothing (verification only).

- [ ] **Step 1: Write the failing reactivity test**

The spec requires that a theme switch recolors every surface. Assert it per component by rendering under the first and the last palette and comparing the resolved surface color:

```dart
testWidgets('AppButton recolors when the palette changes', (tester) async {
  await tester.pumpWidget(host(AppButton(label: 'Play', onPressed: () {}), palette: AppThemeService.palettes.first));
  final a = materialColorOf(tester, find.byType(AppButton));
  await tester.pumpWidget(host(AppButton(label: 'Play', onPressed: () {}), palette: AppThemeService.palettes.last));
  final b = materialColorOf(tester, find.byType(AppButton));
  expect(a, isNot(b));
  expect(b, PlayTorrioTokens.fromPalette(AppThemeService.palettes.last).accent);
});
```

Repeat for `AppChip` (selected), `AppCard`, `AppSearchField` (filled color), `SkeletonBox`, `PosterImage` (fallback fill), `AppSheet`, and `AppErrorState` (via its accent-colored retry button, scoped with `find.ancestor(of: find.text('Try again'), matching: find.byType(AppButton))`). For `AppBadge`, assert the **label color** changes with the palette when `tone: AppBadgeTone.accent` (its neutral surface deliberately stays constant). `AppEmptyState` is intentionally excluded: it renders only neutral text tokens, which are palette-independent by design, so it has nothing to recolor. Each is its own `testWidgets`.

- [ ] **Step 2: Write the failing library guard test**

A test that reads its own source directory and fails if any file under `lib/widgets/ui/` contains a disallowed color literal — this is what makes the design §13 "no inline color literals" rule enforceable rather than aspirational:

```dart
test('no inline color literals in lib/widgets/ui', () {
  final dir = Directory('lib/widgets/ui');
  final offenders = <String>[];
  for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
    final src = f.readAsStringSync();
    for (final pattern in [RegExp(r'Color\(0x'), RegExp(r'Colors\.(?!transparent)')]) {
      if (pattern.hasMatch(src)) offenders.add('${f.path}: ${pattern.pattern}');
    }
  }
  expect(offenders, isEmpty, reason: 'Use PlayTorrioTokens or AppSemanticColors');
});
```

`Colors.transparent` is exempt (it is an alpha channel, used for the sheet's modal barrier background).

- [ ] **Step 3: Run both tests and verify they fail**

Run: `flutter test test/widgets_ui/theme_reactivity_test.dart test/widgets_ui/library_guard_test.dart`
Expected: the guard may already fail if Tasks 1–9 introduced literals — fix those files, not the test. The reactivity test fails only if a component caches a color statically instead of reading `PlayTorrioTokens.of(context)`.

- [ ] **Step 4: Fix any component that does not pass**

The usual cause is a `const` widget holding a color computed at construction time, or a static cached `TextStyle` with a baked color. Read tokens inside `build`.

- [ ] **Step 5: Run the whole new suite**

Run: `flutter test test/widgets_ui/`
Expected: PASS (all tests from Tasks 1–10).

- [ ] **Step 6: Run the repo gates**

Run: `flutter analyze`
Expected: 33 issues, all `info`, 0 warnings.

Run: `flutter test`
Expected: 294 + (new tests) passing, 15 failing (the same pre-existing failures).

- [ ] **Step 7: Commit**

```bash
git add test/widgets_ui/theme_reactivity_test.dart test/widgets_ui/library_guard_test.dart
git commit -m "test(ui): pin theme reactivity and no-inline-color rule for the primitive library"
```

---

## Self-Review

**Spec coverage.**
- §4 Buttons → Task 1. Cards → Task 3. Posters/artwork → Task 5. Search/inputs → Task 6. Chips/badges → Task 2. Dialogs/sheets → Tasks 8, 9. Loading/empty/error → Tasks 4, 7. ✅
- §6.7 component naming (`AppButton`, `AppCard`, `AppChip`, `AppBadge`, `PosterImage`, `AppTextField`, `AppSheet`, `AppDialog`, `AppEmptyState`, `AppErrorState`, `SkeletonBox`) → all match. `AppIconButton` is an addition required by §8's "accessible labels for icon-only buttons"; `AppSearchField` is an addition required by §4's search-bar standardization. ✅
- §6.8 flat-by-default / works with glass off → no component depends on `GlassSettings`; all are plain `Material`/`DecoratedBox`. Transparent-over-ambient → no component paints `bgPrimary`; enforced by Task 10 Step 2. ✅
- §11 variant states → default/pressed (`InkWell`), selected, disabled, loading covered in Tasks 1–3; focused covered in Task 6. ✅
- §13 allowlist → `AppSemanticColors` is the only source of fixed colors, used in Task 2. ✅

**Gaps / not in this plan (deliberate):** no consumer migration (that is 2b); no `DropdownButton`/checkbox/radio primitive (no phase-2 target needs one — deferred until a screen does, per YAGNI); no golden/screenshot tests (repo has none, and introducing them would add tooling the spec forbids).

**Type consistency check:** `materialColorOf` is defined once in `host.dart` (Task 1) and used by Tasks 2, 3, 9, 10. `AppButton`'s constructor is named identically in Tasks 7, 9, 10. `AppRadii.roundedSheet` is used by both `AppSheet` and `AppDialog` per the §4 decision that sheets and dialogs share the large-panel radius. `AppMotion.reduce` is defined in Task 4 and is the only motion helper referenced later.
