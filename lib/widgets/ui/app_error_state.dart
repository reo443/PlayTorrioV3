import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';
import 'app_button.dart';

/// The shared failure panel.
///
/// Generalises the older hardcoded-title error view: [title] is the caller's,
/// so the same component can report a failed catalogue, a failed search, or a
/// failed stream lookup.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    required this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String? message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: tokens.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.sectionHeading.copyWith(
              color: tokens.textPrimary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.supporting.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: retryLabel, onPressed: onRetry),
        ],
      ),
    );
  }
}
