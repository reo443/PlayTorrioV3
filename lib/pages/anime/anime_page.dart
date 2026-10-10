import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../models/anime/anime_media.dart';
import '../../services/anime/anilist_service.dart';
import '../../services/anime/anime_library_service.dart';
import '../../services/theme/app_theme_service.dart';
import '../../services/theme/dock_settings.dart';
import '../../services/theme/glass_settings.dart';
import '../../utils/navigation/route_transitions.dart';
import '../../widgets/anime/anime_slider_section.dart';
import '../../widgets/common/animated_ambient_background.dart';
import '../../widgets/common/app_liquid_dock.dart';
import '../../widgets/common/custom_scroll_track.dart';
import '../../widgets/common/page_top_bar.dart';
import '../../widgets/home/continue_watching_slider.dart';
import '../settings/settings_page.dart';
import 'anime_details_page.dart';
import 'anime_stream_sheet.dart';
import 'anime_search_page.dart';

class AnimePage extends StatefulWidget {
  const AnimePage({super.key});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage> {
  final AnilistService _anilistService = AnilistService.instance;
  final AnimeLibraryService _libraryService = AnimeLibraryService.instance;
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _error;

  // General Anime data
  List<AnimeMedia> _popularSeason = [];
  List<AnimeMedia> _topRated = [];
  List<AnimeMedia> _upcoming = [];
  List<AnimeMedia> _trendingToday = [];
  List<AnimeMedia> _trendingWeek = [];
  List<AnimeMedia> _newEpisodes = [];

  @override
  void initState() {
    super.initState();
    _libraryService.addListener(_onLibraryChanged);
    _libraryService.init();
    _loadAnimeData();
  }

  @override
  void dispose() {
    _libraryService.removeListener(_onLibraryChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAnimeData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final seasonFut = _anilistService.fetchPopularThisSeason(perPage: 18);
      final topRatedFut = _anilistService.fetchTopRated(perPage: 18);
      final upcomingFut = _anilistService.fetchUpcomingNextSeason(perPage: 18);
      final trendingTodayFut = _anilistService.fetchRecentlyAired(
        window: const Duration(days: 1),
        sortByPopularity: true,
      );
      final trendingWeekFut = _anilistService.fetchRecentlyAired(
        window: const Duration(days: 7),
        maxPages: 4,
        sortByPopularity: true,
      );
      final newEpisodesFut = _anilistService.fetchRecentlyAired(
        window: const Duration(days: 1),
        sortByPopularity: false,
      );

      final results = await Future.wait([
        seasonFut,
        topRatedFut,
        upcomingFut,
        trendingTodayFut,
        trendingWeekFut,
        newEpisodesFut,
      ]);

      if (mounted) {
        final hasAnyData = results.any((list) => list.isNotEmpty);
        setState(() {
          _popularSeason = results[0];
          _topRated = results[1];
          _upcoming = results[2];
          _trendingToday = results[3];
          _trendingWeek = results[4];
          _newEpisodes = results[5];
          _loading = false;
          if (!hasAnyData) {
            _error = 'Failed to load Anime catalog. Please check your internet connection or retry.';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading Anime data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load Anime catalog. Check your internet connection.';
          _loading = false;
        });
      }
    }
  }

  void _playEpisode(AnimeMedia anime, int episodeNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AnimeStreamSheet(
        anime: anime,
        episodeNumber: episodeNumber,
        autoPlay: false,
      ),
    );
  }

  void _openDetails(AnimeMedia anime, [int? preferredEpisode]) {
    Navigator.push(
      context,
      CinematicSlideRoute(
        page: AnimeDetailsPage(anime: anime),
      ),
    );
  }

  void _navigateToSettings(Offset? tapPosition) {
    Navigator.push(
      context,
      LiquidRevealRoute(
        page: const SettingsPage(),
        tapPosition: tapPosition,
      ),
    );
  }

  void _navigateToSearch(Offset? tapPosition) {
    Navigator.push(
      context,
      LiquidRevealRoute(
        page: const AnimeSearchPage(),
        tapPosition: tapPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ValueListenableBuilder<AppThemePalette>(
      valueListenable: AppThemeService.currentPalette,
      builder: (context, palette, _) {
        final backgroundContent = AnimatedAmbientBackground(
          child: Stack(
            children: [
              // Main scrollable content
              if (_loading && _trendingWeek.isEmpty)
                Center(
                  child: CircularProgressIndicator(color: palette.primaryColor),
                )
              else if (_error != null && _trendingWeek.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primaryColor,
                        ),
                        onPressed: _loadAnimeData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                RefreshIndicator(
                  color: palette.primaryColor,
                  backgroundColor: palette.cardBackgroundColor,
                  onRefresh: _loadAnimeData,
                  child: ListView(
                    controller: _scrollController,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      // 1. Full Bleed Hero Carousel (Matching Home Page)
                      if ((_trendingToday.isNotEmpty || _trendingWeek.isNotEmpty || _topRated.isNotEmpty))
                        _AnimeHeroCarousel(
                          animeList: (_trendingToday.isNotEmpty
                                  ? _trendingToday
                                  : (_trendingWeek.isNotEmpty ? _trendingWeek : _topRated))
                              .take(6)
                              .toList(),
                          onWatchNow: (anime) => _playEpisode(anime, 1),
                          onDetailsTap: _openDetails,
                        ),

                      const SizedBox(height: 16),

                      // 2. Anime Continue Watching Slider
                      const ContinueWatchingSlider(
                        typeFilter: 'general_anime',
                        title: 'Continue Watching',
                      ),

                      const SizedBox(height: 8),

                      // 3. Sliders with Desktop Scroll Arrows
                      if (_trendingToday.isNotEmpty)
                        AnimeSliderSection(
                          title: 'Trending Today',
                          animeList: _trendingToday,
                          onAnimeTap: _openDetails,
                        ),
                      if (_trendingWeek.isNotEmpty)
                        AnimeSliderSection(
                          title: 'Trending This Week',
                          animeList: _trendingWeek,
                          onAnimeTap: _openDetails,
                        ),
                      if (_newEpisodes.isNotEmpty)
                        AnimeSliderSection(
                          title: 'New Episodes',
                          animeList: _newEpisodes,
                          onAnimeTap: _openDetails,
                        ),
                      AnimeSliderSection(
                        title: 'Popular This  ${AnilistService.currentSeason()}',
                        animeList: _popularSeason,
                        onAnimeTap: _openDetails,
                      ),
                      AnimeSliderSection(
                        title: 'All-Time Masterpieces',
                        animeList: _topRated,
                        onAnimeTap: _openDetails,
                      ),
                      AnimeSliderSection(
                        title: 'Anticipated Next Season',
                        animeList: _upcoming,
                        onAnimeTap: _openDetails,
                      ),
                     

                      SizedBox(height: 110.0 + MediaQuery.paddingOf(context).bottom),
                    ],
                  ),
                ),
            ],
          ),
        );

        final overlayChildren = <Widget>[
          // Floating Glass App Bar (Home Page Style)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PageTopBar(
              topPadding: topPadding,
              title: 'Anime',
              onSearchTap: () => _navigateToSearch(null),
            ),
          ),

          // Custom Scroll Track (Matching Home Page)
          if (MediaQuery.sizeOf(context).width > 800)
            Positioned(
              right: 24,
              bottom: 40,
              child: CustomScrollTrack(controller: _scrollController),
            ),

          // Liquid Dock Navbar (Home Page Style)
          Positioned(
            bottom: 12.0 + MediaQuery.paddingOf(context).bottom,
            left: 0,
            right: 0,
            child: Center(
              child: AppLiquidDock(
                currentDestination: DockItemKey.anime,
                onSettingsTap: () => _navigateToSettings(null),
                onSearchTap: () => _navigateToSearch(null),
              ),
            ),
          ),
        ];

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ValueListenableBuilder<bool>(
            valueListenable: GlassSettings.enabled,
            builder: (context, enabled, _) {
              final overlays = Stack(children: overlayChildren);
              if (enabled) {
                return LiquidGlassView(
                  realTimeCapture: true,
                  useSync: true,
                  pixelRatio: 0.85,
                  refreshRate: LiquidGlassRefreshRate.deviceRefreshRate,
                  regionCapture: true,
                  backgroundWidget: backgroundContent,
                  child: overlays,
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(child: backgroundContent),
                  ...overlayChildren,
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-Bleed Anime Hero Carousel (Matching Home Page _HeroCarousel)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimeHeroCarousel extends StatefulWidget {
  final List<AnimeMedia> animeList;
  final Function(AnimeMedia) onWatchNow;
  final Function(AnimeMedia) onDetailsTap;

  const _AnimeHeroCarousel({
    required this.animeList,
    required this.onWatchNow,
    required this.onDetailsTap,
  });

  @override
  State<_AnimeHeroCarousel> createState() => _AnimeHeroCarouselState();
}

class _AnimeHeroCarouselState extends State<_AnimeHeroCarousel> {
  static const _rotateEvery = Duration(seconds: 8);
  final PageController _pageController = PageController();

  Timer? _timer;
  int _index = 0;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.animeList.length < 2) return;
    _timer = Timer.periodic(_rotateEvery, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_index + 1) % widget.animeList.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseTimer() => _timer?.cancel();

  void _goTo(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  double _heroHeight(double screenWidth, double screenHeight) {
    if (screenWidth < 600) {
      return (screenHeight * 0.68).clamp(460.0, 640.0);
    } else if (screenWidth < 1100) {
      return (screenHeight * 0.70).clamp(520.0, 740.0);
    } else {
      // Maximized / Widescreen Desktop: give generous height
      final targetHeight = screenHeight * 0.82;
      return targetHeight.clamp(620.0, 1050.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = _heroHeight(screenWidth, screenHeight);

    if (widget.animeList.isEmpty) return SizedBox(height: heroHeight);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _pauseTimer();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _startTimer();
      },
      child: SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.animeList.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final anime = widget.animeList[i];
                return _AnimeHeroSlide(
                  anime: anime,
                  screenWidth: screenWidth,
                  onWatchNow: () => widget.onWatchNow(anime),
                  onDetailsTap: () => widget.onDetailsTap(anime),
                );
              },
            ),

            // Dot indicators
            if (widget.animeList.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.animeList.length, (i) {
                    final active = i == _index;
                    return GestureDetector(
                      onTap: () => _goTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: active
                              ? AppThemeService.currentPalette.value.primaryColor
                              : Colors.white.withValues(alpha: 0.30),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppThemeService.currentPalette.value.primaryColor
                                        .withValues(alpha: 0.55),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // Desktop Hover Arrows
            if (widget.animeList.length > 1 &&
                _isHovering &&
                screenWidth > 600) ...[
              if (_index > 0)
                Positioned(
                  left: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => _goTo(_index - 1),
                    ),
                  ),
                ),
              if (_index < widget.animeList.length - 1)
                Positioned(
                  right: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      icon: Icons.arrow_forward_ios_rounded,
                      onTap: () => _goTo(_index + 1),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimeHeroSlide extends StatelessWidget {
  final AnimeMedia anime;
  final double screenWidth;
  final VoidCallback onWatchNow;
  final VoidCallback onDetailsTap;

  const _AnimeHeroSlide({
    required this.anime,
    required this.screenWidth,
    required this.onWatchNow,
    required this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = screenWidth < 600;
    final hasBanner = anime.bannerImage.trim().isNotEmpty;
    final bannerUrl = hasBanner ? anime.bannerImage : null;
    final posterUrl = anime.coverUrl.trim().isNotEmpty ? anime.coverUrl : null;
    final effectiveUrl = bannerUrl ?? posterUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background Layers ──
        if (effectiveUrl != null && effectiveUrl.trim().isNotEmpty)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final containerWidth = constraints.maxWidth;
                final containerHeight = constraints.maxHeight;
                final containerAspect = containerWidth / containerHeight;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: Ambient blurred background fill (eliminates all black bars)
                    ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 32,
                              sigmaY: 32,
                            ),
                            child: Transform.scale(
                              scale: 1.15,
                              child: CachedNetworkImage(
                                imageUrl: effectiveUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.low,
                                fadeInDuration:
                                    const Duration(milliseconds: 300),
                                placeholder: (_, __) => const ColoredBox(
                                    color: Color(0xFF080A0F)),
                                errorWidget: (_, __, ___) => const ColoredBox(
                                    color: Color(0xFF080A0F)),
                              ),
                            ),
                          ),
                          ColoredBox(
                            color:
                                const Color(0xFF080A0F).withValues(alpha: 0.50),
                          ),
                        ],
                      ),
                    ),

                    // Layer 2: Crisp foreground artwork
                    if (hasBanner) ...[
                      // Landscape 16:9 banner available
                      if (containerAspect <= 1.78)
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: bannerUrl!,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.15),
                            filterQuality: FilterQuality.medium,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (_, __) => const SizedBox.shrink(),
                            errorWidget: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        )
                      else
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          width: (containerHeight * (16 / 9))
                              .clamp(0.0, containerWidth),
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: [0.0, 0.22],
                                colors: [Colors.transparent, Colors.white],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: CachedNetworkImage(
                              imageUrl: bannerUrl!,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              filterQuality: FilterQuality.high,
                              fadeInDuration: const Duration(milliseconds: 300),
                              placeholder: (_, __) => const SizedBox.shrink(),
                              errorWidget: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                    ] else ...[
                      // Portrait poster fallback (when no 16:9 banner is available)
                      if (containerAspect <= 1.2)
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: effectiveUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            filterQuality: FilterQuality.medium,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (_, __) => const SizedBox.shrink(),
                            errorWidget: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        )
                      else
                        Positioned(
                          top: 40,
                          bottom: isCompact ? 70 : 60,
                          right: isCompact ? 24 : 72,
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    blurRadius: 36,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CachedNetworkImage(
                                  imageUrl: effectiveUrl,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                  fadeInDuration:
                                      const Duration(milliseconds: 300),
                                  placeholder: (_, __) =>
                                      const SizedBox.shrink(),
                                  errorWidget: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          )
        else
          const ColoredBox(color: Color(0xFF080A0F)),

        // Left horizontal wash for cinematic readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.38, 0.85],
                colors: [
                  const Color(0xFF080A0F).withValues(alpha: 0.95),
                  const Color(0xFF080A0F).withValues(alpha: 0.70),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top Gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  const Color(0xFF080A0F).withValues(alpha: 0.75),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom Gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.30, 0.75],
                colors: [
                  const Color(0xFF080A0F),
                  const Color(0xFF080A0F).withValues(alpha: 0.80),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content Overlay
        Positioned(
          left: isCompact ? 20 : 48,
          right: isCompact ? 20 : 48,
          bottom: isCompact ? 36 : 56,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isCompact ? double.infinity : 680.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rating + Year + Episodes row
                  Row(
                    children: [
                      if (anime.averageScore > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 17,
                                color: Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                anime.formattedScore,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (anime.seasonYear > 0)
                        Text(
                          '${anime.seasonYear}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (anime.totalEpisodes > 0) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.circle,
                            size: 4,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        Text(
                          '${anime.totalEpisodes} Episodes',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (anime.studioName.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.circle,
                            size: 4,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        Text(
                          anime.studioName,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    anime.displayTitle,
                    style: TextStyle(
                      fontSize: isCompact ? 30 : 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.05,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description
                  if (anime.description.isNotEmpty) ...[
                    SizedBox(height: isCompact ? 12 : 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isCompact ? double.infinity : 580,
                      ),
                      child: Text(
                        anime.description,
                        maxLines: isCompact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 14.5 : 15.5,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  // Genre chips
                  if (anime.genres.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: anime.genres.take(4).map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            genre,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.70),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Action buttons (Matching Home Page)
                  SizedBox(height: isCompact ? 22 : 26),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onWatchNow,
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Text(
                          'Watch Ep 1',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeService.currentPalette.value.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 18 : 28,
                            vertical: isCompact ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 12,
                          shadowColor: AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.45),
                        ),
                      ),
                      SizedBox(width: isCompact ? 8 : 12),
                      OutlinedButton.icon(
                        onPressed: onDetailsTap,
                        icon: Icon(
                          Icons.info_outline_rounded,
                          size: isCompact ? 18 : 21,
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                        label: Text(
                          'Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: isCompact ? 14 : 15.5,
                            color: Colors.white.withValues(alpha: 0.80),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 16 : 24,
                            vertical: isCompact ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.2,
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
      ],
    );
  }
}

class _CarouselArrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CarouselArrow({required this.icon, required this.onTap});

  @override
  State<_CarouselArrow> createState() => _CarouselArrowState();
}

class _CarouselArrowState extends State<_CarouselArrow> {
  bool _isHoveringArrow = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringArrow = true),
      onExit: (_) => setState(() => _isHoveringArrow = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHoveringArrow
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.3),
            border: Border.all(
              color: _isHoveringArrow
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            widget.icon,
            color: _isHoveringArrow ? Colors.white : Colors.white70,
            size: 24,
          ),
        ),
      ),
    );
  }
}
