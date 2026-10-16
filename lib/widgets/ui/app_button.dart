import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';

/// Visual weights for [AppButton]. Semantics, not colours, are the contract —
/// each variant resolves its own colours from the active theme tokens.
enum AppButtonVariant { primary, secondary, tertiary, destructive }

/// Control sizes. Values are the surface *minimum* height; the surface grows
/// when the label needs more room (large system text scale) instead of clipping.
enum AppButtonSize { sm, md }

const double _heightSm = 36;
const double _heightMd = 44;

/// The platform minimum touch target. A visually smaller [AppButtonSize.sm]
/// surface is still surrounded by this much tappable area.
const double _minTapTarget = 44;

/// A themed button. Actions stand out through variant, not through size:
/// only [AppButtonVariant.primary] and [AppButtonVariant.destructive] paint a
/// saturated surface.
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

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonSize size;

  /// Stretches the button to the available width.
  final bool expand;

  /// Shows a progress indicator in place of the leading icon and blocks taps.
  final bool loading;

  bool get _enabled => onPressed != null && !loading;

  double get _minHeight => size == AppButtonSize.sm ? _heightSm : _heightMd;

  double get _horizontalPadding =>
      size == AppButtonSize.sm ? AppSpacing.lg : AppSpacing.xl;

  double get _verticalPadding =>
      size == AppButtonSize.sm ? AppSpacing.xs : AppSpacing.sm;

  Color _surface(PlayTorrioTokens tokens) {
    final base = switch (variant) {
      AppButtonVariant.primary => tokens.accent,
      AppButtonVariant.destructive => tokens.destructive,
      AppButtonVariant.secondary => tokens.surfaceElevated,
      AppButtonVariant.tertiary => Colors.transparent,
    };
    return _enabled ? base : base.withValues(alpha: 0.45);
  }

  Color _foreground(PlayTorrioTokens tokens) {
    if (!_enabled) return tokens.textTertiary;
    return switch (variant) {
      AppButtonVariant.primary => tokens.onAccent,
      AppButtonVariant.destructive => tokens.onAccent,
      AppButtonVariant.secondary => tokens.textPrimary,
      AppButtonVariant.tertiary => tokens.textPrimary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final foreground = _foreground(tokens);
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadii.roundedButton,
      side: variant == AppButtonVariant.secondary
          ? BorderSide(color: tokens.borderStrong)
          : BorderSide.none,
    );

    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: foreground),
        if (loading || icon != null) const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(color: foreground),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: 18, color: foreground),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minTapTarget),
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: label,
        child: Material(
          color: _surface(tokens),
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: AppRadii.roundedButton,
            onTap: _enabled ? onPressed : null,
            child: Container(
              constraints: BoxConstraints(minHeight: _minHeight),
              padding: EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
                vertical: _verticalPadding,
              ),
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-only button. [tooltip] is required so an icon-only control can never
/// ship without an accessible name.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final side = size == AppButtonSize.sm ? _heightSm : _heightMd;
    final enabled = onPressed != null;
    final foreground = selected
        ? tokens.onAccent
        : (enabled ? tokens.textPrimary : tokens.textTertiary);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minTapTarget),
          child: Material(
            color: selected
                ? tokens.accent
                : (enabled
                      ? tokens.surfaceElevated
                      : tokens.surfaceElevated.withValues(alpha: 0.45)),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.roundedButton,
              side: BorderSide(color: tokens.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: AppRadii.roundedButton,
              onTap: onPressed,
              child: SizedBox(
                width: side,
                height: side,
                child: Icon(icon, size: 20, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
