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
