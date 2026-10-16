# SDD ledger — plan: docs/superpowers/plans/2026-10-16-udl-phase1-tokens.md

## Setup
- Branch: `main` (repo's established working pattern; prior work committed here by the partner).
- Workspace: `.superpowers/sdd/2026-10-16-udl-phase1-tokens/` (scratch).
- Ruling: Execute on `main` (no worktree) — matches the partner's established workflow. Cost if wrong: none (no commits are made by the executor; see next ruling).
- Ruling: Do NOT run the plan's `git commit` steps — partner's AGENTS.md forbids committing unless explicitly asked; the partner commits their own work. Cost if wrong: partner just runs the listed commit messages themselves.
- Pre-flight shared-interface scan:
  - Task 4 → Task 5: Task 4 produces `PlayTorrioTokens.fromPalette` + the 19 token fields and adds `AppThemePalette.backgroundSecondaryColor`/`surfaceElevatedColor` (with defaults); Task 5 consumes those exact names and gives per-palette values. Names/signatures match. No conflict.
  - Task 1/2/3 are independent leaves (scales, typography, semantic colors); no cross-consumption. No conflict.
  - Ruling: none needed — no conflicts found.

## Progress
- Task 1: complete (tests: flutter test test/theme/app_scales_test.dart → 4/4 pass). Not committed (partner commits).
- Task 2: Ruling: plan's test omitted `import 'package:flutter/material.dart'` needed for `FontWeight` — added the import. Cost if wrong: none (plan typo).
- Task 2: complete (tests: flutter test test/theme/app_typography_test.dart → 2/2 pass). Not committed (partner commits).
- Task 3: complete (tests: flutter test test/theme/app_semantic_colors_test.dart → 1/1 pass). Not committed (partner commits).
- Task 4: Ruling: plan's test was self-contradictory — the loop asserted `onAccent = (lum > 0.5) ? black : white` while the anchor asserted amber(0xFFF59E0B, lum 0.439)→black; no threshold satisfies both the 0.5 literal and both anchors. Spec §6.1 says "whichever contrasts best"; chose threshold 0.4 (in the satisfiable window 0.192–0.439), which keeps 7/8 palettes as-is and matches the spec's amber example. Changed the one loop literal `0.5`→`0.4` and implemented `> 0.4`. Cost if wrong: amber (and any future palette with luminance in 0.4–0.5) uses a slightly less-optimal foreground; visually minor, trivially retunable.
- Task 4: complete (tests: flutter test test/theme/playtorrio_tokens_test.dart → 4/4 pass). AppThemePalette gained backgroundSecondaryColor/surfaceElevatedColor (defaults). Not committed (partner commits).
- Task 5: Ruling: plan's lerp test used `a.lerp(b, 0.5) as PlayTorrioTokens`; my override narrows the return type to `PlayTorrioTokens`, so the cast was flagged `unnecessary_cast` (a new warning over baseline) — removed the cast. Cost if wrong: none.
- Task 5: complete (tests: flutter test test/theme/app_theme_service_tokens_test.dart → 5/5 pass; flutter analyze → 33 infos / 0 warnings; full suite → 292 pass / 14 fail, all 14 pre-existing network/format). Not committed (partner commits).

## Final review (reviewer verdict: With fixes)
- Final: fixed onAccent contrast (Critical, Review Focus #2) — added a WCAG contrast floor (>= 4.0) to 'onAccent picks a readable foreground on every palette'; RED at threshold 0.4 (cyberpunk 3.55, emerald 2.54), lowered threshold 0.4 → 0.2 → GREEN. Anchors preserved (amethyst white, amber black). suite: test/theme 17/17; full 292 pass / 15 fail (all pre-existing).
- Final: fixed missing live-recolor pin (Important, Review Focus #1) — added widget test 'changing the palette recolors tokens through the tree' mirroring main.dart's ValueListenableBuilder; passes (behavior already correct; the gap was coverage, so no RED was possible).
- Final: Ruling: reviewer's Important finding #1 — "only a subset of ColorScheme roles is overridden; surfaceContainer*/outline/onError stay seed-derived (purple)" — DEFERRED by partner decision to a later phase (fits Phase 2 shared-components so the whole ColorScheme becomes palette-driven in one deliberate pass). It remains a plan-scoped gap (plan Task 5 Step 3 lists the subset; the plan's rationale overclaims "every visible role"). Cost if wrong: M3 container/outline/error widgets render seed-tonal (purple-ish) instead of palette-consistent until that phase.
- Final: minor (deferred): circular import app_theme_service <-> playtorrio_tokens (safe; lazy, no const cycle).
- Final: minor (deferred): onSecondary = onAccent (computed from primaryColor) though secondary = accentColor (different luminance).
- Final: minor (deferred): surfaceSelected / copyWith / lerp barely asserted (lerp only checks accent).
- Final: minor (deferred): w800 is synthesized — Poppins bundled at 400/500/600/700 only.
- Final: workspace retained (NOT deleted) — the executor made no git commits, so the ledger is the only durable record of the rulings.

