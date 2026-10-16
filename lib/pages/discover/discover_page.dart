import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/addon/addon.dart';
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
  List<({int id, String name})> _tmdbGenres = const [];

  // TMDB advanced filter state
  int? _filterGenreId;
  int? _filterYear;
  String? _filterSortBy;
  int? _filterProviderId;
  String? _filterCountry;
  String? _filterLanguage;
  String? _filterCertification;
  double? _filterMinScore;
  int? _filterMinRuntime;
  int? _filterMaxRuntime;

  // Lazily-loaded filter option lists.
  List<({int id, String name})> _tmdbProviders = const [];
  List<({String code, String name})> _tmdbCountries = const [];
  List<({String code, String name})> _tmdbLanguages = const [];
  List<String> _tmdbCertifications = const [];

  bool get _hasFilters =>
      _filterGenreId != null ||
      _filterYear != null ||
      _filterSortBy != null ||
      _filterProviderId != null ||
      _filterCountry != null ||
      _filterLanguage != null ||
      _filterCertification != null ||
      _filterMinScore != null ||
      _filterMinRuntime != null ||
      _filterMaxRuntime != null;

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

    String initialType = widget.initialCatalog?.type ?? (sortedTypes.isNotEmpty ? sortedTypes.first : 'movie');
    if (!sortedTypes.contains(initialType) && sortedTypes.isNotEmpty) {
      initialType = sortedTypes.first;
    }

    ({InstalledAddon addon, AddonCatalog catalog})? initialEntry;
    if (widget.initialCatalog != null) {
      for (final entry in catalogs) {
        if (entry.catalog.id == widget.initialCatalog!.id &&
            (widget.initialAddon == null || entry.addon.manifest.id == widget.initialAddon!.manifest.id)) {
          initialEntry = entry;
          break;
        }
      }
    }

    initialEntry ??= catalogs.where((c) => c.catalog.type == initialType).firstOrNull ?? catalogs.firstOrNull;

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

    final genres = await TmdbService.fetchGenres('movie');
    if (!mounted) return;
    setState(() {
      _tmdbGenres = genres;
    });

    _loadItems(refresh: true);
  }

  Future<void> _setTmdbType(String type) async {
    if (_tmdbType == type) return;
    setState(() {
      _tmdbType = type;
      _tmdbListId = type == 'movie' ? 'popular_movie' : 'popular_series';
      _filterGenreId = null;
      _tmdbGenres = const [];
      _tmdbProviders = const [];
      _tmdbCertifications = const [];
    });

    final genres = await TmdbService.fetchGenres(type);
    if (!mounted) return;
    setState(() => _tmdbGenres = genres);
    _loadItems(refresh: true);
  }

  void _selectTmdbList(String listId) {
    if (_tmdbListId == listId && !_hasFilters) return;
    setState(() {
      _tmdbListId = listId;
      _clearFilters();
    });
    _loadItems(refresh: true);
  }

  void _clearFilters() {
    _filterGenreId = null;
    _filterYear = null;
    _filterSortBy = null;
    _filterProviderId = null;
    _filterCountry = null;
    _filterLanguage = null;
    _filterCertification = null;
    _filterMinScore = null;
    _filterMinRuntime = null;
    _filterMaxRuntime = null;
  }

  /// Applies a filter mutation and reloads results from page 1.
  void _applyFilter(VoidCallback mutate) {
    setState(mutate);
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
      final newItems = _hasFilters
          ? await TmdbService.discover(
              type: _tmdbType,
              genreId: _filterGenreId,
              year: _filterYear,
              sortBy: _filterSortBy,
              providerId: _filterProviderId,
              country: _filterCountry,
              language: _filterLanguage,
              certification: _filterCertification,
              minScore: _filterMinScore,
              minRuntime: _filterMinRuntime,
              maxRuntime: _filterMaxRuntime,
              page: page,
            )
          : await TmdbService.fetchList(_tmdbListId, page: page);

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
            child: _buildDiscoverContent(headerHeight, sizing, bottomInset, palette),
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
              child: AppLiquidDock(
                currentDestination: DockItemKey.discover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverContent(double topOffset, MovieCardSizing sizing, double bottomInset, AppThemePalette palette) {
    if (_selectedCatalogEntry == null && !_isTmdbMode) {
      return Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, topOffset + 30, 20, 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 48, color: Colors.white.withValues(alpha: 0.3)),
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
              Icon(Icons.inbox_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
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
    final columns = ((screenWidth - sizing.sidePadding * 2 + sizing.spacing) /
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
          _buildTmdbListRow(palette),
          const SizedBox(height: 4),
          _buildTmdbFilterRow(palette),
          const SizedBox(height: 6),
          Expanded(child: grid),
        ],
      );
    }

    return grid;
  }

  /// Type toggle (Movies / TV) + curated TMDB list chips.
  Widget _buildTmdbListRow(AppThemePalette palette) {
    final lists = _tmdbType == 'movie'
        ? const [
            (listId: 'popular_movie', label: 'Popular'),
            (listId: 'trending_day', label: 'Trending'),
            (listId: 'top_rated_movie', label: 'Top Rated'),
            (listId: 'now_playing', label: 'Now Playing'),
            (listId: 'upcoming', label: 'Upcoming'),
          ]
        : const [
            (listId: 'popular_series', label: 'Popular'),
            (listId: 'top_rated_series', label: 'Top Rated'),
          ];

    final chips = <Widget>[
      _pill(
        label: 'Movies',
        selected: _tmdbType == 'movie',
        palette: palette,
        onTap: () => _setTmdbType('movie'),
      ),
      _pill(
        label: 'TV Shows',
        selected: _tmdbType == 'series',
        palette: palette,
        onTap: () => _setTmdbType('series'),
      ),
      Container(
        width: 1,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      for (final l in lists)
        _pill(
          label: l.label,
          selected: !_hasFilters && _tmdbListId == l.listId,
          palette: palette,
          onTap: () => _selectTmdbList(l.listId),
        ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => chips[index],
      ),
    );
  }

  /// Horizontal row of advanced TMDB filter chips.
  Widget _buildTmdbFilterRow(AppThemePalette palette) {
    String genreLabel() {
      if (_filterGenreId == null) return 'Genre';
      for (final g in _tmdbGenres) {
        if (g.id == _filterGenreId) return g.name;
      }
      return 'Genre';
    }

    String providerLabel() {
      if (_filterProviderId == null) return 'Services';
      for (final p in _tmdbProviders) {
        if (p.id == _filterProviderId) return p.name;
      }
      return 'Services';
    }

    String countryLabel() {
      if (_filterCountry == null) return 'Country';
      for (final c in _tmdbCountries) {
        if (c.code == _filterCountry) return c.name;
      }
      return _filterCountry!;
    }

    String languageLabel() {
      if (_filterLanguage == null) return 'Language';
      for (final l in _tmdbLanguages) {
        if (l.code == _filterLanguage) return l.name;
      }
      return _filterLanguage!.toUpperCase();
    }

    String sortLabel() {
      if (_filterSortBy == null) return 'Sort';
      for (final s in TmdbService.sortOptionsFor(_tmdbType)) {
        if (s.value == _filterSortBy) return s.label;
      }
      return 'Sort';
    }

    String scoreLabel() {
      if (_filterMinScore == null) return 'Score';
      return '${_filterMinScore!.toStringAsFixed(1)}+';
    }

    String runtimeLabel() {
      if (_filterMinRuntime == null && _filterMaxRuntime == null) return 'Runtime';
      for (final r in TmdbService.runtimeOptions) {
        if (r.min == _filterMinRuntime && r.max == _filterMaxRuntime) return r.label;
      }
      return 'Runtime';
    }

    final chips = <Widget>[
      _filterChip(genreLabel(), active: _filterGenreId != null, palette: palette, onTap: _openGenreSheet),
      _filterChip(sortLabel(), active: _filterSortBy != null, palette: palette, onTap: _openSortSheet),
      _filterChip(
        _filterYear?.toString() ?? 'Year',
        active: _filterYear != null,
        palette: palette,
        onTap: _openYearSheet,
      ),
      _filterChip(providerLabel(), active: _filterProviderId != null, palette: palette, onTap: _openProviderSheet),
      _filterChip(countryLabel(), active: _filterCountry != null, palette: palette, onTap: _openCountrySheet),
      _filterChip(languageLabel(), active: _filterLanguage != null, palette: palette, onTap: _openLanguageSheet),
      _filterChip(
        _filterCertification ?? 'Certificate',
        active: _filterCertification != null,
        palette: palette,
        onTap: _openCertificationSheet,
      ),
      _filterChip(scoreLabel(), active: _filterMinScore != null, palette: palette, onTap: _openScoreSheet),
      _filterChip(runtimeLabel(), active: _filterMinRuntime != null || _filterMaxRuntime != null, palette: palette, onTap: _openRuntimeSheet),
      if (_hasFilters)
        _filterChip(
          'Clear',
          active: true,
          palette: palette,
          icon: Icons.close_rounded,
          onTap: () => _applyFilter(_clearFilters),
        ),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => chips[index],
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required AppThemePalette palette,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.primaryColor : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? palette.primaryColor : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _filterChip(
    String label, {
    required bool active,
    required AppThemePalette palette,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? palette.primaryColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? palette.primaryColor.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!active)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.tune_rounded, size: 13, color: Colors.white.withValues(alpha: 0.55)),
              ),
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)),
              ),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white.withValues(alpha: 0.7),
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter sheets ──────────────────────────────────────────────────────

  Future<void> _openGenreSheet() async {
    if (_tmdbGenres.isEmpty) {
      final genres = await TmdbService.fetchGenres(_tmdbType);
      if (!mounted) return;
      setState(() => _tmdbGenres = genres);
    }
    _openChoiceSheet<int>(
      title: 'Genre',
      options: [for (final g in _tmdbGenres) (value: g.id, label: g.name)],
      selected: _filterGenreId,
      onSelected: (v) => _applyFilter(() => _filterGenreId = v),
    );
  }

  void _openSortSheet() {
    final options = TmdbService.sortOptionsFor(_tmdbType);
    _openChoiceSheet<String>(
      title: 'Sort By',
      options: [for (final s in options) (value: s.value, label: s.label)],
      selected: _filterSortBy,
      onSelected: (v) => _applyFilter(() => _filterSortBy = v),
    );
  }

  void _openYearSheet() {
    _openChoiceSheet<int>(
      title: 'Year',
      options: [for (final y in TmdbService.yearOptions) (value: y, label: '$y')],
      selected: _filterYear,
      onSelected: (v) => _applyFilter(() => _filterYear = v),
      searchable: true,
    );
  }

  Future<void> _openProviderSheet() async {
    if (_tmdbProviders.isEmpty) {
      final providers = await TmdbService.fetchWatchProviders(_tmdbType);
      if (!mounted) return;
      setState(() => _tmdbProviders = providers);
    }
    _openChoiceSheet<int>(
      title: 'Streaming Services',
      options: [for (final p in _tmdbProviders) (value: p.id, label: p.name)],
      selected: _filterProviderId,
      onSelected: (v) => _applyFilter(() => _filterProviderId = v),
      searchable: true,
    );
  }

  Future<void> _openCountrySheet() async {
    if (_tmdbCountries.isEmpty) {
      final countries = await TmdbService.fetchCountries();
      if (!mounted) return;
      setState(() => _tmdbCountries = countries);
    }
    _openChoiceSheet<String>(
      title: 'Country',
      options: [for (final c in _tmdbCountries) (value: c.code, label: c.name)],
      selected: _filterCountry,
      onSelected: (v) => _applyFilter(() => _filterCountry = v),
      searchable: true,
    );
  }

  Future<void> _openLanguageSheet() async {
    if (_tmdbLanguages.isEmpty) {
      final languages = await TmdbService.fetchLanguages();
      if (!mounted) return;
      setState(() => _tmdbLanguages = languages);
    }
    _openChoiceSheet<String>(
      title: 'Language',
      options: [for (final l in _tmdbLanguages) (value: l.code, label: l.name)],
      selected: _filterLanguage,
      onSelected: (v) => _applyFilter(() => _filterLanguage = v),
      searchable: true,
    );
  }

  Future<void> _openCertificationSheet() async {
    if (_tmdbCertifications.isEmpty) {
      final certs = await TmdbService.fetchCertifications(_tmdbType);
      if (!mounted) return;
      setState(() => _tmdbCertifications = certs);
    }
    _openChoiceSheet<String>(
      title: 'Certification',
      options: [for (final c in _tmdbCertifications) (value: c, label: c)],
      selected: _filterCertification,
      onSelected: (v) => _applyFilter(() => _filterCertification = v),
    );
  }

  void _openScoreSheet() {
    _openChoiceSheet<double?>(
      title: 'Minimum Score',
      options: [for (final s in TmdbService.scoreOptions) (value: s.minScore, label: s.label)],
      selected: _filterMinScore,
      onSelected: (v) => _applyFilter(() => _filterMinScore = v),
    );
  }

  void _openRuntimeSheet() {
    _openChoiceSheet<int>(
      title: 'Runtime',
      options: [
        for (var i = 0; i < TmdbService.runtimeOptions.length; i++)
          (value: i, label: TmdbService.runtimeOptions[i].label),
      ],
      selected: _runtimeOptionIndex,
      onSelected: (v) => _applyFilter(() {
        final opt = v == null ? null : TmdbService.runtimeOptions[v];
        _filterMinRuntime = opt?.min;
        _filterMaxRuntime = opt?.max;
      }),
    );
  }

  int? get _runtimeOptionIndex {
    for (var i = 0; i < TmdbService.runtimeOptions.length; i++) {
      final r = TmdbService.runtimeOptions[i];
      if (r.min == _filterMinRuntime && r.max == _filterMaxRuntime) {
        return i == 0 ? null : i;
      }
    }
    return null;
  }

  Future<void> _openChoiceSheet<T>({
    required String title,
    required List<({T value, String label})> options,
    required T? selected,
    required ValueChanged<T?> onSelected,
    bool searchable = false,
  }) {
    final palette = AppThemeService.currentPalette.value;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.cardBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FilterSheet<T>(
        title: title,
        options: options,
        selected: selected,
        accent: palette.primaryColor,
        searchable: searchable,
        onSelected: (value) {
          Navigator.pop(ctx);
          onSelected(value);
        },
      ),
    );
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
            border: Border.all(color: palette.primaryColor.withValues(alpha: 0.3)),
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
                child: Icon(Icons.tune_rounded, color: palette.primaryColor, size: 30),
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
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      onSelected: (val) => _onExtraOptionSelected(extra.name, val),
                      itemBuilder: (context) => extra.options
                          .map(
                            (opt) => PopupMenuItem<String>(
                              value: opt,
                              child: Text(opt, style: const TextStyle(color: Colors.white)),
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
                            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    final controller = TextEditingController(text: _selectedExtras[extraName] ?? '');
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
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            Center(child: CircularProgressIndicator(color: palette.primaryColor))
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
                  padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: palette.appBarBackgroundColor.withValues(alpha: 0.6),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
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
                          widget.isGenre ? 'Genre: ${widget.query}' : 'Search: ${widget.query}',
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
        crossAxisCount: ((MediaQuery.sizeOf(context).width - sizing.sidePadding * 2 + sizing.spacing) /
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

/// Bottom-sheet list of filter options, optionally with a search field.
///
/// An "Any" row at the top clears the filter (emits null).
class _FilterSheet<T> extends StatefulWidget {
  final String title;
  final List<({T value, String label})> options;
  final T? selected;
  final Color accent;
  final bool searchable;
  final ValueChanged<T?> onSelected;

  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.accent,
    required this.onSelected,
    this.searchable = false,
  });

  @override
  State<_FilterSheet<T>> createState() => _FilterSheetState<T>();
}

class _FilterSheetState<T> extends State<_FilterSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.label.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.selected != null)
                  TextButton(
                    onPressed: () => widget.onSelected(null),
                    child: Text('Clear', style: TextStyle(color: widget.accent)),
                  ),
              ],
            ),
          ),
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                autofocus: false,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.accent),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _tile(label: 'Any', value: null);
                }
                final option = filtered[index - 1];
                return _tile(label: option.label, value: option.value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({required String label, required T? value}) {
    final selected = value == widget.selected;
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          color: selected ? widget.accent : Colors.white,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: selected ? Icon(Icons.check_rounded, color: widget.accent, size: 20) : null,
      onTap: () => widget.onSelected(value),
    );
  }
}
