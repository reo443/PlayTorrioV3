import 'package:flutter/material.dart';

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
  /// purple when [filterCount] > 0.
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
    final palette = Theme.of(context).colorScheme.brightness == Brightness.dark
        ? const Color(0xFF7C5CFF)
        : const Color(0xFF7C5CFF);
    final isNarrow = MediaQuery.sizeOf(context).width < 430;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.only(top: topPadding + 2, bottom: 6, left: 12, right: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF5080A0F), Color(0xE6080A0F)],
          ),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            if (showBack) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 17, color: Colors.white),
                tooltip: 'Back',
                onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 4),
            ],

            if (isSearching && searchField != null)
              Expanded(child: searchField!)
            else ...[
              Image.asset(
                'assets/icon.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              if (!isNarrow)
                Flexible(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      text: 'PlayTorrio ',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                      children: [
                        if (title != null)
                          TextSpan(
                            text: title!,
                            style: TextStyle(
                              color: palette,
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
              _buildFilterButton(context),
              const SizedBox(width: 6),
            ],

            if (onSearchTap != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.75),
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

  Widget _buildFilterButton(BuildContext context) {
    final isActive = filterCount > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onFilterTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF7C5CFF)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF7C5CFF)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.tune_rounded,
                size: 16,
                color: isActive ? Colors.white : Colors.white70,
              ),
            ),
            if (isActive)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 0.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$filterCount',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C5CFF),
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
