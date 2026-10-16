import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';
import 'app_button.dart';

/// Dialogs stay narrower than the app's content column so a decision never
/// becomes a wall of text on a wide desktop window.
const double _dialogMaxWidth = 420;

/// The shared dialog chrome: elevated surface, title, optional message or
/// arbitrary content, and end-aligned actions.
///
/// Prefer [showAppDialog] for the common confirm/cancel case; this widget is
/// public so a caller can build a dialog with custom actions of its own.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
  });

  final String title;
  final String? message;

  /// Arbitrary body placed under [message].
  final Widget? content;

  /// Action buttons, laid out end-aligned.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
      child: Material(
        color: tokens.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.roundedSheet),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTypography.sectionHeading.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: AppTypography.supporting.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: AppSpacing.lg),
                content!,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.end,
                    children: actions,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows an [AppDialog] and resolves to `true` for confirm, `false` for
/// cancel, and `null` when the barrier is tapped instead.
///
/// The confirm button always exists; pass [cancelLabel] to add the escape
/// hatch, and [destructive] to colour the confirm action for an irreversible
/// decision.
Future<bool?> showAppDialog(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  String confirmLabel = 'OK',
  String? cancelLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AppDialog(
      title: title,
      message: message,
      content: content,
      actions: [
        if (cancelLabel != null)
          AppButton(
            label: cancelLabel,
            variant: AppButtonVariant.tertiary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
        AppButton(
          label: confirmLabel,
          variant: destructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
}
