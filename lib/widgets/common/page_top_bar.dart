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
