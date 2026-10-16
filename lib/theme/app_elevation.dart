import 'package:flutter/material.dart';

/// The single elevation vocabulary for dark surfaces.
///
/// [shadowSm]/[shadowMd] are neutral depth shadows; [glow] tints a shadow with
/// the active accent for focused/selected surfaces.
abstract final class AppElevation {
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static BoxShadow glow(Color accent) => BoxShadow(
        color: accent.withValues(alpha: 0.28),
        blurRadius: 22,
        spreadRadius: 0,
      );
}
