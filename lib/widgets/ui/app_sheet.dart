import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';

/// The shared bottom-sheet chrome: drag handle, header, and elevated surface
/// with the large-panel radius.
///
/// Use [AppSheet.show] to present one; the chrome is a plain widget so it can
/// also be embedded (previews, tests).
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.padding,
    this.leading,
  });

  final String? title;
  final String? subtitle;
  final Widget child;

  /// Defaults to [AppSpacing.xxl] on every side.
  final EdgeInsetsGeometry? padding;

  /// Optional widget placed before the title.
  final Widget? leading;

  /// Presents [builder] in a modal sheet using the shared chrome.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    String? subtitle,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      sheetAnimationStyle: const AnimationStyle(
        duration: AppMotion.sheet,
        curve: AppMotion.sheetCurve,
      ),
      builder: (context) => AppSheet(
        title: title,
        subtitle: subtitle,
        child: Builder(builder: builder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final hasHeader = title != null || leading != null;

    return Material(
      color: tokens.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  key: const Key('app_sheet_handle'),
                  width: AppSpacing.xxxl,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: tokens.borderSubtle,
                    borderRadius: AppRadii.roundedChip,
                  ),
                ),
              ),
              if (hasHeader) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: AppSpacing.md),
                    ],
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sectionHeading.copyWith(
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.supporting.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
