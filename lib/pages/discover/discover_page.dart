import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/addon/addon.dart';
import '../../models/discover/discover_filter_state.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/movie_section.dart';
import '../../services/addon/addon_manager.dart';
import '../../services/metadata/metadata_service.dart';
import '../../services/metadata/tmdb_service.dart';
import '../../services/theme/app_theme_service.dart';
import '../../services/theme/dock_settings.dart';
import '../../widgets/common/app_liquid_dock.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/page_top_bar.dart';
import '../../widgets/discover/advanced_filter_sheet.dart';
import '../../widgets/discover/filter_option_sheet.dart';
import '../../widgets/movie/movie_card.dart';
import '../search/search_page.dart';

class DiscoverPage extends StatefulWidget {
  final String? query;
  final bool isGenre;
  final AddonCatalog? initialCatalog;
  final InstalledAddon? initialAddon;

  const DiscoverPage({
    super.key,
    this.query,
    this.isGenre = false,
    this.initialCatalog,
    this.initialAddon,
  });

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // Legacy query mode (when query is passed)
  bool get _isLegacyMode => widget.query != null && widget.query!.isNotEmpty;

  // Legacy state
  bool _legacyLoading = true;
  String? _legacyError;
  List<MovieSection> _legacySections = [];

  // Full Discover state
  String _selectedType = 'movie';

  // TMDB browsing state (used when TmdbService.isConfigured)
  String _tmdbType = 'movie';
  String _tmdbListId = 'popular_movie';

  // TMDB advanced filter state (single source of truth; sheet seeds from it).
  DiscoverFilterState _filters = DiscoverFilterState.empty;

  // Sort is kept separate from filtering.
  String? _sortBy = TmdbService.kTrendingSort;

  /// True when results must come from `/discover` (filters or an explicit sort).
  bool get _useDiscover => !_filters.isEmpty || _sortBy != null;

  ({InstalledAddon addon, AddonCatalog catalog})? _selectedCatalogEntry;
  final Map<String, String> _selectedExtras = {};

