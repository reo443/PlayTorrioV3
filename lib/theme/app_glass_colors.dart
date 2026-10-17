import 'package:flutter/widgets.dart';

/// The fixed colours of the glass material.
///
/// Glass is white light refracted through a surface, so these values are
/// palette-independent by construction — a palette-tinted "glass" would just be
/// a tinted panel. Spec 13 applies: they are declared once, here, so the glass
/// engine and the widgets that draw it share one definition instead of
/// repeating the literals inline.
///
/// [shadow] is the exception that proves the rule: a drop shadow under a glass
/// surface is cast by the surface, not by the light passing through it, so it
/// stays a fixed black wash.
abstract final class AppGlassColors {
  /// Drop shadow cast by a raised glass surface.
  static const shadow = Color(0x66000000);

  /// The bright rim that reads as the edge of the glass.
  static const edge = Color(0x24FFFFFF);

  /// Glyph / icon colour on top of the glass.
  static const glyph = Color(0xF2FFFFFF);

  /// Muted glyph, e.g. the dock's scroll arrows.
  static const glyphMuted = Color(0xB3FFFFFF);

  /// Gradient stops of the non-glass fallback surface, at rest.
  static const fallbackRest = [Color(0x24FFFFFF), Color(0x12FFFFFF)];

  /// Gradient stops of the non-glass fallback surface, while hovered.
  static const fallbackHover = [Color(0x38FFFFFF), Color(0x1FFFFFFF)];

  /// Border of the non-glass fallback surface.
  static const fallbackBorder = Color(0x26FFFFFF);
}
