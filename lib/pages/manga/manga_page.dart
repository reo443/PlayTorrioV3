import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../models/manga/manga.dart';
import '../../models/manga/manga_chapter.dart';
import '../../services/theme/app_theme_service.dart';
import '../../services/theme/dock_settings.dart';
import '../../services/manga/manga_service.dart';
import '../../services/manga/manga_settings.dart';
import '../../widgets/common/animated_ambient_background.dart';
import '../../widgets/common/app_liquid_dock.dart';
import '../../widgets/common/custom_scroll_track.dart';
import '../../widgets/common/page_top_bar.dart';
import '../../widgets/common/slider_arrow.dart';
import '../../widgets/manga/manga_card.dart';
import '../../models/manga/manga_browse_filter.dart';
import 'manga_reader_page.dart';
import 'manga_search_page.dart';

class MangaPage extends StatefulWidget {
  const MangaPage({super.key});

  @override
  State<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  // Static cache to preserve state across navigations
  static List<Manga>? _cachedMangaList;
  static List<Map<String, dynamic>>? _cachedReadingHistory;
  static int _cachedCurrentPage = 1;
  static double _cachedScrollOffset = 0.0;

  // Editorial section caches (Popular / Latest / Recently Added / Most Followed)
  static List<Manga>? _cachedPopularSection;
  static List<Manga>? _cachedLatestSection;
  static List<Manga>? _cachedRecentSection;
  static List<Manga>? _cachedFollowedSection;

  final MangaService _mangaService = MangaService();
  late final ScrollController _scrollController;

  List<Manga> _mangaList = [];
  List<Map<String, dynamic>> _readingHistory = [];

  // Discover-style editorial sections
  List<Manga> _popularSection = [];
  List<Manga> _latestSection = [];
  List<Manga> _recentSection = [];
  List<Manga> _followedSection = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;

