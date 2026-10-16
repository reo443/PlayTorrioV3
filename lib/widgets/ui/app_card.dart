import 'package:flutter/material.dart';

import '../../theme/app_elevation.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/playtorrio_tokens.dart';

/// The shared surface frame: the one place that decides what a "card" looks
/// like in this app.
///
/// Paints a themed surface - never the ambient [PlayTorrioTokens.bgPrimary],
/// which belongs to the app background layer behind the screen content.
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

  final Widget child;

  /// Defaults to [AppSpacing.lg] on every side.
  final EdgeInsetsGeometry? padding;

  /// When null the card is inert and renders no ink surface at all.
  final VoidCallback? onTap;

  final bool selected;

  /// Lifts the card onto the elevated surface tier with a depth shadow.
  final bool elevated;

  final bool bordered;

  /// Defaults to [AppRadii.roundedCard].
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final resolvedRadius = radius ?? AppRadii.roundedCard;
    final lifted = elevated || selected;

    final surface = elevated
        ? tokens.surfaceElevated
        : (selected ? tokens.surfaceSelected : tokens.surface);

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        boxShadow: lifted ? const [AppElevation.shadowSm] : null,
      ),
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: resolvedRadius,
          side: bordered
              ? BorderSide(
                  color: selected ? tokens.borderStrong : tokens.borderSubtle,
                )
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                borderRadius: resolvedRadius,
                onTap: onTap,
                child: content,
              ),
      ),
    );
  }
}
