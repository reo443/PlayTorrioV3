# UDL Phase 2b-A — States & Chrome Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the five low-risk shared chrome/state widgets (`poster_skeleton`, `error_view`, `section_header`, `page_top_bar`, `modern_toast`) onto the phase-2a primitives and the token layer, deleting every hardcoded colour literal in them.

**Architecture:** Each widget keeps its public API byte-for-byte. Bodies are reimplemented on `SkeletonBox`, `PosterImage`'s fallback contract, `AppErrorState`, `AppButton` and `PlayTorrioTokens`. Where a primitive's contract differs from the current pixels (button metrics, semantic shade) the delta is deliberate and is listed in "Known visible deltas" below. Two of the five (`page_top_bar`, `section_header`) keep custom layout because the design doc's component list has no top-bar/section-header primitive — they are *recoloured*, not rewritten.

**Tech Stack:** Flutter 3.x / Dart 3.11, `flutter_test`, no new packages. Tests reuse `test/widgets_ui/host.dart`.

---

## Scope

Phase 2b is three independent subsystems. This plan is **A** only.

- **A (this plan):** `poster_skeleton.dart`, `error_view.dart`, `section_header.dart`, `page_top_bar.dart`, `modern_toast.dart`
- **B (later plan):** `movie_card`, `anime_card`, `manga_card`, `iptv_channel_card`, `continue_watching_slider`, `movie_slider_section`
- **C (later plan):** `filter_option_sheet`, `advanced_filter_sheet`, `settings_controls`, `app_liquid_dock`, `liquid_dock`

## Global Constraints

- **Public APIs are frozen.** Every constructor parameter and public field listed below must survive unchanged. Consumers are: `page_top_bar` (5 pages), `error_view` (3 pages), `section_header` (3 slider sections), `poster_skeleton` (3 cards), `modern_toast` (2 player files).
- **`flutter analyze` must stay at 33 issues, all `info`, 0 warnings.**
- **Zero test failures under `test/widgets_ui` and `test/udl`.** The 15 pre-existing failures elsewhere are live-network flakiness; do not gate on their count.
- **No inline colour literals** in the five migrated files: no `Color(0x...)`, no `Colors.<name>` except where a value is not a colour. Task 6 enforces this mechanically.
- **Palette-derived, never fixed.** Anything that is today `0xFF7C5CFF` must come from `tokens.accent`, so the eight palettes actually change the chrome.
- **Transparency.** These widgets sit over `AnimatedAmbientBackground`; do not repaint an opaque full-screen background.

## Known visible deltas (deliberate, flagged to the user)

1. `section_header` "See All" becomes `AppButton(tertiary, sm)` → label moves from accent-coloured 14/w700 to `textPrimary` 13/w600, and the row grows from ~32px to the 44px minimum tap target.
2. `error_view` swaps an orange warning icon for `AppErrorState`'s neutral outline icon, and the title moves from 21/w800 to `AppTypography.sectionHeading`.
3. `modern_toast` shades change to the spec-§13 allowlist: success `0xFF10B981`→`0xFF30A46C`, error `0xFFF4436C`→`0xFFE5484D`, info `0xFF9D85FF`→`tokens.accent`.
4. `page_top_bar`'s inactive filter chip becomes the opaque token surface (`surfaceElevated` + `borderSubtle`) instead of a 6%-white tint, matching `AppIconButton`.
5. `modern_toast`'s shadow drops from a bespoke 0.45-black/24px to `AppElevation.shadowMd`.

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `lib/widgets/common/poster_skeleton.dart` | rewrite | `PosterSkeleton` delegates to `SkeletonBox`; `MissingPoster` becomes token-coloured |
| `lib/widgets/common/error_view.dart` | rewrite | thin wrapper over `AppErrorState` |
| `lib/widgets/common/section_header.dart` | rewrite | token-coloured header + `AppButton` "See All" |
| `lib/widgets/common/page_top_bar.dart` | rewrite | token-coloured glass bar, dead conditional removed |
| `lib/widgets/common/modern_toast.dart` | modify | semantic colours from the allowlist + tokens |
| `test/udl/poster_skeleton_test.dart` | create | 5 tests |
| `test/udl/error_view_test.dart` | create | 4 tests |
| `test/udl/section_header_test.dart` | create | 4 tests |
| `test/udl/page_top_bar_test.dart` | create | 5 tests |
| `test/udl/modern_toast_test.dart` | create | 4 tests |
| `test/udl/no_inline_colors_test.dart` | create | 1 guard test over the migrated file list |

