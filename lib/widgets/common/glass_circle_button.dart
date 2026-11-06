import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/theme/glass_settings.dart';
import '../../theme/playtorrio_tokens.dart';

/// A circular glass icon button that floats over content.
///
/// This is the app's one floating control shape: [FloatingBackButton] uses it
/// for back, and page headers use it for search and the other top-level
/// actions. It recolours with the palette instead of carrying its own accent.
///
/// Glass is optional: with effects disabled it paints an opaque elevated
/// surface (spec 6.8), so the control never depends on the shader.
class GlassCircleButton extends StatefulWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Visual diameter. The tap target is always at least 48.
  final double size;

  /// Marks a toggle that is currently on (e.g. fullscreen) with the accent.
  final bool isActive;

  @override
  State<GlassCircleButton> createState() => _GlassCircleButtonState();
}

class _GlassCircleButtonState extends State<GlassCircleButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final scale = _pressed ? 0.92 : (_hovered ? 1.04 : 1.0);

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: GlassSettings.enabled,
                    builder: (context, glass, _) => _disc(
                      tokens: tokens,
                      glass: glass,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _disc({required PlayTorrioTokens tokens, required bool glass}) {
    final rim = Border.all(
      color: widget.isActive
          ? tokens.accent.withValues(alpha: 0.6)
          : (glass
              ? tokens.textPrimary.withValues(alpha: 0.18)
              : tokens.borderStrong),
    );
    final glow = [
      BoxShadow(
        color: tokens.bgPrimary.withValues(alpha: 0.45),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
      if (_hovered)
        BoxShadow(
          color: tokens.accent.withValues(alpha: 0.28),
          blurRadius: 22,
          spreadRadius: 1,
        ),
    ];

    final icon = Icon(
      widget.icon,
      size: widget.size * 0.41,
      color: widget.isActive ? tokens.accent : tokens.textPrimary,
    );

    if (!glass) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tokens.surfaceElevated,
          border: rim,
          boxShadow: glow,
        ),
        child: Center(child: icon),
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: glow),
      // The rim sits on top of the blurred fill, otherwise the child paints
      // over it and the edge disappears.
      foregroundDecoration: BoxDecoration(shape: BoxShape.circle, border: rim),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ColoredBox(
            color: tokens.surface.withValues(alpha: 0.55),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