  final List<Movie> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  bool get _isTmdbMode => !_isLegacyMode && TmdbService.isConfigured;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (_isLegacyMode) {
      _fetchLegacyData();
    } else if (_isTmdbMode) {
      _initTmdbDiscover();
    } else {
      _initDiscoverCatalogs();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Legacy Search / Genre Mode ──
  Future<void> _fetchLegacyData() async {
    setState(() {
      _legacyLoading = true;
      _legacyError = null;
    });

    try {
      final manager = AddonManager.instance;
      List<MovieSection> sections;

      if (widget.isGenre) {
        sections = await manager.fetchByGenre(widget.query!);
      } else {
        sections = await manager.searchAll(widget.query!);
      }

      if (!mounted) return;
      setState(() {
        _legacySections = sections;
        _legacyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _legacyError = e.toString();
        _legacyLoading = false;
      });
    }
  }

  // ── Full Discover Mode ──
  void _initDiscoverCatalogs() {
    final catalogs = AddonManager.instance.getAvailableDiscoverCatalogs();
    final types = <String>{};
    for (final entry in catalogs) {
      types.add(entry.catalog.type);
    }

    final sortedTypes = types.toList();
    const priority = ['movie', 'series', 'anime', 'collections', 'collection'];
    sortedTypes.sort((a, b) {
      final idxA = priority.indexOf(a);
      final idxB = priority.indexOf(b);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return a.compareTo(b);
    });

    String initialType =
        widget.initialCatalog?.type ??
        (sortedTypes.isNotEmpty ? sortedTypes.first : 'movie');
    if (!sortedTypes.contains(initialType) && sortedTypes.isNotEmpty) {
      initialType = sortedTypes.first;
    }

    ({InstalledAddon addon, AddonCatalog catalog})? initialEntry;
    if (widget.initialCatalog != null) {
      for (final entry in catalogs) {
        if (entry.catalog.id == widget.initialCatalog!.id &&
            (widget.initialAddon == null ||
                entry.addon.manifest.id == widget.initialAddon!.manifest.id)) {
          initialEntry = entry;
          break;
        }
      }
    }

    initialEntry ??=
        catalogs.where((c) => c.catalog.type == initialType).firstOrNull ??
        catalogs.firstOrNull;

    setState(() {
      _selectedType = initialType;
      _selectedCatalogEntry = initialEntry;
    });

    _checkAndLoadCatalog();
  }

  // ── TMDB Discover Mode ──
  Future<void> _initTmdbDiscover() async {
    setState(() {
      _tmdbType = 'movie';
      _tmdbListId = 'popular_movie';
    });
    _loadItems(refresh: true);
  }

  Future<void> _setTmdbType(String type) async {
    if (_tmdbType == type) return;
    setState(() {
      _tmdbType = type;
      _tmdbListId = type == 'movie' ? 'popular_movie' : 'popular_series';
      _filters = DiscoverFilterState.empty;
      _sortBy = TmdbService.kTrendingSort;
    });
    _loadItems(refresh: true);
  }

  /// Applies a new filter set and reloads results from page 1.
  void _applyFilters(DiscoverFilterState next) {
    setState(() => _filters = next);
    _loadItems(refresh: true);
  }

  /// Applies a sort selection and reloads results from page 1.
  void _applySort(String? sortBy) {
    setState(() => _sortBy = sortBy);
    _loadItems(refresh: true);
  }

  // ── Results ──────────────────────────────────────────────────────────

  /// Catalog order as-served, deduplicated by id across paginated loads.
  List<Movie> get _visibleItems {
    if (_items.isEmpty) return _items;
    final seen = <String>{};
    return _items.where((m) => seen.add(m.id)).toList();
  }

  /// Search lives in the dedicated global search page (same as home).
  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  List<CatalogExtra> get _missingRequiredExtras {
    if (_selectedCatalogEntry == null) return const [];
    final catalog = _selectedCatalogEntry!.catalog;
    return catalog.requiredExtras.where((req) {
      final val = _selectedExtras[req.name];
      return val == null || val.trim().isEmpty;
    }).toList();
  }

  bool get _areRequiredExtrasSatisfied => _missingRequiredExtras.isEmpty;

  void _onExtraOptionSelected(String extraName, String? value) {
    if (_selectedExtras[extraName] == value) return;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _selectedExtras.remove(extraName);
      } else {
        _selectedExtras[extraName] = value.trim();
      }
    });
    _checkAndLoadCatalog();
  }

  void _onCustomExtraSubmitted(String extraName, String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _selectedExtras.remove(extraName);
      });
    } else {
      setState(() {
        _selectedExtras[extraName] = value.trim();
      });
    }
    _checkAndLoadCatalog();
  }

  void _checkAndLoadCatalog() {
    if (_selectedCatalogEntry == null) {
      setState(() {
        _items.clear();
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    if (!_areRequiredExtrasSatisfied) {
      // Gating: DO NOT fire network requests until required extras are selected!
      setState(() {
        _items.clear();
        _isLoading = false;
        _hasMore = false;
        _error = null;
      });
      return;
    }

    _loadItems(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      if (!_isLoading && _hasMore) {
        _loadItems();
      }
    }
  }

  Future<void> _loadItems({bool refresh = false}) async {
    if (_isTmdbMode) {
      await _loadTmdbItems(refresh: refresh);
      return;
    }

    if (_selectedCatalogEntry == null) return;
    final entry = _selectedCatalogEntry!;

    if (refresh) {
      setState(() {
        _items.clear();
        _hasMore = true;
        _error = null;
      });
    }

    if (!_hasMore) return;
    if (!_areRequiredExtrasSatisfied) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await MetadataService.fetchCatalog(
        baseUrl: entry.addon.baseUrl,
        type: entry.catalog.type,
        catalogId: entry.catalog.id,
        extraParams: _selectedExtras.isNotEmpty ? _selectedExtras : null,
        skip: entry.catalog.supportsSkip ? _items.length : 0,
      );
      final fetchedCount = newItems.length;

      if (!entry.catalog.supportsSkip) {
        _hasMore = false;
      }

      if (!mounted) return;

      setState(() {
        if (newItems.isEmpty) {
          _hasMore = false;
        } else {
          _items.addAll(newItems);
          if (fetchedCount < 10) {
            _hasMore = false;
          }
        }
        _isLoading = false;
      });

      // Auto load more if screen not filled yet
      _ensureScreenFilled();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Loads a page of items for the currently selected TMDB list.
  Future<void> _loadTmdbItems({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _items.clear();
        _hasMore = true;
        _error = null;
      });
    }

    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final page = (_items.length ~/ TmdbService.pageSize) + 1;
      final List<Movie> newItems;
      // The trending list can't be filtered — when any filter is active we must
      // go through /discover so the genre/score/etc. filters actually apply.
      if (_filters.isEmpty && _sortBy == TmdbService.kTrendingSort) {
        final listId = _tmdbType == 'series'
            ? 'trending_tv_day'
            : 'trending_day';
        newItems = await TmdbService.fetchList(listId, page: page);
      } else if (_useDiscover) {
        newItems = await TmdbService.discover(
          type: _tmdbType,
          genreIds: _filters.genreIds,
          yearFrom: _filters.yearFrom,
          yearTo: _filters.yearTo,
          sortBy: _sortBy,
          providerIds: _filters.providerIds,
          country: _filters.country,
          language: _filters.language,
          certification: _filters.certification,
          minScore: _filters.minScore,
          minRuntime: _filters.minRuntime,
          maxRuntime: _filters.maxRuntime,
          page: page,
        );
      } else {
        newItems = await TmdbService.fetchList(_tmdbListId, page: page);
      }

      if (!mounted) return;

      setState(() {
        // Trending lists shift between pages — dedupe by id.
        final seen = _items.map((m) => m.id).toSet();
        for (final m in newItems) {
          if (seen.add(m.id)) _items.add(m);
        }
        if (newItems.length < TmdbService.pageSize) _hasMore = false;
        _isLoading = false;
      });

      _ensureScreenFilled();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _ensureScreenFilled() {
    if (!_hasMore || _isLoading) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hasMore || _isLoading) return;
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0) {
        _loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemePalette>(
      valueListenable: AppThemeService.currentPalette,
      builder: (context, palette, _) {
        if (_isLegacyMode) {
          return _buildLegacyScaffold(palette);
        }
        return _buildDiscoverScaffold(palette);
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Full Discover UI
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDiscoverScaffold(AppThemePalette palette) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomInset = mediaQuery.padding.bottom;
    final screenWidth = mediaQuery.size.width;

    final sizing = MovieCardSizing.fromWidth(screenWidth);

    // PageTopBar height: status bar + top pad 6 + row ~38 + bottom pad 10
    final headerHeight = topPadding + 56;

    return Scaffold(
      backgroundColor: palette.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Main Content Grid ──
          Positioned.fill(
            child: _buildDiscoverContent(
              headerHeight,
              sizing,
              bottomInset,
              palette,
            ),
          ),

          // ── Glass App Bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PageTopBar(
              topPadding: topPadding,
              title: 'Discover',
              showBack: true,
              onSearchTap: _navigateToSearch,
            ),
          ),

          // ── Liquid Dock Navbar ──
          Positioned(
            bottom: 12.0 + bottomInset,
            left: 0,
            right: 0,
            child: const Center(
              child: AppLiquidDock(currentDestination: DockItemKey.discover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverContent(
    double topOffset,
    MovieCardSizing sizing,
    double bottomInset,
    AppThemePalette palette,
  ) {
    if (_selectedCatalogEntry == null && !_isTmdbMode) {
      return Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, topOffset + 30, 20, 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 48,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No catalogs available for "$_selectedType"',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Required extra gating prompt
    if (!_areRequiredExtrasSatisfied) {
      return _buildRequiredExtraGatingPrompt(topOffset);
    }

    if (_items.isEmpty && _isLoading) {
      return Center(
        child: CircularProgressIndicator(color: palette.primaryColor),
      );
    }

    if (_items.isEmpty && _error != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, topOffset + 30, 20, 100),
          child: ErrorView(
            error: _error,
            onRetry: () => _loadItems(refresh: true),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, topOffset + 30, 20, 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 48,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              const Text(
                'No titles found in this catalog',
                style: TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final visibleItems = _visibleItems;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns =
        ((screenWidth - sizing.sidePadding * 2 + sizing.spacing) /
                (sizing.cardWidth + sizing.spacing))
            .floor()
            .clamp(2, 10);
    final double cardAspectRatio = sizing.cardWidth / sizing.totalHeight;

    final grid = GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        sizing.sidePadding,
        _isTmdbMode ? 14 : topOffset + 14,
        sizing.sidePadding,
        110 + bottomInset,
      ),
      physics: const ClampingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: cardAspectRatio,
        crossAxisSpacing: sizing.spacing,
        mainAxisSpacing: sizing.spacing,
      ),
      itemCount: visibleItems.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleItems.length) {
          return Center(
            child: CircularProgressIndicator(color: palette.primaryColor),
          );
        }
        return MovieCard(movie: visibleItems[index]);
      },
    );

    if (_isTmdbMode) {
      return Column(
        children: [
          SizedBox(height: topOffset),
          _buildControlBar(palette),
          const SizedBox(height: 6),
          Expanded(child: grid),
        ],
      );
    }

    return grid;
  }

  // ── Control bar palette (premium dark streaming look) ──
  static const Color _kBarSurface = Color(0xFF1B2231);
  static const Color _kBarMuted = Color(0xFF9AA6B8);

  /// Unified control bar: animated Movies/TV segmented control + Sort + Filters.
  Widget _buildControlBar(AppThemePalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildTypeSegmented(palette)),
          const SizedBox(width: 12),
          _barDivider(),
          const SizedBox(width: 12),
          _iconButton(
            icon: Icons.swap_vert_rounded,
            tooltip: 'Sort: $_sortLabel',
            accent: palette.primaryColor,
            onTap: _openSortSheet,
          ),
          const SizedBox(width: 10),
          _iconButton(
            icon: Icons.filter_alt_rounded,
            tooltip: 'Filters',
            accent: palette.primaryColor,
            badge: _filters.activeCount,
            onTap: _openAdvancedFilters,
          ),
        ],
      ),
    );
  }

  Widget _barDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.08),
      );

  /// Rounded segmented Movies/TV control with a sliding highlight.
  Widget _buildTypeSegmented(AppThemePalette palette) {
    final isMovies = _tmdbType == 'movie';
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kBarSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: isMovies ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.primaryColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _segmentLabel(
                  'Movies',
                  selected: isMovies,
                  onTap: () => _setTmdbType('movie'),
                ),
              ),
              Expanded(
                child: _segmentLabel(
                  'TV',
                  selected: !isMovies,
                  onTap: () => _setTmdbType('series'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segmentLabel(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: selected ? Colors.white : _kBarMuted,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.1,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required Color accent,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kBarSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  if (badge > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Label for the current sort (defaults to "Trending").
  String get _sortLabel {
    if (_sortBy != null) {
      for (final s in TmdbService.sortOptionsFor(_tmdbType)) {
        if (s.value == _sortBy) return s.label;
      }
    }
    return 'Trending';
  }

  Future<void> _openSortSheet() async {
    final options = TmdbService.sortOptionsFor(_tmdbType);
    final accent = AppThemeService.currentPalette.value.primaryColor;
    final result = await showModalBottomSheet<({String? value})>(
      context: context,
      backgroundColor: AppThemeService.currentPalette.value.cardBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FilterOptionSheet<String>(
        title: 'Sort by',
        options: [for (final s in options) (value: s.value, label: s.label)],
        selected: _sortBy,
        accent: accent,
        onSelected: (value) => Navigator.pop(ctx, (value: value)),
      ),
    );
    if (result == null) return;
    _applySort(result.value);
  }

  Future<void> _openAdvancedFilters() async {
    final result = await showModalBottomSheet<DiscoverFilterState>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => AdvancedFilterSheet(
        mediaType: _tmdbType,
        initial: _filters,
        countResults: (draft) => TmdbService.discoverTotal(
          type: _tmdbType,
          genreIds: draft.genreIds,
          yearFrom: draft.yearFrom,
          yearTo: draft.yearTo,
          sortBy: _sortBy,
          providerIds: draft.providerIds,
          country: draft.country,
          language: draft.language,
          certification: draft.certification,
          minScore: draft.minScore,
          minRuntime: draft.minRuntime,
          maxRuntime: draft.maxRuntime,
        ),
      ),
    );
    if (result == null) return;
    _applyFilters(result);
  }

  Widget _buildRequiredExtraGatingPrompt(double topOffset) {
    final missing = _missingRequiredExtras;
    final palette = AppThemeService.currentPalette.value;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 420;

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isNarrow ? 16 : 24,
          topOffset + 20,
          isNarrow ? 16 : 24,
          120 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 18 : 28,
            vertical: isNarrow ? 20 : 28,
          ),
          decoration: BoxDecoration(
            color: palette.cardBackgroundColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: palette.primaryColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primaryColor.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: palette.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Required Filter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isNarrow ? 17 : 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This catalog requires selecting ${missing.map((e) => e.name).join(' & ')} before loading titles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: isNarrow ? 13 : 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Quick selection chips for missing extras
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: missing.map((extra) {
                  if (extra.options.isNotEmpty) {
                    return PopupMenuButton<String>(
                      tooltip: extra.name,
                      constraints: const BoxConstraints(maxHeight: 360),
                      color: palette.cardBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      onSelected: (val) =>
                          _onExtraOptionSelected(extra.name, val),
                      itemBuilder: (context) => extra.options
                          .map(
                            (opt) => PopupMenuItem<String>(
                              value: opt,
                              child: Text(
                                opt,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 14 : 16,
                          vertical: isNarrow ? 7 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Select ${extra.name[0].toUpperCase()}${extra.name.substring(1)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isNarrow ? 12.5 : 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return ElevatedButton.icon(
                      onPressed: () => _showCustomExtraDialog(extra.name),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 14 : 18,
                          vertical: isNarrow ? 8 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(
                        'Enter ${extra.name}',
                        style: TextStyle(fontSize: isNarrow ? 12.5 : 14),
                      ),
                    );
                  }
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomExtraDialog(String extraName) {
    final controller = TextEditingController(
      text: _selectedExtras[extraName] ?? '',
    );
    final palette = AppThemeService.currentPalette.value;
    final screenWidth = MediaQuery.sizeOf(context).width;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Enter $extraName',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: (screenWidth - 64).clamp(260.0, 420.0),
          child: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type $extraName here...',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: palette.primaryColor),
              ),
            ),
            onSubmitted: (val) {
              Navigator.pop(ctx);
              _onCustomExtraSubmitted(extraName, val);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _onCustomExtraSubmitted(extraName, controller.text);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Legacy Search/Genre Scaffold (Backwards compatibility)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLegacyScaffold(AppThemePalette palette) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: palette.scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (_legacyLoading)
            Center(
              child: CircularProgressIndicator(color: palette.primaryColor),
            )
          else if (_legacyError != null)
            ErrorView(error: _legacyError, onRetry: _fetchLegacyData)
          else if (_legacySections.isEmpty)
            Center(
              child: Text(
                'No results found for "${widget.query}"',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          else
            _buildLegacySectionsList(topPadding + kToolbarHeight + 20),

          // Glass App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: kToolbarHeight + topPadding,
                  padding: EdgeInsets.only(
                    top: topPadding,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: palette.appBarBackgroundColor.withValues(alpha: 0.6),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.isGenre
                              ? 'Genre: ${widget.query}'
                              : 'Search: ${widget.query}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 22 : 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacySectionsList(double topPadding) {
    final allMoviesMap = <String, Movie>{};
    for (var section in _legacySections) {
      for (var movie in section.movies) {
        if (!allMoviesMap.containsKey(movie.id)) {
          allMoviesMap[movie.id] = movie;
        }
      }
    }
    final allMovies = allMoviesMap.values.toList();
    final sizing = MovieCardSizing.fromWidth(MediaQuery.sizeOf(context).width);
    final double cardAspectRatio = sizing.cardWidth / sizing.totalHeight;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        sizing.sidePadding,
        topPadding,
        sizing.sidePadding,
        110 + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const ClampingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            ((MediaQuery.sizeOf(context).width -
                        sizing.sidePadding * 2 +
                        sizing.spacing) /
                    (sizing.cardWidth + sizing.spacing))
                .floor()
                .clamp(2, 10),
        childAspectRatio: cardAspectRatio,
        crossAxisSpacing: sizing.spacing,
        mainAxisSpacing: sizing.spacing,
      ),
      itemCount: allMovies.length,
      itemBuilder: (context, index) {
        return MovieCard(movie: allMovies[index]);
      },
    );
  }
}
