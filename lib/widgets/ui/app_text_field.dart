import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';

/// A themed single-line text input.
///
/// Focus, disabled, and error borders come from [InputDecoration]'s own state
/// handling, so the field reflects focus without keeping a [FocusNode] of its
/// own - which is what lets this stay a [StatelessWidget].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled = true,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.semanticsLabel,
  });

  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;

  /// Trailing widget, e.g. a clear affordance.
  final Widget? suffix;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool obscureText;
  final bool enabled;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final iconColor = enabled
        ? tokens.textSecondary
        : tokens.textTertiary.withValues(alpha: 0.6);

    OutlineInputBorder borderFor(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadii.roundedInput,
          borderSide: BorderSide(color: color, width: width),
        );

    final decoration = InputDecoration(
      filled: true,
      fillColor: enabled
          ? tokens.surface
          : tokens.surface.withValues(alpha: 0.5),
      hintText: hintText,
      hintStyle: AppTypography.body.copyWith(
        color: enabled
            ? tokens.textTertiary
            : tokens.textTertiary.withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: iconColor),
      suffixIcon: suffix,
      errorText: errorText,
      errorStyle: AppTypography.supporting.copyWith(color: tokens.error),
      border: borderFor(tokens.borderSubtle),
      enabledBorder: borderFor(tokens.borderSubtle),
      focusedBorder: borderFor(tokens.focusRing, 1.5),
      disabledBorder: borderFor(tokens.borderSubtle),
      errorBorder: borderFor(tokens.error),
      focusedErrorBorder: borderFor(tokens.error, 1.5),
    );

    final field = TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: tokens.accent,
      style: AppTypography.body.copyWith(
        color: enabled ? tokens.textPrimary : tokens.textTertiary,
      ),
      decoration: decoration,
    );

    final label = semanticsLabel;
    if (label == null) return field;
    return Semantics(label: label, textField: true, child: field);
  }
}

/// A search input: leading search icon, and a clear affordance that appears
/// only once there is something to clear.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.onClear,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;

    return AppTextField(
      controller: activeController,
      hintText: hintText,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      prefixIcon: Icons.search_rounded,
      suffix: activeController == null
          ? null
          : ValueListenableBuilder<TextEditingValue>(
              valueListenable: activeController,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Clear',
                  onPressed: () {
                    activeController.clear();
                    onClear?.call();
                  },
                );
              },
            ),
    );
  }
}
