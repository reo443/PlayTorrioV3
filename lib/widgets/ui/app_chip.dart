import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';

/// The fixed meanings a non-interactive [AppBadge] can carry.
///
/// Everything except [neutral] and [accent] comes from the design's allowlist
/// of semantic colours (spec 13): they must read the same way on every palette.
enum AppBadgeTone {
  neutral,
  accent,
  success,
  warning,
  error,
  rating,
  quality4k,
  qualityHd,
  qualitySd,
}

/// A selectable pill for filters and choices.
///
/// Selection is signalled by surface, border, and semantics - not by colour
/// alone.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final foreground = selected ? tokens.accent : tokens.textPrimary;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? tokens.surfaceSelected : tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.roundedChip,
          side: BorderSide(
            color: selected ? tokens.borderStrong : tokens.borderSubtle,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: AppRadii.roundedChip,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact metadata tag - resolution, codec, rating, status.
///
/// The [tone] colours the label and outlines the tag; the surface stays the
/// neutral theme surface so a wall of badges never becomes a wall of colour.
/// Badges are not interactive and are not focusable.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  Color _toneColor(PlayTorrioTokens tokens) => switch (tone) {
    AppBadgeTone.neutral => tokens.textSecondary,
    AppBadgeTone.accent => tokens.accent,
    AppBadgeTone.success => AppSemanticColors.success,
    AppBadgeTone.warning => AppSemanticColors.warning,
    AppBadgeTone.error => AppSemanticColors.error,
    AppBadgeTone.rating => AppSemanticColors.rating,
    AppBadgeTone.quality4k => AppSemanticColors.quality4k,
    AppBadgeTone.qualityHd => AppSemanticColors.qualityHd,
    AppBadgeTone.qualitySd => AppSemanticColors.qualitySd,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final color = _toneColor(tokens);

    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.roundedBadge,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.badge.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
