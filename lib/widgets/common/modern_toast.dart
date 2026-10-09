import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

enum ToastType { info, success, error }

/// Lightweight, modern floating toast that replaces ScaffoldMessenger
/// snackbars for transient in-player feedback.
///
/// Renders a glassy pill pinned near the top of the screen (below the
/// status bar), slides down + fades in with a soft overshoot, holds,
/// then fades out. A new toast replaces the current one.
class ModernToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    dismiss();
    _entry = OverlayEntry(
      builder: (_) => _ToastOverlay(message: message, type: type),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);

    _timer = Timer(duration + const Duration(milliseconds: 300), dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;

  const _ToastOverlay({
    required this.message,
    required this.type,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _inDuration = Duration(milliseconds: 280);
  static const _outDuration = Duration(milliseconds: 260);
  static const _holdDuration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _inDuration + _holdDuration + _outDuration,
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ModernToast.dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    final inT = _inDuration.inMilliseconds.toDouble();
    final outStart =
        (_inDuration + _holdDuration).inMilliseconds.toDouble();
    final total = _controller.duration!.inMilliseconds.toDouble();

    final opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: inT,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: outStart - inT,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: total - outStart,
      ),
    ]).animate(_controller);

    final slide = Tween<Offset>(
      begin: const Offset(0, -0.85),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0,
          inT / total,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    return Positioned(
      top: topInset + 14,
      left: 24,
      right: 24,
      child: Material(
        type: MaterialType.transparency,
        child: FadeTransition(
          opacity: opacity,
          child: SlideTransition(
            position: slide,
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 0.75,
                child: _buildGlassPill(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPill(BuildContext context) {
    final (icon, iconColor, iconBg) = switch (widget.type) {
      ToastType.success => (
        Icons.check_circle_rounded,
        const Color(0xFF10B981),
        const Color(0xFF10B981),
      ),
      ToastType.error => (
        Icons.cancel_rounded,
        const Color(0xFFF4436C),
        const Color(0xFFF4436C),
      ),
      ToastType.info => (
        Icons.subtitles_rounded,
        const Color(0xFF9D85FF),
        const Color(0xFF7C5CFF),
      ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xCC12151E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
