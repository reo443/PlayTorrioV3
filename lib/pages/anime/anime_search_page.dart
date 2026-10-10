import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/anime/anime_media.dart';
import '../../services/anime/anilist_service.dart';
import '../../utils/navigation/route_transitions.dart';
import '../../widgets/anime/anime_card.dart';
import '../../widgets/movie/movie_card.dart';
import 'anime_details_page.dart';
import 'anime_search_filter_sheet.dart';

/// Clean dedicated anime search page: back button, search bar, filter
/// button, results in a responsive poster grid, recent searches.
class AnimeSearchPage extends StatefulWidget {
  const AnimeSearchPage({super.key});

  @override
  State<AnimeSearchPage> createState() => _AnimeSearchPageState();
}

class _AnimeSearchPageState extends State<AnimeSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool _isLoading = false;
  List<AnimeMedia> _results = [];
  AnimeSearchFilterState _filters = const AnimeSearchFilterState();

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
    final history = prefs.getStringList('anime_search_history') ?? [];
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('anime_search_history') ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) history.removeLast();
    await prefs.setStringList('anime_search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _removeSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('anime_search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('anime_search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('anime_search_history');
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
    if (trimmed.isEmpty && !_filters.isDefault) {
      // Keep filtered browse when the text is cleared.
      _debounce = Timer(const Duration(milliseconds: 400), () {
        _performSearch('');
      });
      return;
    }
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
    final hasText = q.isNotEmpty;

    if (!hasText && _filters.isDefault) {
      setState(() {
        _results.clear();
        _isLoading = false;
      });
      return;
    }

    if (hasText) {
      _saveSearchHistory(q);
    }

    setState(() => _isLoading = true);

    try {
      final results = await AnilistService.instance.searchAnime(
        q,
        genre: _filters.genre,
        year: _filters.year,
        season: _filters.season,
        format: _filters.format,
        status: _filters.status,
        sort: _filters.sort,
        isAdult: _filters.adult,
        perPage: 40,
      );
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

  void _applyFilters(AnimeSearchFilterState result) {
    if (result == _filters) return;
    setState(() {
      _filters = result;
    });
    _performSearch();
  }

  void _openDetails(AnimeMedia anime) {
    Navigator.push(
      context,
      CinematicSlideRoute(page: AnimeDetailsPage(anime: anime)),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────

  Widget _buildFilterButton() {
    final count = _filters.activeCount;
    final isActive = count > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showAnimeSearchFilterSheet(
        context: context,
        current: _filters,
        onApply: _applyFilters,
      ),
      child: Container(
        height: 42,
        width: 42,
        margin: const EdgeInsets.only(left: 8, right: 12),
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
                              hintText: _filters.isDefault
                                  ? 'Search anime...'
                                  : 'Search anime (filtered)...',
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
          : _results.isEmpty
          ? _buildEmptyState(topPadding)
          : _buildResultsGrid(topPadding),
    );
  }

  Widget _buildResultsGrid(double topPadding) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sizing = MovieCardSizing.fromWidth(screenWidth);
    final columns =
        ((screenWidth - sizing.sidePadding * 2 + sizing.spacing) /
                (sizing.cardWidth + sizing.spacing))
            .floor()
            .clamp(2, 10);

    return GridView.builder(
      padding: EdgeInsets.only(
        top: topPadding + kToolbarHeight + 20,
        left: sizing.sidePadding,
        right: sizing.sidePadding,
        bottom: 40 + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const ClampingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: sizing.cardWidth / sizing.totalHeight,
        crossAxisSpacing: sizing.spacing,
        mainAxisSpacing: sizing.spacing,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return SizedBox(
          width: sizing.cardWidth,
          child: AnimeCard(
            anime: _results[index],
            width: sizing.cardWidth,
            onTap: () => _openDetails(_results[index]),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(double topPadding) {
    final filtered = !_filters.isDefault;
    final hasQueryOrFilters =
        _searchController.text.trim().isNotEmpty || filtered;

    if (hasQueryOrFilters) {
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
                      setState(() => _filters = const AnimeSearchFilterState()),
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
            'Search for anime, or filter by genre, season, format and more',
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