All new tests import the existing harness with `import '../widgets_ui/host.dart';`.

---

### Task 1: `MissingPoster` and `PosterSkeleton` on the primitives

**Files:**
- Modify: `lib/widgets/common/poster_skeleton.dart` (whole file → rewrite)
- Test: `test/udl/poster_skeleton_test.dart`

Consumers pass `PosterSkeleton` as a `CachedNetworkImage.placeholder` and `MissingPoster` as its `errorWidget`, both inside the card's `ClipRRect(borderRadius: circular(18))` (`movie_card.dart:275-295`). The skeleton must therefore stay **square-filled** so the frame alone owns the corner — passing a radius would leave slivers at frames whose clip is larger.

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/poster_skeleton_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/poster_skeleton.dart';
import 'package:playtorrio/widgets/ui/skeleton_box.dart';

import '../widgets_ui/host.dart';

Color? _missingPosterSurface(WidgetTester tester) {
  final box = tester.widget<ColoredBox>(
    find
        .descendant(of: find.byType(MissingPoster), matching: find.byType(ColoredBox))
        .first,
  );
  return box.color;
}

void main() {
  testWidgets('PosterSkeleton renders the shared SkeletonBox', (tester) async {
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: PosterSkeleton())),
    );

    expect(find.byType(SkeletonBox), findsOneWidget);
  });

  testWidgets('PosterSkeleton fills its frame squarely', (tester) async {
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: PosterSkeleton())),
    );

    final skeleton = tester.widget<SkeletonBox>(find.byType(SkeletonBox));
    expect(skeleton.radius, BorderRadius.zero);
  });

  testWidgets('PosterSkeleton is static under reduced motion', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(width: 120, height: 180, child: PosterSkeleton()),
        disableAnimations: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('PosterSkeleton shimmers when motion is allowed', (tester) async {
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: PosterSkeleton())),
    );

    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('MissingPoster uses the token surface and tertiary icon', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: MissingPoster())),
    );

    expect(_missingPosterSurface(tester), tokens.surfaceElevated);
    final icon = tester.widget<Icon>(
      find.descendant(of: find.byType(MissingPoster), matching: find.byType(Icon)),
    );
    expect(icon.color, tokens.textTertiary);
  });

  testWidgets('MissingPoster follows the selected palette', (tester) async {
    final last = AppThemeService.palettes.last;
    final first = AppThemeService.palettes.first;
    await tester.pumpWidget(
      host(const SizedBox(width: 120, height: 180, child: MissingPoster()), palette: last),
    );

    expect(
      _missingPosterSurface(tester),
      PlayTorrioTokens.fromPalette(last).surfaceElevated,
    );
    expect(
      _missingPosterSurface(tester),
      isNot(PlayTorrioTokens.fromPalette(first).surfaceElevated),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/udl/poster_skeleton_test.dart`
Expected: FAIL — `MissingPoster`'s surface is `Color(0xFF171A23)` literal, and `find.byType(SkeletonBox)` finds nothing.

- [ ] **Step 3: Rewrite the implementation**

```dart
// lib/widgets/common/poster_skeleton.dart
import 'package:flutter/material.dart';

import '../../theme/playtorrio_tokens.dart';
import '../ui/skeleton_box.dart';

/// Shimmer placeholder shown while a poster image is loading.
///
/// Delegates to [SkeletonBox] so every loading placeholder in the app pulses
/// with one motion and one token-derived fill. The skeleton itself is square:
/// the surrounding poster frame owns the corner radius, so the placeholder
/// always fills that frame edge to edge.
class PosterSkeleton extends StatelessWidget {
  const PosterSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const SkeletonBox(radius: BorderRadius.zero);
}

/// Placeholder shown when a poster image fails to load.
class MissingPoster extends StatelessWidget {
  const MissingPoster({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);

    return ColoredBox(
      color: tokens.surfaceElevated,
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          size: 46,
          color: tokens.textTertiary,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/udl/poster_skeleton_test.dart`
Expected: PASS (5/5).

- [ ] **Step 5: Commit**

```powershell
git add lib/widgets/common/poster_skeleton.dart test/udl/poster_skeleton_test.dart
git commit -m "refactor(udl): rebuild poster skeleton and missing poster on the primitives"
```

---

### Task 2: `ErrorView` on `AppErrorState`

**Files:**
- Modify: `lib/widgets/common/error_view.dart` (whole file → rewrite)
- Test: `test/udl/error_view_test.dart`
- Consumers: `catalog_page.dart`, `home_page.dart`, `discover_page.dart` — all pass `error` and `onRetry` only.

`AppErrorState` generalises the hardcoded title. The wrapper keeps the catalogue copy verbatim so no consumer changes.

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/error_view_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/widgets/common/error_view.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/ui/app_error_state.dart';

import '../widgets_ui/host.dart';

void main() {
  testWidgets('ErrorView renders the shared AppErrorState', (tester) async {
    await tester.pumpWidget(host(ErrorView(error: 'boom', onRetry: () {})));

    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('ErrorView keeps the catalogue title and shows the error', (tester) async {
    await tester.pumpWidget(host(ErrorView(error: 'boom', onRetry: () {})));

    expect(find.text('Could not load movies'), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('ErrorView falls back to Unknown error when error is null', (tester) async {
    await tester.pumpWidget(host(ErrorView(error: null, onRetry: () {})));

    expect(find.text('Unknown error'), findsOneWidget);
  });

  testWidgets('ErrorView retry uses the shared button and fires onRetry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(host(ErrorView(error: 'boom', onRetry: () => retries++)));

    expect(find.byType(AppButton), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(retries, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/udl/error_view_test.dart`
Expected: FAIL — `ErrorView` does not build an `AppErrorState`, and `find.byType(AppButton)` finds nothing.

- [ ] **Step 3: Rewrite the implementation**

```dart
// lib/widgets/common/error_view.dart
import 'package:flutter/material.dart';

import '../ui/app_error_state.dart';

/// Full-screen failure panel for the catalogue surfaces.
///
/// A thin, movie-flavoured wrapper over [AppErrorState]: the shared panel owns
/// the layout, the type scale, and the colours; this keeps the copy the
/// catalogue screens have always shown.
class ErrorView extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppErrorState(
        title: 'Could not load movies',
        message: error ?? 'Unknown error',
        onRetry: onRetry,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/udl/error_view_test.dart`
Expected: PASS (4/4).

- [ ] **Step 5: Commit**

```powershell
git add lib/widgets/common/error_view.dart test/udl/error_view_test.dart
git commit -m "refactor(udl): rebuild ErrorView on AppErrorState"
```

---

### Task 3: `SectionHeader` tokens + `AppButton`

**Files:**
- Modify: `lib/widgets/common/section_header.dart` (whole file → rewrite)
- Test: `test/udl/section_header_test.dart`
- Consumers: `movie_slider_section.dart`, `anime_slider_section.dart`, `iptv_slider_section.dart` — all pass `title` and `onSeeAll` only.

Removes the direct `AppThemeService.currentPalette` read (the token extension is already palette-reactive) and the `Colors.white.withValues(alpha: 0.38)` subtitle literal.

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/section_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_typography.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/section_header.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';

import '../widgets_ui/host.dart';

void main() {
  testWidgets('title uses the section heading scale', (tester) async {
    await tester.pumpWidget(host(const SectionHeader(title: 'Trending')));

    final title = tester.widget<Text>(find.text('Trending'));
    expect(title.style!.fontSize, AppTypography.screenTitle.fontSize);
    expect(title.style!.fontWeight, AppTypography.screenTitle.fontWeight);
  });

  testWidgets('subtitle uses the token tertiary colour', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(const SectionHeader(title: 'Trending', subtitle: 'This week')),
    );

    final subtitle = tester.widget<Text>(find.text('This week'));
    expect(subtitle.style!.color, tokens.textTertiary);
  });

  testWidgets('onSeeAll renders a shared AppButton that fires the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(SectionHeader(title: 'Trending', onSeeAll: () => taps++)),
    );

    expect(find.byType(AppButton), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('no see-all control without onSeeAll', (tester) async {
    await tester.pumpWidget(host(const SectionHeader(title: 'Trending')));

    expect(find.byType(AppButton), findsNothing);
    expect(find.text('See All'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/udl/section_header_test.dart`
Expected: FAIL — title `fontSize` is 21 (not `AppTypography.screenTitle`'s 22) and there is no `AppButton`.

- [ ] **Step 3: Rewrite the implementation**

```dart
// lib/widgets/common/section_header.dart
import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';
import '../ui/app_button.dart';

/// Clean section header — title on left, optional trailing widget / "See All"
/// on right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.screenTitle.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTypography.supporting.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            if (onSeeAll != null) const SizedBox(width: AppSpacing.sm),
          ],
          if (onSeeAll != null)
            AppButton(
              label: 'See All',
              variant: AppButtonVariant.tertiary,
              size: AppButtonSize.sm,
              trailingIcon: Icons.chevron_right_rounded,
              onPressed: onSeeAll,
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/udl/section_header_test.dart`
Expected: PASS (4/4).

- [ ] **Step 5: Commit**

```powershell
git add lib/widgets/common/section_header.dart test/udl/section_header_test.dart
git commit -m "refactor(udl): move SectionHeader onto tokens and AppButton"
```

---

### Task 4: `PageTopBar` tokens, dead conditional removed

**Files:**
- Modify: `lib/widgets/common/page_top_bar.dart` (whole file → rewrite)
- Test: `test/udl/page_top_bar_test.dart`
- Consumers: `home_page.dart`, `discover_page.dart`, `catalog_page.dart`, `anime_page.dart`, `manga_page.dart`.

`page_top_bar.dart:47-49` is a conditional whose two branches are the same literal — it never followed the palette. Both the title and the filter button must resolve to `tokens.accent`.

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/page_top_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/page_top_bar.dart';

import '../widgets_ui/host.dart';

Color? _titleAccent(WidgetTester tester) {
  final rich = tester.widget<RichText>(find.byType(RichText).first);
  final span = rich.text as TextSpan;
  return span.children!.first.style!.color;
}

void main() {
  testWidgets('section title accent follows the selected palette', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(
      host(const PageTopBar(topPadding: 0, title: 'Movies'), palette: last),
    );

    expect(_titleAccent(tester), PlayTorrioTokens.fromPalette(last).accent);
    expect(
      _titleAccent(tester),
      isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).accent),
    );
  });

  testWidgets('back button is present and labelled when showBack', (tester) async {
    await tester.pumpWidget(
      host(const PageTopBar(topPadding: 0, showBack: true)),
    );

    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('no back button by default', (tester) async {
    await tester.pumpWidget(host(const PageTopBar(topPadding: 0)));

    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('filter button shows the count badge when active', (tester) async {
    await tester.pumpWidget(
      host(PageTopBar(topPadding: 0, onFilterTap: () {}, filterCount: 3)),
    );

    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('no filter button without onFilterTap', (tester) async {
    await tester.pumpWidget(host(const PageTopBar(topPadding: 0)));

    expect(find.byIcon(Icons.tune_rounded), findsNothing);
  });

  testWidgets('search toggle swaps icon while searching', (tester) async {
    await tester.pumpWidget(
      host(
        PageTopBar(
          topPadding: 0,
          onSearchTap: () {},
          isSearching: true,
          searchField: const TextField(),
        ),
      ),
    );

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/udl/page_top_bar_test.dart`
Expected: FAIL — the accent is the literal `0xFF7C5CFF` for every palette, so the `palette: last` assertion fails.

- [ ] **Step 3: Rewrite the implementation**

```dart
// lib/widgets/common/page_top_bar.dart
import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';

/// The single consistent top bar used across all pages: glass gradient,
/// logo + "PlayTorrio <Section>" title, search, and an optional filter
/// button with an active-count badge.
class PageTopBar extends StatelessWidget {
  final double topPadding;

  /// Section name rendered after "PlayTorrio" in the accent color.
  /// Pass null on the home page to show just "PlayTorrio".
  final String? title;

  final bool showBack;
  final VoidCallback? onBackTap;

  /// Toggled search: when [isSearching] is true, [searchField] replaces
  /// the logo/title and the trailing button becomes a close toggle.
  final VoidCallback? onSearchTap;
  final bool isSearching;
  final Widget? searchField;

  /// Filter button — hidden when null. Shows a count badge and turns
  /// accent-coloured when [filterCount] > 0.
  final VoidCallback? onFilterTap;
  final int filterCount;

  /// Extra buttons rendered between the title and the filter/search
  /// buttons (e.g. the home page's calendar button).
  final List<Widget> trailing;

  const PageTopBar({
    super.key,
    required this.topPadding,
    this.title,
    this.showBack = false,
    this.onBackTap,
    this.onSearchTap,
    this.isSearching = false,
    this.searchField,
    this.onFilterTap,
    this.filterCount = 0,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 430;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.only(
          top: topPadding + 2,
          bottom: 6,
          left: AppSpacing.md,
          right: 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tokens.bgPrimary.withValues(alpha: 0.96),
              tokens.bgPrimary.withValues(alpha: 0.90),
            ],
          ),
          border: Border(
            bottom: BorderSide(color: tokens.borderSubtle),
          ),
        ),
        child: Row(
          children: [
            if (showBack) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 17,
                  color: tokens.textPrimary,
                ),
                tooltip: 'Back',
                onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],

            if (isSearching && searchField != null)
              Expanded(child: searchField!)
            else ...[
              Image.asset(
                'assets/icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              if (!isNarrow)
                Flexible(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      text: 'PlayTorrio ',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: tokens.textPrimary,
                      ),
                      children: [
                        if (title != null)
                          TextSpan(
                            text: title!,
                            style: TextStyle(
                              color: tokens.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],

            if (!(isSearching && searchField != null)) const Spacer(),

            ...trailing,

            if (onFilterTap != null) ...[
              _buildFilterButton(context, tokens),
              const SizedBox(width: 6),
            ],

            if (onSearchTap != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: tokens.textPrimary.withValues(alpha: 0.75),
                  size: 21,
                ),
                tooltip: isSearching ? 'Close search' : 'Search',
                onPressed: onSearchTap,
              ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, PlayTorrioTokens tokens) {
    final isActive = filterCount > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onFilterTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: isActive ? tokens.accent : tokens.surfaceElevated,
          borderRadius: AppRadii.roundedButton,
          border: Border.all(
            color: isActive ? tokens.accent : tokens.borderSubtle,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.tune_rounded,
                size: 16,
                color: isActive ? tokens.onAccent : tokens.textSecondary,
              ),
            ),
            if (isActive)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3.5,
                    vertical: 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.onAccent,
                    borderRadius: AppRadii.roundedBadge,
                  ),
                  child: Text(
                    '$filterCount',
                    style: AppTypography.badge.copyWith(
                      fontSize: 8.5,
                      color: tokens.accent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/udl/page_top_bar_test.dart`
Expected: PASS (6/6).

- [ ] **Step 5: Commit**

```powershell
git add lib/widgets/common/page_top_bar.dart test/udl/page_top_bar_test.dart
git commit -m "refactor(udl): drive PageTopBar from tokens instead of fixed literals"
```

---

### Task 5: `ModernToast` semantic colours

**Files:**
- Modify: `lib/widgets/common/modern_toast.dart:147-215` (the `_buildGlassPill` method)
- Test: `test/udl/modern_toast_test.dart`
- Consumers: `player_screen.dart`, `text_sync_overlay.dart`.

`modern_toast.dart:148-164` is a colour map that duplicates `AppSemanticColors`. Spec §13 says those meanings live once, in the token layer.

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/modern_toast_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_semantic_colors.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/modern_toast.dart';

import '../widgets_ui/host.dart';

/// Pumps an empty host and hands back its [BuildContext] so the toast can be
/// inserted into the real root overlay, exactly as the player does.
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    host(
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return ctx;
}

Color? _iconColor(WidgetTester tester, IconData icon) =>
    tester.widget<Icon>(find.byIcon(icon)).color;

void main() {
  testWidgets('success toast uses the semantic success colour', (tester) async {
    final ctx = await _pumpHost(tester);
    ModernToast.show(ctx, message: 'Saved', type: ToastType.success);
    await tester.pump();

    expect(_iconColor(tester, Icons.check_circle_rounded), AppSemanticColors.success);

    ModernToast.dismiss();
    await tester.pump();
  });

  testWidgets('error toast uses the semantic error colour', (tester) async {
    final ctx = await _pumpHost(tester);
    ModernToast.show(ctx, message: 'Failed', type: ToastType.error);
    await tester.pump();

    expect(_iconColor(tester, Icons.cancel_rounded), AppSemanticColors.error);

    ModernToast.dismiss();
    await tester.pump();
  });

  testWidgets('info toast uses the active accent', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    final ctx = await _pumpHost(tester);
    ModernToast.show(ctx, message: 'Syncing');
    await tester.pump();

    expect(_iconColor(tester, Icons.subtitles_rounded), tokens.accent);

    ModernToast.dismiss();
    await tester.pump();
  });

  testWidgets('pill surface comes from the token surface', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    final ctx = await _pumpHost(tester);
    ModernToast.show(ctx, message: 'Syncing');
    await tester.pump();

    final pill = tester.widget<Container>(
      find.ancestor(of: find.text('Syncing'), matching: find.byType(Container)).first,
    );
    final decoration = pill.decoration! as BoxDecoration;
    expect(decoration.color, tokens.surface.withValues(alpha: 0.8));

    ModernToast.dismiss();
    await tester.pump();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/udl/modern_toast_test.dart`
Expected: FAIL — success resolves to `0xFF10B981`, not `AppSemanticColors.success` (`0xFF30A46C`).

- [ ] **Step 3: Replace `_buildGlassPill` (and its imports)**

```dart
// lib/widgets/common/modern_toast.dart — replace the import block
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../theme/app_elevation.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/playtorrio_tokens.dart';
```

```dart
// lib/widgets/common/modern_toast.dart — replace _buildGlassPill in full
  Widget _buildGlassPill(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);

    final (IconData icon, Color tone) = switch (widget.type) {
      ToastType.success => (Icons.check_circle_rounded, AppSemanticColors.success),
      ToastType.error => (Icons.cancel_rounded, AppSemanticColors.error),
      ToastType.info => (Icons.subtitles_rounded, tokens.accent),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderStrong),
            boxShadow: const [AppElevation.shadowMd],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tone, size: 18),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyStrong.copyWith(
                    color: tokens.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/udl/modern_toast_test.dart`
Expected: PASS (4/4).

- [ ] **Step 5: Commit**

```powershell
git add lib/widgets/common/modern_toast.dart test/udl/modern_toast_test.dart
git commit -m "refactor(udl): source ModernToast colours from the semantic allowlist"
```

---

### Task 6: Mechanical no-inline-colour guard for migrated files

**Files:**
- Create: `test/udl/no_inline_colors_test.dart`

The refactor's actual contract is "these files no longer name a colour". Assert it mechanically so a later edit cannot quietly reintroduce a literal.

- [ ] **Step 1: Write the failing test**

```dart
// test/udl/no_inline_colors_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Widgets migrated onto the token layer. Add to this list from each phase-2b
/// plan as files move across.
const List<String> migratedFiles = [
  'lib/widgets/common/poster_skeleton.dart',
  'lib/widgets/common/error_view.dart',
  'lib/widgets/common/section_header.dart',
  'lib/widgets/common/page_top_bar.dart',
  'lib/widgets/common/modern_toast.dart',
];

/// Matches a `Color(0x…)` literal or a `Colors.<name>` reference, without
/// flagging an identifier that merely ends in those words.
final RegExp _inlineColor = RegExp(
  r'(?<![A-Za-z0-9_])(?:Color\(\s*0x|Colors\.(?!transparent))',
);

void main() {
  test('migrated widgets contain no inline colour literals', () {
    final offenders = <String>[];

    for (final path in migratedFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path should exist');

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_inlineColor.hasMatch(lines[i])) {
          offenders.add('$path:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty, reason: 'Use PlayTorrioTokens/AppSemanticColors:\n${offenders.join('\n')}');
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/udl/no_inline_colors_test.dart`
Expected: PASS (1/1) — Tasks 1-5 already removed every literal. If this fails, the listed `file:line` still names a colour; fix that file before committing.

- [ ] **Step 3: Commit**

```powershell
git add test/udl/no_inline_colors_test.dart
git commit -m "test(udl): guard migrated phase-2b widgets against inline colours"
```

---

## Verification (run after Task 6)

- [ ] `flutter analyze` → 33 issues, all `info`, 0 warnings (unchanged from baseline).
- [ ] `flutter test test/udl test/widgets_ui` → all pass, zero failures.
- [ ] `flutter test` → no failure whose path contains `test/udl` or `test/widgets_ui`; the remaining failures are the pre-existing live-network set.
- [ ] Confirm each of the 5 consumer call sites still compiles unchanged: `grep -rn "PageTopBar\|ErrorView\|SectionHeader\|PosterSkeleton\|MissingPoster\|ModernToast" lib/` shows no signature edits needed.

## Self-Review

- **Spec coverage:** the design doc's phase-2 list names all five files; §13's allowlist is honoured (`modern_toast` now reads `AppSemanticColors`); §6.8 transparency is respected (no file gains an opaque full-screen background).
- **Type consistency:** `host()`, `AppTypography.screenTitle`, `AppRadii.roundedPoster`, `PlayTorrioTokens.of`, `AppSemanticColors.*`, `AppElevation.shadowMd`, `AppButtonVariant.tertiary`, `AppButtonSize.sm`, `SkeletonBox.radius` all exist as used above (verified against source).
- **Deferred, not done here:** `missingposter` duplicate in `manga_card.dart:402` is removed by plan B; `AppIconButton` is deliberately *not* used for the top-bar back/search controls because it always paints a raised surface and this bar is glass.
