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

  ({InstalledAddon addon, AddonCatalog catalog})? _selectedCatalogEntry;
  final Map<String, String> _selectedExtras = {};

  final List<Movie> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

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

    final sizing = MovieCardSizing.fromWidth(screenWidth);

    // PageTopBar height: status bar + top pad 6 + row ~38 + bottom pad 10
    final headerHeight = topPadding + 56;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      body: Stack(
        children: [
          // ── Main Content Grid ──
          Positioned.fill(
            child: _buildDiscoverContent(headerHeight, sizing, bottomInset),
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

  Widget _buildDiscoverContent(double topOffset, MovieCardSizing sizing, double bottomInset) {
    if (_selectedCatalogEntry == null) {
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
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

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        sizing.sidePadding,
        topOffset + 14,
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
