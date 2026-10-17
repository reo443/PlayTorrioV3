import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_settings_colors.dart';
import '../../theme/playtorrio_tokens.dart';

/// Typography tokens for settings screens (system font, spec sizes/weights).
///
/// The colours come from [AppSettingsColors] because these styles are `const`
/// and a `const` style cannot read per-context tokens.
abstract final class SettingsText {
  /// Section label: 12px, w700, uppercase, letter-spacing 0.09em.
  static const sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
    color: AppSettingsColors.sectionLabel,
  );

  /// Setting title: 15px, w700.
  static const title = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppSettingsColors.title,
  );

  /// Setting description: 13px, w500.
  static const description = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppSettingsColors.description,
  );

  /// Inactive / unselected option text.
  static const inactive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppSettingsColors.inactive,
  );
}

/// Segmented option picker: a wrapping track with equal-width buttons.
/// The selected option is indicated by fill alone — no outlined chips and
/// no checkmark icons. Accent color follows the active theme palette.
class SettingsSegmentedControl<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) label;
  final String? semanticsLabel;

  /// Optional per-value widget rendered before the label (e.g. a small
  /// color swatch). Keeps indicator context that plain text labels lose.
  final Widget Function(T value)? indicator;

  const SettingsSegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.label,
    this.semanticsLabel,
    this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    // 3+ options (or long labels) use a smaller font and may wrap 2 lines.
    final compact = values.length >= 3;
    final fontSize = compact ? 13.0 : 14.0;
    final tokens = PlayTorrioTokens.of(context);

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: tokens.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.borderStrong),
        ),
        child: Row(
          children: [
            for (var i = 0; i < values.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _SegmentedButton<T>(
                  value: values[i],
                  isSelected: values[i] == selected,
                  label: label(values[i]),
                  indicator: indicator?.call(values[i]),
                  fontSize: fontSize,
                  maxLines: compact ? 2 : 1,
                  onTap: () => onChanged(values[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentedButton<T> extends StatelessWidget {
  final T value;
  final bool isSelected;
  final String label;
  final Widget? indicator;
  final double fontSize;
  final int maxLines;
  final VoidCallback onTap;

  const _SegmentedButton({
    required this.value,
    required this.isSelected,
    required this.label,
    this.indicator,
    required this.fontSize,
    required this.maxLines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final accent = tokens.accent;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? accent : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (indicator != null) ...[
                  indicator!,
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.3,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? tokens.onAccent
                          : AppSettingsColors.inactive,
                    ),
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

/// Toggle switch: 44x26 track with a 20px white thumb. On-state follows the
/// active theme accent. Exposed as a real button with a descriptive
/// accessibility label, with a ≥44px touch target. Pass a null [onChanged]
/// to render the switch in a disabled state.
class SettingsToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticsLabel;

  const SettingsToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final accent = tokens.accent;
    final enabled = onChanged != null;

    return Semantics(
      button: true,
      toggled: value,
      label: semanticsLabel,
      enabled: enabled,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(value ? false : true),
          borderRadius: AppRadii.roundedChip,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                color: !enabled
                    ? tokens.textPrimary.withValues(alpha: 0.08)
                    : value
                    ? accent
                    : tokens.textPrimary.withValues(alpha: 0.15),
                borderRadius: AppRadii.roundedChip,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.only(left: value ? 21 : 3),
                  // Stays light in both states, so it cannot follow the
                  // accent's contrast colour the way an accent-filled surface
                  // would.
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full setting row: title, optional description, and the toggle switch.
/// Uses the spec typography (title 15/w700, description 13/w500).
class SettingsToggleRow extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleRow({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: SettingsText.title),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(description!, style: SettingsText.description),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SettingsToggleSwitch(
            value: value,
            onChanged: onChanged,
            semanticsLabel: label,
          ),
        ],
      ),
    );
  }
}
