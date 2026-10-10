import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/manga/manga.dart';
import '../../models/manga/manga_browse_filter.dart';
import '../../services/manga/manga_service.dart';
import '../../services/manga/manga_settings.dart';
import '../../widgets/manga/manga_card.dart';
import 'manga_filter_sheet.dart';

/// Clean dedicated manga search page: back button, search bar, filter
/// button (the full WeebCentral browse filter sheet, applied server-side
/// alongside the query), results in a responsive poster grid, recent
/// searches.
class MangaSearchPage extends StatefulWidget {
  const MangaSearchPage({super.key});

  @override
  State<MangaSearchPage> createState() => _MangaSearchPageState();
}

class _MangaSearchPageState extends State<MangaSearchPage> {
  final MangaService _mangaService = MangaService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool _isLoading = false;
  List<Manga> _results = [];
  MangaBrowseFilter _filters = const MangaBrowseFilter();

  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Search history ────────────────────────────────────────────────────

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('manga_search_history') ?? [];
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('manga_search_history') ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) history.removeLast();
    await prefs.setStringList('manga_search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _removeSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('manga_search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('manga_search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('manga_search_history');
    if (mounted) {
      setState(() {
        _searchHistory = [];
      });
    }
  }

  // ── Search ────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results.clear();
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(trimmed);
    });
  }

  void _performSearch([String? query]) async {
    final q = (query ?? _searchController.text).trim();
    if (q.isEmpty) return;

    _saveSearchHistory(q);
    setState(() => _isLoading = true);

    try {
      final results = await _mangaService.searchManga(q, page: 1, filter: _filters);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  void _applyFilters(MangaBrowseFilter result) {
    if (result == _filters) return;
    setState(() {
      _filters = result;
    });
    // Re-run the search with the new server-side filters applied.
    if (_searchController.text.trim().isNotEmpty) {
      _performSearch();
    }
  }

  // ── Results ──────────────────────────────────────────────────────────

  /// Filtering happens server-side (WeebCentral's search endpoint accepts
  /// the same params as browse), so the raw results list is used as-is.
  List<Manga> get _visibleResults => _results;

  // ── UI ────────────────────────────────────────────────────────────────

  Widget _buildFilterButton() {
    final count = _filters.activeCount;
    final isActive = count > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showMangaFilterSheet(
        context: context,
        current: _filters,
        onApply: _applyFilters,
      ),
      child: Container(
        height: 42,
        width: 42,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF7C5CFF)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF7C5CFF)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.tune_rounded,
                size: 19,
                color: isActive ? Colors.white : Colors.white70,
              ),
            ),
            if (count > 0)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C5CFF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final visible = _visibleResults;
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              padding: EdgeInsets.only(top: topPadding, bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF080A0F).withValues(alpha: 0.90),
                    const Color(0xFF080A0F).withValues(alpha: 0.60),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            autofocus: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textInputAction: TextInputAction.search,
                            onChanged: _onSearchChanged,
                            onSubmitted: (q) => _performSearch(),
                            decoration: InputDecoration(
                              hintText: 'Search manga, manhwa, manhua...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 19,
                                color: Colors.white38,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      color: Colors.white60,
                                      splashRadius: 18,
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildFilterButton(),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
            )
          : visible.isEmpty
          ? _buildEmptyState(topPadding, hasQuery)
          : _buildResultsGrid(topPadding, visible),
    );
  }

  Widget _buildResultsGrid(double topPadding, List<Manga> results) {
    final density = MangaSettings.cardDensity.value;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sizing = MangaCardSizing.fromWidth(screenWidth, density: density);

    return GridView.builder(
      padding: EdgeInsets.only(
        top: topPadding + kToolbarHeight + 20,
        left: sizing.sidePadding,
        right: sizing.sidePadding,
        bottom: 40 + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const ClampingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: sizing.cardWidth + sizing.spacing * 2,
        mainAxisSpacing: 20.0,
        crossAxisSpacing: sizing.spacing,
        mainAxisExtent: sizing.totalHeight,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return SizedBox(
          width: sizing.cardWidth,
          child: MangaCard(manga: results[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(double topPadding, bool hasQuery) {
    final filtered = !_filters.isDefault;

    if (hasQuery || filtered) {
      return Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filtered
                    ? Icons.filter_alt_off_rounded
                    : Icons.search_off_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                filtered
                    ? 'No results match your active filters'
                    : 'No results found',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (filtered) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C5CFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _filters = const MangaBrowseFilter()),
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                  label: const Text('Clear Filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        top: topPadding + kToolbarHeight + 24,
        bottom: 40 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Icon(
          Icons.search_rounded,
          size: 56,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Search manga, manhwa and manhua',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (_searchHistory.isNotEmpty) ...[
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT SEARCHES',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white38,
                    letterSpacing: 1.1,
                  ),
                ),
                GestureDetector(
                  onTap: _clearSearchHistory,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((query) {
                return InputChip(
                  label: Text(query),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  onPressed: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                  onDeleted: () => _removeSearchHistory(query),
                  deleteIconColor: Colors.white38,
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
