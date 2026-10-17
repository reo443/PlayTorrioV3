import 'package:flutter/widgets.dart';

/// The fixed text colours of the settings type ramp.
///
/// These are deliberately **not** palette-derived. The settings screens use one
/// neutral grey ramp that has to read the same on every palette, and the ramp
/// lives in [SettingsText] as `const` styles, which cannot read per-context
/// tokens. Spec 13 therefore applies: the values are declared once, here,
/// instead of being repeated inline — and the no-inline-colours guard keeps it
/// that way.
///
/// If the settings screens should ever follow the palette, that is a design
/// change to the ramp (and to [SettingsText]'s API), not a tweak here.
abstract final class AppSettingsColors {
  /// Section label: the dimmest step, used for uppercase group headings.
  static const sectionLabel = Color(0xFF7E7E8C);

  /// Setting title: the brightest step.
  static const title = Color(0xFFF2F2F5);

  /// Setting description: the middle step, supporting the title.
  static const description = Color(0xFF8C8C98);

  /// Inactive / unselected option text.
  static const inactive = Color(0xFF9D9DAA);
}
