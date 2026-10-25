import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/addon/addon.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/movie_section.dart';
import '../../models/stream/stream_model.dart';
import '../../services/addon/addon_manager.dart';
import '../../services/cloudstream/cloudstream_manager.dart';
import '../../services/metadata/tmdb_service.dart';
import '../../theme/playtorrio_tokens.dart';
import '../../widgets/movie/movie_card.dart';
import '../../widgets/search/magnet_files_view.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/app_empty_state.dart';
import '../../widgets/ui/app_text_field.dart';
import '../player/player_screen.dart';
import 'search_filter_sheet.dart';

/// Dedicated search page: back button, search bar, content-type filter,
/// and results in a responsive poster grid.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  bool _isLoading = false;
  List<MovieSection> _results = [];
  String _lastQuery = '';

  bool _isMagnetMode = false;
  String _magnetQuery = '';

  List<String> _searchHistory = [];

  /// Client-side filters applied to the flattened results.
  SearchFilterState _filters = const SearchFilterState();

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Search history ────────────────────────────────────────────────────

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) history.removeLast();
    await prefs.setStringList('search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _removeSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    if (mounted) {
      setState(() {
        _searchHistory = [];
      });
    }
  }

  // ── Link detection / direct playback ────────────────────────────────

  static bool _isMagnetLink(String text) {
    final trimmed = text.trim();
    if (trimmed.toLowerCase().startsWith('magnet:')) return true;
    if (RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(trimmed)) return true;
    if (RegExp(r'^[a-zA-Z2-7]{32}$').hasMatch(trimmed)) return true;
    return false;
  }

  static bool _isStreamLink(String text) {
    final trimmed = text.trim();
    final lower = trimmed.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return false;
    }
    return true;
  }

  void _playDirectStream(String url) {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    String title = 'Direct Stream';
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last;
      if (last.isNotEmpty) {
        title = Uri.decodeComponent(last);
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          source: StreamSource(
            name: 'Direct Stream',
            title: title,
            url: trimmed,
            addonName: 'Direct Stream',
          ),
          title: title,
        ),
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results.clear();
        _isLoading = false;
        _lastQuery = '';
        _isMagnetMode = false;
        _magnetQuery = '';
      });
      return;
    }

    if (_isStreamLink(trimmed)) {
      _playDirectStream(trimmed);
      return;
    }

    if (_isMagnetLink(trimmed)) {
      setState(() {
        _isMagnetMode = true;
        _magnetQuery = trimmed;
        _isLoading = false;
        _results.clear();
      });
      return;
    } else if (_isMagnetMode) {
      setState(() {
        _isMagnetMode = false;
        _magnetQuery = '';
      });
    }

    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (trimmed != _lastQuery) {
        _performSearch(trimmed);
      }
    });
  }

  void _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    if (_isStreamLink(trimmed)) {
      _playDirectStream(trimmed);
      return;
    }

    if (_isMagnetLink(trimmed)) {
      setState(() {
        _isMagnetMode = true;
        _magnetQuery = trimmed;
        _isLoading = false;
        _results.clear();
      });
      return;
    }

    _saveSearchHistory(trimmed);

    setState(() {
      _isLoading = true;
      _lastQuery = trimmed;
      _isMagnetMode = false;
      _results = [];
    });

    final currentQuery = trimmed;

    void addSection(MovieSection section, {bool isCloudStream = false}) {
      if (!mounted || _lastQuery != currentQuery) return;
      if (section.movies.isEmpty) return;

      // Prevent duplicate sections by addon + catalog identity — NOT display
      // name. Addons like Cinemeta name both their movie and series catalogs
      // "Popular", which used to drop the series results as "duplicates".
      final exists = _results.any(
        (s) =>
            s.addonBaseUrl == section.addonBaseUrl &&
            s.catalog.type == section.catalog.type &&
            s.catalog.id == section.catalog.id,
      );
      if (exists) return;

      setState(() {
        if (!isCloudStream &&
            (section.addonBaseUrl.contains('cinemeta') ||
                section.subtitle.toLowerCase().contains('cinemeta'))) {
          // Prioritize Cinemeta at the top
          _results.insert(0, section);
        } else {
          _results.add(section);
        }
      });
    }

    try {
      // 1. Metadata search — TMDB when configured, else Stremio addons.
      final Future<List<MovieSection>> addonSearch = TmdbService.isConfigured
          ? TmdbService.searchMulti(currentQuery).then((movies) {
              if (!mounted || _lastQuery != currentQuery || movies.isEmpty) {
                return <MovieSection>[];
              }

              final movieItems = movies.where((m) => m.type == 'movie').toList();
              final seriesItems =
                  movies.where((m) => m.type == 'series').toList();

              if (movieItems.isNotEmpty) {
                addSection(
                  MovieSection(
                    title: 'Movies',
                    subtitle: 'TMDB',
                    contentType: 'movie',
                    addonBaseUrl: TmdbService.kSentinel,
                    catalog: AddonCatalog(
                      type: 'movie',
                      id: 'tmdb_search_movie',
                      name: 'Movies',
                    ),
                    movies: movieItems,
                  ),
                );
              }
              if (seriesItems.isNotEmpty) {
                addSection(
                  MovieSection(
                    title: 'Series',
                    subtitle: 'TMDB',
                    contentType: 'series',
                    addonBaseUrl: TmdbService.kSentinel,
                    catalog: AddonCatalog(
                      type: 'series',
                      id: 'tmdb_search_series',
                      name: 'Series',
                    ),
                    movies: seriesItems,
                  ),
                );
              }
              return <MovieSection>[];
            }).catchError((e) {
              debugPrint('[SearchPage] TMDB search error: $e');
              return <MovieSection>[];
            })
          : AddonManager.instance
              .searchAll(
                currentQuery,
                onSectionResult: (section) {
                  addSection(section, isCloudStream: false);
                },
              )
              .catchError((e) {
                debugPrint('[SearchPage] Addon search error: $e');
                return <MovieSection>[];
              });

      // 2. Search CloudStream Extensions with dynamic streaming
      final csSearch =
          (CloudStreamManager.instance.activeExtensions.isNotEmpty
                  ? CloudStreamManager.instance.searchAcrossExtensions(
                      currentQuery,
                      onProviderResult: (providerName, items) {
                        if (!mounted || _lastQuery != currentQuery) return;
                        if (items.isEmpty) return;

                        final movies = <Movie>[];
                        for (final item in items) {
                          final title =
                              item['title']?.toString() ??
                              item['name']?.toString() ??
                              'Unknown';
                          final rawUrl = item['url']?.toString() ?? '';
                          final sourceId =
                              item['_sourceId']?.toString() ??
                              'cs_${providerName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
                          final cover =
                              item['cover']?.toString() ??
                              item['poster']?.toString() ??
                              item['image']?.toString();
                          final isSeries =
                              item['type'] == 1 ||
                              item['type']?.toString().toLowerCase().contains(
                                    'series',
                                  ) ==
                                  true ||
                              item['type']?.toString().toLowerCase().contains(
                                    'tv',
                                  ) ==
                                  true ||
                              (item['extraData'] is Map &&
                                  (item['extraData'] as Map)['type']
                                          ?.toString()
                                          .toLowerCase()
                                          .contains('series') ==
                                      true);

                          movies.add(
                            Movie(
                              id: 'cloudstream:$sourceId:${Uri.encodeComponent(rawUrl)}',
                              name: title,
                              poster: cover,
                              year:
                                  item['year']?.toString() ??
                                  (item['extraData'] is Map
                                      ? (item['extraData'] as Map)['year']
                                            ?.toString()
                                      : null),
                              type: isSeries ? 'series' : 'movie',
                              addonBaseUrl: 'cloudstream',
                            ),
                          );
                        }

                        if (movies.isNotEmpty) {
                          final section = MovieSection(
                            title: 'CloudStream • $providerName',
                            subtitle: 'CloudStream Extension',
                            contentType: 'movie',
                            addonBaseUrl: 'cloudstream',
                            catalog: AddonCatalog(
                              type: 'movie',
                              id: 'cs_$providerName',
                              name: providerName,
                            ),
                            movies: movies,
                          );
                          addSection(section, isCloudStream: true);
                        }
                      },
                    )
                  : Future.value(<String, List<Map<String, dynamic>>>{}))
              .catchError((e) {
                debugPrint('[SearchPage] CloudStream search error: $e');
                return <String, List<Map<String, dynamic>>>{};
              });

      await Future.wait([
        addonSearch,
        csSearch,
      ]).timeout(const Duration(seconds: 20), onTimeout: () => <Object>[]);
    } catch (_) {}

    if (mounted && _lastQuery == currentQuery) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _searchController.text = text;
      _onSearchChanged(text);
      if (!_isMagnetLink(text) && !_isStreamLink(text)) {
        _performSearch(text);
      }
    }
  }

  // ── Results ──────────────────────────────────────────────────────────

  static int? _extractYear(String? s) {
    if (s == null || s.isEmpty) return null;
    final m = RegExp(r'(19|20)\d{2}').firstMatch(s);
    return m != null ? int.tryParse(m.group(0)!) : null;
  }

  static double? _ratingOf(Movie m) => double.tryParse(m.imdbRating ?? '');

  int _cmpNullsLast(double? va, double? vb) {
    if (va == null && vb == null) return 0;
    if (va == null) return 1;
    if (vb == null) return -1;
    return _filters.sortDescending ? vb.compareTo(va) : va.compareTo(vb);
  }

  int _compareBySort(Movie a, Movie b) {
    switch (_filters.sortKey) {
      case 'title':
        final an = a.name.toLowerCase();
        final bn = b.name.toLowerCase();
        return _filters.sortDescending ? bn.compareTo(an) : an.compareTo(bn);
      case 'popularity':
        return _cmpNullsLast(a.popularity, b.popularity);
      case 'score':
        return _cmpNullsLast(_ratingOf(a), _ratingOf(b));
      case 'year':
        return _cmpNullsLast(
          _extractYear(a.year)?.toDouble(),
          _extractYear(b.year)?.toDouble(),
        );
      default:
        return 0;
    }
  }

  /// Union of genres present across all current results, sorted.
  List<String> get _availableGenres {
    final seen = <String>{};
    final list = <String>[];
    for (final sec in _results) {
      for (final m in sec.movies) {
        for (final g in m.genres) {
          final trimmed = g.trim();
          if (trimmed.isNotEmpty && seen.add(trimmed)) {
            list.add(trimmed);
          }
        }
      }
    }
    list.sort();
    return list;
  }

  /// Flattens result sections into a deduplicated, filtered, sorted list.
  List<Movie> get _filteredMovies {
    final seen = <String>{};
    final list = <Movie>[];
    final f = _filters;

    for (final sec in _results) {
      for (final m in sec.movies) {
        if (f.type != 'all' && m.type != f.type) continue;

        if (f.genres.isNotEmpty) {
          final hasAny = m.genres.any(f.genres.contains);
          if (!hasAny) continue;
        }

        if (f.minYear != null || f.maxYear != null) {
          final y = _extractYear(m.year);
          if (y == null) continue;
          if (f.minYear != null && y < f.minYear!) continue;
          if (f.maxYear != null && y > f.maxYear!) continue;
        }
        if (f.minRating != null || f.maxRating != null) {
          final r = _ratingOf(m);
          if (r == null) continue;
          if (f.minRating != null && r < f.minRating!) continue;
          if (f.maxRating != null && r > f.maxRating!) continue;
        }
        if (f.minDuration != null || f.maxDuration != null) {
          final d = m.runtime;
          if (d == null) continue;
          if (f.minDuration != null && d < f.minDuration!) continue;
          if (f.maxDuration != null && d > f.maxDuration!) continue;
        }

        if (!seen.add(m.id)) continue;
        list.add(m);
      }
    }

    if (f.sortKey != null) {
      list.sort(_compareBySort);
    }
    return list;
  }

  void _applyFilters(SearchFilterState result) {
    if (result == _filters) return;
    setState(() {
      _filters = result;
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────

  Widget _buildFilterButton() {
    final tokens = PlayTorrioTokens.of(context);
    final count = _filters.activeCount;
    final isActive = count > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showSearchFilterSheet(
        context: context,
        current: _filters,
        availableGenres: _availableGenres,
        onApply: _applyFilters,
      ),
      child: Container(
        height: 42,
        width: 42,
        margin: const EdgeInsets.only(left: 8, right: 12),
        decoration: BoxDecoration(
          color: isActive ? tokens.accent : tokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? tokens.accent : tokens.borderSubtle,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.tune_rounded,
                size: 19,
                color: isActive ? tokens.onAccent : tokens.textPrimary,
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
                    color: tokens.textPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: tokens.accent,
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
    final tokens = PlayTorrioTokens.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final movies = _filteredMovies;

    return Scaffold(
      backgroundColor: tokens.bgPrimary,
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
                    tokens.bgPrimary.withValues(alpha: 0.90),
                    tokens.bgPrimary.withValues(alpha: 0.60),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: tokens.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                    color: tokens.textPrimary,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: AppSearchField(
                          controller: _searchController,
                          hintText: 'Search movies, series, or paste links',
                          autofocus: true,
                          onChanged: _onSearchChanged,
                          onSubmitted: _performSearch,
                          emptySuffix: IconButton(
                            icon: const Icon(
                              Icons.content_paste_rounded,
                              size: 17,
                            ),
                            tooltip: 'Paste from clipboard',
                            onPressed: _pasteFromClipboard,
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
      body: Stack(
        children: [
          if (_isMagnetMode && _magnetQuery.isNotEmpty)
            MagnetFilesView(key: ValueKey(_magnetQuery), magnet: _magnetQuery)
          else if (_isLoading && _results.isEmpty)
            Center(
              child: CircularProgressIndicator(color: tokens.accent),
            )
          else if (!_isLoading && _lastQuery.isNotEmpty && movies.isEmpty)
            Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 32,
                ),
                child: AppEmptyState(
                  icon: _results.isNotEmpty
                      ? Icons.filter_alt_off_rounded
                      : Icons.search_off_rounded,
                  title: _results.isNotEmpty
                      ? 'No results match your active filters'
                      : 'No results for "$_lastQuery"',
                  action: _results.isNotEmpty
                      ? AppButton(
                          label: 'Clear Filters',
                          icon: Icons.filter_alt_off_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => setState(
                            () => _filters = const SearchFilterState(),
                          ),
                        )
                      : null,
                ),
              ),
            )
          else if (movies.isNotEmpty)
            Builder(
              builder: (context) {
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
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    return MovieCard(movie: movies[index]);
                  },
                );
              },
            )
          else
            _buildEmptyState(topPadding),

          if (_isLoading && _results.isNotEmpty)
            Positioned(
              top: topPadding + kToolbarHeight + 10,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double topPadding) {
    final tokens = PlayTorrioTokens.of(context);

    return ListView(
      clipBehavior: Clip.none,
      padding: EdgeInsets.only(
        top: topPadding + kToolbarHeight + 24,
        bottom: 40 + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const ClampingScrollPhysics(),
      children: [
        const AppEmptyState(
          icon: Icons.search_rounded,
          title: 'Search for movies, series, or paste a link',
        ),

        // Recent Searches
        if (_searchHistory.isNotEmpty) ...[
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT SEARCHES',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: tokens.textTertiary,
                    letterSpacing: 1.1,
                  ),
                ),
                GestureDetector(
                  onTap: _clearSearchHistory,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.accent,
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
                  labelStyle: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: tokens.surface,
                  side: BorderSide(color: tokens.borderSubtle),
                  onPressed: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                  onDeleted: () => _removeSearchHistory(query),
                  deleteIconColor: tokens.textTertiary,
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
