import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/addon/addon.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/movie_section.dart';
import '../../services/addon/addon_manager.dart';
import '../../services/metadata/metadata_service.dart';
import '../../services/theme/dock_settings.dart';
import '../../widgets/common/app_liquid_dock.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/movie/movie_card.dart';
import 'discover_filter_sheet.dart';

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
  List<({InstalledAddon addon, AddonCatalog catalog})> _allCatalogs = [];
  String _selectedType = 'movie';

  ({InstalledAddon addon, AddonCatalog catalog})? _selectedCatalogEntry;
  final Map<String, String> _selectedExtras = {};

  // Client-side filters (applied locally to loaded items)
  int? _minYear;
  int? _maxYear;
  double? _minRating;
  double? _maxRating;
  int? _minDuration;
  int? _maxDuration;

  // Client-side sorting
  String? _sortKey; // null | 'title' | 'trending' | 'popularity' | 'score'
  bool _sortDescending = true;

  final List<Movie> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  // Per-genre skip offsets for multi-genre fan-out pagination
  final Map<String, int> _genreSkip = {};

  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (_isLegacyMode) {
      _fetchLegacyData();
    } else {
      _initDiscoverCatalogs();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
      _allCatalogs = catalogs;
      _selectedType = initialType;
      _selectedCatalogEntry = initialEntry;
    });

    _checkAndLoadCatalog();
  }

  // ── Client-side filter & sort helpers ──
  static int? _extractYear(String? s) {
    if (s == null || s.isEmpty) return null;
    final m = RegExp(r'(19|20)\d{2}').firstMatch(s);
    return m != null ? int.tryParse(m.group(0)!) : null;
  }

  static double? _ratingOf(Movie m) => double.tryParse(m.imdbRating ?? '');

  bool get _hasClientFilters =>
      _minYear != null ||
      _maxYear != null ||
      _minRating != null ||
      _maxRating != null ||
      _minDuration != null ||
      _maxDuration != null;

  double? _trendingScore(Movie m) {
    final rating = _ratingOf(m);
    if (rating == null) return null;
    final y = _extractYear(m.year);
    final now = DateTime.now().year;
    var bonus = 0.0;
    if (y != null) {
      final age = (now - y).clamp(0, 99);
      if (age < 5) bonus = (5 - age) * 0.2;
    }
    return rating + bonus;
  }

  int _cmpNullsLast(double? va, double? vb) {
    if (va == null && vb == null) return 0;
    if (va == null) return 1;
    if (vb == null) return -1;
    return _sortDescending ? vb.compareTo(va) : va.compareTo(vb);
  }

  int _compareBySort(Movie a, Movie b) {
    switch (_sortKey) {
      case 'title':
        final an = a.name.toLowerCase();
        final bn = b.name.toLowerCase();
        return _sortDescending ? bn.compareTo(an) : an.compareTo(bn);
      case 'trending':
        return _cmpNullsLast(_trendingScore(a), _trendingScore(b));
      case 'popularity':
        return _cmpNullsLast(
          a.popularity ?? _ratingOf(a),
          b.popularity ?? _ratingOf(b),
        );
      case 'score':
        return _cmpNullsLast(_ratingOf(a), _ratingOf(b));
      default:
        return 0;
    }
  }

  List<Movie> get _visibleItems {
    if (!_hasClientFilters && _sortKey == null) return _items;
    var items = List<Movie>.of(_items);
    if (_hasClientFilters) {
      items = items.where(_matchesClientFilters).toList();
    }
    if (_sortKey != null) {
      items.sort(_compareBySort);
    }
    return items;
  }

  bool _matchesClientFilters(Movie m) {
    if (_minYear != null || _maxYear != null) {
      final y = _extractYear(m.year);
      if (y == null) return false;
      if (_minYear != null && y < _minYear!) return false;
      if (_maxYear != null && y > _maxYear!) return false;
    }
    if (_minRating != null || _maxRating != null) {
      final r = double.tryParse(m.imdbRating ?? '');
      if (r == null) return false;
      if (_minRating != null && r < _minRating!) return false;
      if (_maxRating != null && r > _maxRating!) return false;
    }
    if (_minDuration != null || _maxDuration != null) {
      final d = m.runtime;
      if (d == null) return false;
      if (_minDuration != null && d < _minDuration!) return false;
      if (_maxDuration != null && d > _maxDuration!) return false;
    }
    return true;
  }

  int get _activeFilterCount {
    var count = _selectedExtras.length;
    if (_sortKey != null) count++;
    if (_minYear != null || _maxYear != null) count++;
    if (_minRating != null || _maxRating != null) count++;
    if (_minDuration != null || _maxDuration != null) count++;
    return count;
  }

  static bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  void _applyFilters(DiscoverFilterResult result) {
    final newExtras = <String, String>{};
    if (result.genres.isNotEmpty) {
      newExtras['genre'] = result.genres.join(',');
    }

    final typeChanged = result.type != _selectedType;
    final catalogChanged = result.catalogEntry != _selectedCatalogEntry;
    final extrasChanged = !_mapsEqual(_selectedExtras, newExtras);
    final needsReload = typeChanged || catalogChanged || extrasChanged;

    setState(() {
      if (needsReload) {
        _selectedType = result.type;
        _selectedCatalogEntry = result.catalogEntry;
        _selectedExtras.clear();
        _selectedExtras.addAll(newExtras);
        _searchQuery = '';
        _isSearching = false;
        _searchController.clear();
      }
      _sortKey = result.sortKey;
      _sortDescending = result.sortDescending;
      _minYear = result.minYear;
      _maxYear = result.maxYear;
      _minRating = result.minRating;
      _maxRating = result.maxRating;
      _minDuration = result.minDuration;
      _maxDuration = result.maxDuration;
    });

    if (needsReload) {
      _checkAndLoadCatalog();
    } else {
      _ensureScreenFilled();
    }
  }

  void _clearAllFilters() {
    final hadExtras = _selectedExtras.isNotEmpty;
    setState(() {
      _minYear = null;
      _maxYear = null;
      _minRating = null;
      _maxRating = null;
      _minDuration = null;
      _maxDuration = null;
      _sortKey = null;
      _sortDescending = true;
      if (hadExtras) {
        _selectedExtras.clear();
        _searchQuery = '';
        _isSearching = false;
        _searchController.clear();
      }
    });
    if (hadExtras) {
      _checkAndLoadCatalog();
    } else {
      _ensureScreenFilled();
    }
  }

  void _openFilterSheet() {
    if (_selectedCatalogEntry == null) return;
    final genres = _selectedExtras['genre']
            ?.split(',')
            .map((g) => g.trim())
            .where((g) => g.isNotEmpty)
            .toList() ??
        <String>[];

    showDiscoverFilterSheet(
      context: context,
      selectedType: _selectedType,
      catalogs: _allCatalogs,
      selectedCatalogEntry: _selectedCatalogEntry!,
      selectedGenres: genres,
      sortKey: _sortKey,
      sortDescending: _sortDescending,
      minYear: _minYear,
      maxYear: _maxYear,
      minRating: _minRating,
      maxRating: _maxRating,
      minDuration: _minDuration,
      maxDuration: _maxDuration,
      onApply: _applyFilters,
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
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
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
    if (_selectedCatalogEntry == null) return;
    final entry = _selectedCatalogEntry!;

    if (refresh) {
      setState(() {
        _items.clear();
        _hasMore = true;
        _error = null;
      });
      _genreSkip.clear();
    }

    if (!_hasMore) return;
    if (!_areRequiredExtrasSatisfied) return;

    setState(() => _isLoading = true);

    try {
      List<Movie> newItems = [];
      var fetchedCount = 0;

      final params = Map<String, String>.from(_selectedExtras);
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      final selectedGenres = (params['genre'] ?? '')
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList();
      final isMultiGenre = selectedGenres.length > 1 && _searchQuery.isEmpty;

      if (_isSearching && _searchQuery.isNotEmpty && !entry.catalog.supportsSkip) {
        newItems = await MetadataService.search(
          baseUrl: entry.addon.baseUrl,
          type: entry.catalog.type,
          catalogId: entry.catalog.id,
          query: _searchQuery,
        );
        fetchedCount = newItems.length;
        _hasMore = false;
      } else if (isMultiGenre) {
        // Addons like Cinemeta only accept a single genre per request —
        // fan out one request per genre and merge + dedupe client-side.
        final results = await Future.wait(
          selectedGenres.map((g) async {
            try {
              final movies = await MetadataService.fetchCatalog(
                baseUrl: entry.addon.baseUrl,
                type: entry.catalog.type,
                catalogId: entry.catalog.id,
                extraParams: {...params, 'genre': g},
                skip: entry.catalog.supportsSkip ? (_genreSkip[g] ?? 0) : 0,
              );
              return (g, movies);
            } catch (_) {
              return (g, <Movie>[]);
            }
          }),
        );

        final existingIds = _items.map((m) => m.id).toSet();
        final batchIds = <String>{};
        for (final (genre, movies) in results) {
          _genreSkip[genre] = (_genreSkip[genre] ?? 0) + movies.length;
          fetchedCount += movies.length;
          for (final m in movies) {
            if (existingIds.contains(m.id) || batchIds.contains(m.id)) continue;
            batchIds.add(m.id);
            newItems.add(m);
          }
        }

        if (!entry.catalog.supportsSkip || fetchedCount < 10) {
          _hasMore = false;
        }
      } else {
        newItems = await MetadataService.fetchCatalog(
          baseUrl: entry.addon.baseUrl,
          type: entry.catalog.type,
          catalogId: entry.catalog.id,
          extraParams: params.isNotEmpty ? params : null,
          skip: entry.catalog.supportsSkip ? _items.length : 0,
        );
        fetchedCount = newItems.length;

        if (!entry.catalog.supportsSkip) {
          _hasMore = false;
        }
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

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
      });
      _checkAndLoadCatalog();
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.trim();
    });
    _checkAndLoadCatalog();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
    _checkAndLoadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLegacyMode) {
      return _buildLegacyScaffold();
    }
    return _buildDiscoverScaffold();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Full Discover UI
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDiscoverScaffold() {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomInset = mediaQuery.padding.bottom;
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isCompactScreen = screenHeight < 520;

    final sizing = MovieCardSizing.fromWidth(screenWidth);

    final toolbarH = isCompactScreen ? 46.0 : kToolbarHeight;

    final headerHeight = topPadding + toolbarH;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      body: Stack(
        children: [
          // ── Main Content Grid ──
          Positioned.fill(
            child: _buildDiscoverContent(headerHeight, sizing, bottomInset),
          ),

          // ── Glass App Bar & Filters ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(
              topPadding,
              isCompactScreen: isCompactScreen,
              toolbarH: toolbarH,
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

  Widget _buildDiscoverContent(double topOffset, MovieCardSizing sizing, double bottomInset) {
    if (_selectedCatalogEntry == null) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
      );
    }

    if (_items.isEmpty && _error != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
          physics: const BouncingScrollPhysics(),
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

    if (visibleItems.isEmpty) {
      if (_hasMore) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
        );
      }
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, topOffset + 30, 20, 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_alt_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text(
                'No titles match your active filters',
                style: TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                label: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = ((screenWidth - sizing.sidePadding * 2 + sizing.spacing) /
            (sizing.cardWidth + sizing.spacing))
        .floor()
        .clamp(2, 10);
    final double cardAspectRatio = sizing.cardWidth / sizing.totalHeight;

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        sizing.sidePadding,
        topOffset + 14,
        sizing.sidePadding,
        110 + bottomInset,
      ),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: cardAspectRatio,
        crossAxisSpacing: sizing.spacing,
        mainAxisSpacing: sizing.spacing,
      ),
      itemCount: visibleItems.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleItems.length) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
          );
        }
        return MovieCard(movie: visibleItems[index]);
      },
    );
  }

  Widget _buildRequiredExtraGatingPrompt(double topOffset) {
    final missing = _missingRequiredExtras;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 420;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
            color: const Color(0xFF131622).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7C5CFF).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C5CFF).withValues(alpha: 0.1),
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
                  color: const Color(0xFF7C5CFF).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFF9D85FF), size: 30),
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
                      color: const Color(0xFF15171F),
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
                          color: const Color(0xFF7C5CFF),
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
                        backgroundColor: const Color(0xFF7C5CFF),
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
    final screenWidth = MediaQuery.sizeOf(context).width;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15171F),
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
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF7C5CFF)),
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
              backgroundColor: const Color(0xFF7C5CFF),
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

  Widget _buildHeader(
    double topPadding, {
    bool isCompactScreen = false,
    double toolbarH = kToolbarHeight,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 800;
    final isNarrow = screenWidth < 400;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF080A0F).withValues(alpha: 0.95),
                const Color(0xFF080A0F).withValues(alpha: 0.80),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Title Row ──
              SizedBox(
                height: toolbarH,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 19, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 2),
                    if (!_isSearching) ...[
                      const Icon(Icons.explore_rounded, color: Color(0xFF7C5CFF), size: 21),
                      const SizedBox(width: 8),
                      Text(
                        'Discover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 20 : (isNarrow ? 17 : 18),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    if (_isSearching)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            textInputAction: TextInputAction.search,
                            onSubmitted: _onSearchSubmitted,
                            decoration: InputDecoration(
                              hintText: isNarrow
                                  ? 'Search...'
                                  : 'Search within ${_selectedCatalogEntry?.catalog.name ?? 'catalog'}...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                                onPressed: _clearSearch,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),

                    // Search toggle button
                    if (!_isSearching && (_selectedCatalogEntry?.catalog.supportsSearch ?? false))
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 22),
                        tooltip: 'Search catalog',
                        onPressed: () => setState(() => _isSearching = true),
                      ),

                    // Filters button
                    _buildFilterButton(isNarrow),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(bool isNarrow) {
    final count = _activeFilterCount;
    final hasActive = count > 0;

    return GestureDetector(
      onTap: _openFilterSheet,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 14, vertical: 6),
        decoration: BoxDecoration(
          color: hasActive
              ? const Color(0xFF7C5CFF)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActive
                ? const Color(0xFF7C5CFF)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 15,
              color: hasActive ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 5),
            Text(
              'Filters',
              style: TextStyle(
                color: hasActive ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: isNarrow ? 12 : 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Legacy Search/Genre Scaffold (Backwards compatibility)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLegacyScaffold() {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      body: Stack(
        children: [
          if (_legacyLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFF)))
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
                    color: const Color(0xFF0A0C16).withValues(alpha: 0.6),
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
      physics: const BouncingScrollPhysics(),
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