  // Track grid layout dimensions
  late double _screenWidth;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _cachedScrollOffset,
    );

    MangaSettings.changeNotifier.addListener(_onSettingsChanged);
    AppThemeService.currentPalette.addListener(_onSettingsChanged);

    if (_cachedMangaList != null && _cachedReadingHistory != null) {
      _mangaList = _cachedMangaList!;
      _readingHistory = _cachedReadingHistory!;
      _currentPage = _cachedCurrentPage;
      // Refresh reading history in background silently
      _mangaService.getReadingHistory().then((history) {
        if (mounted) {
          setState(() {
            _readingHistory = history;
            _cachedReadingHistory = history;
          });
        }
      });
    } else {
      _isLoading = true;
      _loadInitialData();
    }

    _loadSectionData();

    MangaService.readingHistoryRevision.addListener(_loadHistory);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    MangaSettings.changeNotifier.removeListener(_onSettingsChanged);
    AppThemeService.currentPalette.removeListener(_onSettingsChanged);
    MangaService.readingHistoryRevision.removeListener(_loadHistory);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _cachedScrollOffset = _scrollController.offset;
    }
    if (_isLoading || _isLoadingMore) return;

    // If we're within 800 pixels of the bottom, load more
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 800) {
      _loadMore();
    }
  }

  Future<void> _loadHistory() async {
    final history = await _mangaService.getReadingHistory();
    if (mounted) {
      setState(() {
        _readingHistory = history;
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _mangaList.clear();
    });

    final results = await Future.wait([
      _mangaService.browseManga(page: _currentPage),
      _mangaService.getReadingHistory(),
    ]);

    if (mounted) {
      setState(() {
        _mangaList = results[0] as List<Manga>;
        _readingHistory = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;

        _cachedMangaList = _mangaList;
        _cachedReadingHistory = _readingHistory;
        _cachedCurrentPage = _currentPage;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);

    _currentPage++;
    final newManga = await _mangaService.browseManga(page: _currentPage);

    if (mounted) {
      setState(() {
        _mangaList.addAll(newManga);
        _isLoadingMore = false;

        _cachedMangaList = _mangaList;
        _cachedCurrentPage = _currentPage;
      });
    }
  }

  /// Loads the editorial discover sections — Popular, Latest Updates,
  /// Recently Added and Most Followed — cached statically across visits.
  Future<void> _loadSectionData() async {
    if (_cachedPopularSection != null &&
        _cachedLatestSection != null &&
        _cachedRecentSection != null &&
        _cachedFollowedSection != null) {
      setState(() {
        _popularSection = _cachedPopularSection!;
        _latestSection = _cachedLatestSection!;
        _recentSection = _cachedRecentSection!;
        _followedSection = _cachedFollowedSection!;
      });
      return;
    }

    try {
      final results = await Future.wait([
        _mangaService.browseManga(
          page: 1,
          filter: const MangaBrowseFilter(sort: 'Popularity'),
        ),
        _mangaService.browseManga(
          page: 1,
          filter: const MangaBrowseFilter(sort: 'Latest Updates'),
        ),
        _mangaService.browseManga(
          page: 1,
          filter: const MangaBrowseFilter(sort: 'Recently Added'),
        ),
        _mangaService.browseManga(
          page: 1,
          filter: const MangaBrowseFilter(sort: 'Subscribers'),
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _popularSection = results[0];
        _latestSection = results[1];
        _recentSection = results[2];
        _followedSection = results[3];

        _cachedPopularSection = _popularSection;
        _cachedLatestSection = _latestSection;
        _cachedRecentSection = _recentSection;
        _cachedFollowedSection = _followedSection;
      });
    } catch (_) {
      // Sections are editorial — a failure just means they don't render.
    }
  }

  void _resumeReading(Map<String, dynamic> historyEntry) {
    final mangaJson = historyEntry['manga'];
    final manga = Manga.fromJson(mangaJson);
    final chapterIndex = historyEntry['chapterIndex'] as int;
    final pageIndex = historyEntry['pageIndex'] as int;
    final chaptersList = (historyEntry['chapters'] as List)
        .map((c) => MangaChapter.fromJson(c))
        .toList();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MangaReaderPage(
              manga: manga,
              chapters: chaptersList,
              currentChapterIndex: chapterIndex,
              resumePageIndex: pageIndex,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onRemoveHistory(String mangaId) {
    _mangaService.removeHistory(mangaId).then((_) {
      _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.sizeOf(context).width;
    final palette = AppThemeService.currentPalette.value;
    final ambientEnabled = MangaSettings.enableAmbientLights.value;
    final showScrollTrack = MangaSettings.showScrollTrack.value;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      body: Stack(
        children: [
          // ── Moving Ambient Background ──
          if (ambientEnabled)
            const Positioned.fill(child: AnimatedAmbientBackground())
          else
            Positioned.fill(
              child: Container(color: palette.scaffoldBackgroundColor),
            ),

          LiquidGlassView(
            pixelRatio: 0.25,
            refreshRate: LiquidGlassRefreshRate.low,
            backgroundWidget: _buildScrollableContent(),
            child: Stack(
              children: [
                // Top App Bar / Search / Customize
                _buildAppBar(),

                // Custom Scroll Track (Desktop only)
                if (_screenWidth > 800 && showScrollTrack)
                  Positioned(
                    right: 24,
                    bottom: 40,
                    child: CustomScrollTrack(controller: _scrollController),
                  ),

                // ── Bottom Liquid Dock Navbar ──
                Positioned(
                  bottom: 12.0 + MediaQuery.paddingOf(context).bottom,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: AppLiquidDock(currentDestination: DockItemKey.manga),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    final density = MangaSettings.cardDensity.value;
    final sizing = MangaCardSizing.fromWidth(_screenWidth, density: density);
    final showContinue = MangaSettings.showContinueReading.value;
    final isMobile = _screenWidth < 600;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: 76.0 + topInset), // Spacer for top app bar
        ),

        // ── Continue Reading ──
        if (showContinue && _readingHistory.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 32.0,
                vertical: isMobile ? 12.0 : 16.0,
              ),
              child: Text(
                'Continue Reading',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _ContinueReadingSlider(
              readingHistory: _readingHistory,
              onResume: _resumeReading,
              onRemove: _onRemoveHistory,
              screenWidth: _screenWidth,
              isMobile: isMobile,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: isMobile ? 24 : 40)),
        ],

        // ── Discover Sections (Popular / Latest / Recent / Most Followed) ──
        if (_popularSection.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildMangaSection(
              'Popular Manga',
              _popularSection,
              sizing,
              isMobile,
            ),
          ),
        ],
        if (_latestSection.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildMangaSection(
              'Latest Updates',
              _latestSection,
              sizing,
              isMobile,
            ),
          ),
        ],
        if (_recentSection.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildMangaSection(
              'Recently Added',
              _recentSection,
              sizing,
              isMobile,
            ),
          ),
        ],
        if (_followedSection.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildMangaSection(
              'Most Followed',
              _followedSection,
              sizing,
              isMobile,
            ),
          ),
        ],

        // ── Discovery / Search Results & Filters ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16.0 : 32.0,
              vertical: isMobile ? 12.0 : 16.0,
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover Manga',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Discover Manga',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        if (_isLoading && _mangaList.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        else if (_mangaList.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No manga found',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: sizing.sidePadding,
              vertical: 8.0,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: sizing.cardWidth + sizing.spacing * 2,
                mainAxisSpacing: 32.0,
                crossAxisSpacing: sizing.spacing,
                mainAxisExtent: sizing.totalHeight,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return MangaCard(manga: _mangaList[index]);
              }, childCount: _mangaList.length),
            ),
          ),

        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 110.0 + bottomInset,
          ), // Bottom padding for dock
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    final topInset = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: PageTopBar(
        topPadding: topInset,
        title: 'Manga',
        onSearchTap: _navigateToSearch,
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MangaSearchPage()),
    );
  }

  /// Discover-style horizontal slider: section title + a row of manga
  /// posters.
  Widget _buildMangaSection(
    String title,
    List<Manga> list,
    MangaCardSizing sizing,
    bool isMobile,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 22 : 30, top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 32.0),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: sizing.totalHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 32.0),
              physics: const ClampingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: sizing.cardWidth,
                  height: sizing.totalHeight,
                  child: MangaCard(manga: list[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueReadingSlider extends StatefulWidget {
  final List<Map<String, dynamic>> readingHistory;
  final void Function(Map<String, dynamic>) onResume;
  final void Function(String mangaId) onRemove;
  final double screenWidth;
  final bool isMobile;

  const _ContinueReadingSlider({
    required this.readingHistory,
    required this.onResume,
    required this.onRemove,
    required this.screenWidth,
    required this.isMobile,
  });

  @override
  State<_ContinueReadingSlider> createState() => _ContinueReadingSliderState();
}

class _ContinueReadingSliderState extends State<_ContinueReadingSlider> {
  late final ScrollController _scrollController;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollButtons();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    final canLeft = _scrollController.position.pixels > 10;
    final canRight =
        _scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 10;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scroll(double directionMultiplier) {
    if (!_scrollController.hasClients) return;
    final viewportWidth = _scrollController.position.viewportDimension;
    final scrollAmount = (viewportWidth * 0.75) * directionMultiplier;
    final target = (_scrollController.position.pixels + scrollAmount).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !widget.isMobile;

    return MouseRegion(
      onEnter: (_) {
        if (isDesktop) setState(() => _isHovering = true);
      },
      onExit: (_) {
        if (isDesktop) setState(() => _isHovering = false);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: widget.isMobile ? 200 : 240,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 12.0 : 24.0,
              ),
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.readingHistory.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(widget.readingHistory[index]);
              },
            ),
          ),
          if (isDesktop) ...[
            // Left Arrow
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: _canScrollLeft && _isHovering ? 12 : -60,
              top: 0,
              bottom: 0,
              child: Center(
                child: SliderArrow(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => _scroll(-1),
                ),
              ),
            ),
            // Right Arrow
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              right: _canScrollRight && _isHovering ? 12 : -60,
              top: 0,
              bottom: 0,
              child: Center(
                child: SliderArrow(
                  icon: Icons.arrow_forward_ios_rounded,
                  onTap: () => _scroll(1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final palette = AppThemeService.currentPalette.value;
    final mangaJson = entry['manga'];
    final mangaId = (mangaJson['id'] ?? '').toString();
    final title = mangaJson['title'] ?? 'Unknown';
    final coverUrl =
        mangaJson['cover_normal'] ?? mangaJson['cover_small'] ?? '';
    final chapterIndex = entry['chapterIndex'] as int;
    final chaptersList = entry['chapters'] as List;
    final chapterTitle =
        chaptersList.isNotEmpty && chapterIndex < chaptersList.length
        ? chaptersList[chapterIndex]['name'] ??
              'Chapter ${chaptersList[chapterIndex]['number']}'
        : 'Resume';

    return GestureDetector(
      onTap: () => widget.onResume(entry),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: widget.isMobile
              ? math.min(320.0, widget.screenWidth * 0.82)
              : 380,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                if (coverUrl.isNotEmpty)
                  Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                // Gradient Overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                // Frosted Info Panel
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  color: palette.primaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    chapterTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 14,
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
                ),
                // Remove from Continue Reading Button
                Positioned(
                  top: 16,
                  left: 16,
                  child: Tooltip(
                    message: 'Remove from Continue Reading',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onRemove(mangaId),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Play/Resume Overlay Icon
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.primaryColor.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
