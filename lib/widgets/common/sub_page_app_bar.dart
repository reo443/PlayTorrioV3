import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/theme/glass_settings.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';
import 'floating_back_button.dart';

/// The top bar for pushed sub-pages: settings, downloads, and every other
/// screen that is one step inside the app.
///
/// It replaces the stock Material [AppBar] those pages used to build by hand.
/// The shape is deliberately quiet — the same glass disc the app already uses
/// for back, a large left-aligned title, and a hairline instead of a shadow —
/// so it reads as part of the page rather than a slab on top of it.
///
/// It is a [PreferredSizeWidget], so a page keeps its `appBar:` slot:
///
/// ```dart
/// Scaffold(
///   appBar: SubPageAppBar(
///     title: 'Appearance',
///     topInset: MediaQuery.paddingOf(context).top,
///   ),
/// )
/// ```
///
/// [topInset] is passed in rather than read from the context because
/// [preferredSize] is evaluated without one — the same contract [PageTopBar]
/// uses. Glass is optional: with effects disabled the bar paints the plain
/// page colour (spec 6.8).
///
/// Three escape hatches keep the bar usable on pages with a bespoke header
/// without forking it: [titleLeading] for a marker or icon before the title,
/// [titleWidget] when the title is not text (a search field), and [bottom] for
/// a tab bar or status strip.
class SubPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SubPageAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.titleLeading,
    this.subtitle,
    this.topInset = 0,
    this.actions = const [],
    this.bottom,
    this.onBack,
    this.showBack = true,
    this.height = 64,
  }) : assert(
          title != null || titleWidget != null,
          'SubPageAppBar needs a title or a titleWidget',
        );

  /// The page name, rendered in [AppTypography.screenTitle].
  final String? title;

  /// Replaces the text title entirely — use it when the header is a control,
  /// such as the search field on the IPTV search page.
  final Widget? titleWidget;

  /// Sits immediately before the title, e.g. a section icon or an accent bar.
  final Widget? titleLeading;

  /// Optional second line, e.g. the number of results on a filtered page.
  final String? subtitle;

  /// Status-bar padding. Pass `MediaQuery.paddingOf(context).top`.
  final double topInset;

  /// Trailing controls, right-aligned in the bar.
  final List<Widget> actions;

  /// Extra content below the title row, such as a [TabBar].
  final PreferredSizeWidget? bottom;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  final bool showBack;

  /// Height of the content row, excluding [topInset] and [bottom].
  final double height;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + topInset + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);

    final content = Padding(
      padding: EdgeInsets.only(top: topInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height,
            child: Row(
              children: [
                const SizedBox(width: 4),
                if (showBack) ...[
                  FloatingBackButton(onPressed: onBack),
                  const SizedBox(width: 4),
                ],
                if (titleLeading != null) ...[
                  titleLeading!,
                  const SizedBox(width: 12),
                ],
                Expanded(child: titleWidget ?? _title(tokens)),
                ...actions,
                const SizedBox(width: 12),
              ],
            ),
          ),
          if (bottom != null)
            SizedBox(
              height: bottom!.preferredSize.height,
              child: bottom!,
            ),
        ],
      ),
    );

    return Container(
      // Foreground, not decoration: a decoration border would shrink the
      // child by its width and make the fixed-height row overflow. When there
      // is a bottom row, its own divider already separates it from the page.
      foregroundDecoration: bottom == null
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
            )
          : null,
      child: ValueListenableBuilder<bool>(
        valueListenable: GlassSettings.enabled,
        builder: (context, glass, child) {
          if (!glass) return ColoredBox(color: tokens.bgPrimary, child: child);

          return ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: ColoredBox(
                color: tokens.bgPrimary.withValues(alpha: 0.82),
                child: child,
              ),
            ),
          );
        },
        child: content,
      ),
    );
  }

  Widget _title(PlayTorrioTokens tokens) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.screenTitle.copyWith(color: tokens.textPrimary),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: tokens.textSecondary),
          ),
      ],
    );
  }
}
