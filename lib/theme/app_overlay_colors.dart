import 'package:flutter/painting.dart';

/// Fixed colours for surfaces that are not the app surface.
///
/// These are user choices or structural overlays rather than palette values,
/// so they are declared once here instead of as literals at the call site.
abstract final class AppOverlayColors {
  /// The user-selected "Pure Black" details background
  /// (`DetailsBackground.black`). A deliberate true black, not a palette tint.
  static const Color pureBlack = Color(0xFF000000);
}
