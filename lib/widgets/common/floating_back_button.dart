import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/theme/glass_settings.dart';
import '../../theme/playtorrio_tokens.dart';

/// The app's one back affordance.
///
/// A glass circle that floats over content: it reads on a poster, a hero band,
/// or a plain page, and it recolours with the palette instead of carrying its
/// own accent. Pages that already have a header row can drop it in place of
/// their hand-rolled `IconButton`; pages that draw their own floating chip put
/// it inside a [Positioned] and get the same control.
///
/// It hides itself when the route cannot be popped, so a pushed page always
/// has a way back and a root page never shows a dead control. Pass
/// [showWhenCannotPop] for the rare screen that wants the control regardless.
///
/// Glass is optional: with effects disabled it falls back to an opaque
/// elevated surface (spec 6.8), so the button never depends on the shader.
class FloatingBackButton extends StatefulWidget {
  const FloatingBackButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Back',
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.size = 44,
    this.showWhenCannotPop = false,
  });

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;

  final String tooltip;
  final IconData icon;

  /// Visual diameter. The tap target is always at least 48.
  final double size;

  final bool showWhenCannotPop;

  @override
  State<FloatingBackButton> createState() => _FloatingBackButtonState();
}

class _FloatingBackButtonState extends State<FloatingBackButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (!canPop && !widget.showWhenCannotPop) return const SizedBox.shrink();

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
            onTap: widget.onPressed ?? () => Navigator.of(context).maybePop(),
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
                      diameter: widget.size,
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

  Widget _disc({
    required PlayTorrioTokens tokens,
    required bool glass,
    required double diameter,
  }) {
    final rim = Border.all(
      color: glass
          ? tokens.textPrimary.withValues(alpha: 0.18)
          : tokens.borderStrong,
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
      size: diameter * 0.41,
      color: tokens.textPrimary,
    );

    if (!glass) {
      return Container(
        width: diameter,
        height: diameter,
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
      width: diameter,
      height: diameter,
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
