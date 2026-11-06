import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'glass_circle_button.dart';

/// One extra floating action beside the search disc.
class FloatingPageAction {
  const FloatingPageAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Marks a toggle that is currently on, such as fullscreen.
  final bool isActive;
}

/// The floating controls that replace the old full-width top bar.
///
/// A page drops this into its overlay stack anchored top-right:
///
/// ```dart
/// Positioned(
///   top: 0,
///   right: AppSpacing.md,
///   child: FloatingPageActions(
///     topInset: MediaQuery.paddingOf(context).top,
///     onSearchTap: _openSearch,
///   ),
/// )
/// ```
///
/// Search is always first; [actions] stack beneath it in order. The widgets
/// are transparent to taps outside their own 48pt targets, so the content
/// behind them stays interactive.
class FloatingPageActions extends StatelessWidget {
  const FloatingPageActions({
    super.key,
    required this.topInset,
    this.onSearchTap,
    this.searchTooltip = 'Search',
    this.actions = const [],
  });

  /// Status-bar padding. Pass `MediaQuery.paddingOf(context).top`.
  final double topInset;

  /// Search is hidden when null.
  final VoidCallback? onSearchTap;

  final String searchTooltip;

  /// Extra controls, rendered under the search disc in list order.
  final List<FloatingPageAction> actions;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (onSearchTap != null)
        GlassCircleButton(
          icon: Icons.search_rounded,
          tooltip: searchTooltip,
          onPressed: onSearchTap!,
        ),
      for (final action in actions)
        GlassCircleButton(
          icon: action.icon,
          tooltip: action.tooltip,
          onPressed: action.onTap,
          isActive: action.isActive,
        ),
    ];

    return Padding(
      padding: EdgeInsets.only(top: topInset + AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            buttons[i],
          ],
        ],
      ),
    );
  }
}
