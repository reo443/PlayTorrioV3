import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/anime/anime_media.dart';
import '../../theme/playtorrio_tokens.dart';
import '../common/poster_skeleton.dart';
import '../ui/app_chip.dart';

class AnimeCard extends StatefulWidget {
  final AnimeMedia anime;
  final VoidCallback onTap;
  final double? width;

  const AnimeCard({
    super.key,
    required this.anime,
    required this.onTap,
    this.width,
  });

  @override
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final anime = widget.anime;
    final tokens = PlayTorrioTokens.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.97 : (_hovered ? 1.045 : 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster Frame
                Expanded(
                  child: _AnimePosterFrame(
                    anime: anime,
                    hovered: _hovered,
                  ),
                ),

                // Title
                const SizedBox(height: 9),
                Text(
                  anime.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                    color: tokens.textPrimary,
                  ),
                ),

                // Year / Format / Genre
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (anime.seasonYear > 0) ...[
                      Text(
                        '${anime.seasonYear}',
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: tokens.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        anime.genres.isNotEmpty
                            ? anime.genres.first
                            : anime.formattedFormat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimePosterFrame extends StatelessWidget {
  final AnimeMedia anime;
  final bool hovered;

  const _AnimePosterFrame({
    required this.anime,
    required this.hovered,
  });

  @override
  Widget build(BuildContext context) {
    final posterUrl = anime.coverUrl;
    final hasPoster = posterUrl.isNotEmpty;
    final tokens = PlayTorrioTokens.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: tokens.bgPrimary.withValues(alpha: hovered ? 0.60 : 0.34),
            blurRadius: hovered ? 32 : 20,
            offset: Offset(0, hovered ? 18 : 10),
          ),
          if (hovered)
            BoxShadow(
              color: tokens.accent.withValues(alpha: 0.28),
              blurRadius: 34,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: tokens.surfaceElevated),

            // Poster Image
            if (hasPoster)
              CachedNetworkImage(
                imageUrl: posterUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                placeholder: (context, url) => const PosterSkeleton(),
                errorWidget: (context, url, error) => const MissingPoster(),
              )
            else
              const MissingPoster(),

            // Vignette Gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      tokens.bgPrimary.withValues(alpha: 0.20),
                    ],
                  ),
                ),
              ),
            ),

            // Top Left Rating Badge (score, or popularity fallback for
            // unreleased titles like "Anticipated Next Season" that have no
            // average score yet)
            if (anime.averageScore > 0)
              Positioned(
                top: 9,
                left: 9,
                child: AppBadge(
                  label: anime.formattedScore,
                  tone: AppBadgeTone.rating,
                  icon: Icons.star_rounded,
                ),
              )
            else if (anime.popularity > 0)
              Positioned(
                top: 9,
                left: 9,
                child: AppBadge(
                  label: anime.formattedPopularity,
                  tone: AppBadgeTone.warning,
                  icon: Icons.local_fire_department_rounded,
                ),
              ),

            // Top Right Format Pill (compact — never wide enough to reach
            // the rating badge on narrow posters)
            Positioned(
              top: 9,
              right: 9,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 74),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: tokens.accent.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      anime.formatTag,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: tokens.onAccent,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Overlay with Episode Count
            if (anime.totalEpisodes > 0)
              Positioned(
                bottom: 9,
                left: 9,
                child: AppBadge(label: '${anime.totalEpisodes} EPS'),
              ),

            // Hover Play Glow Icon
            if (hovered)
              Positioned(
                bottom: 9,
                right: 9,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: tokens.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: tokens.onAccent,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
