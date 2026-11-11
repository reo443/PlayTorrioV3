import 'package:flutter/material.dart';

import '../../models/movie/movie.dart';
import '../../models/movie/movie_section.dart';
import '../../services/metadata/metadata_service.dart';
import '../../services/metadata/tmdb_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/floating_back_button.dart';
import '../../widgets/movie/movie_card.dart';

class CatalogPage extends StatefulWidget {
  final MovieSection section;

  const CatalogPage({
    super.key,
    required this.section,
  });

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final List<Movie> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  final Map<String, String> _selectedExtras = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Auto-select required extras (e.g. the current year for the "New"
    // catalog) — the page no longer shows a filter row to pick them
    // manually.
    for (final req in widget.section.catalog.requiredExtras) {
      if (_selectedExtras[req.name] == null && req.options.isNotEmpty) {
        _selectedExtras[req.name] = req.options.first;
      }
    }

    _loadItems(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    if (refresh) {
      setState(() {
        _items.clear();
        _hasMore = true;
        _error = null;
      });
    }

    if (!_hasMore) return;

    // Merged (mixed) sections combine movies + series from multiple catalogs
    // and can't be re-fetched from a single endpoint — serve the section's
    // own items instead (e.g. Trending Today / Trending Week).
    if (widget.section.contentType == 'mixed') {
      final seen = _items.map((m) => '${m.type}:${m.id}').toSet();
      setState(() {
        for (final m in widget.section.movies) {
          final key = '${m.type}:${m.id}';
          if (seen.add(key)) _items.add(m);
        }
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    // Safety: required extras must be selected (auto-selected in initState).
    if (widget.section.catalog.hasRequiredExtra) {
      for (final req in widget.section.catalog.requiredExtras) {
        final val = _selectedExtras[req.name];
        if (val == null || val.trim().isEmpty) {
          setState(() {
            _isLoading = false;
            _hasMore = false;
          });
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final isTmdb = widget.section.addonBaseUrl == TmdbService.kSentinel;

      final newItems = isTmdb
          ? await TmdbService.fetchList(
              widget.section.catalog.id,
              page: (_items.length ~/ TmdbService.pageSize) + 1,
            )
          : await MetadataService.fetchCatalog(
              baseUrl: widget.section.addonBaseUrl,
              type: widget.section.contentType,
              catalogId: widget.section.catalog.id,
              extraParams: _selectedExtras.isNotEmpty ? _selectedExtras : null,
              skip: _items.length,
            );

      if (!mounted) return;

      setState(() {
        if (isTmdb) {
          // Trending lists shift between pages — dedupe by id.
          final seen = _items.map((m) => m.id).toSet();
          for (final m in newItems) {
            if (seen.add(m.id)) _items.add(m);
          }
          if (newItems.length < TmdbService.pageSize) _hasMore = false;
        } else if (newItems.isEmpty) {
          _hasMore = false;
        } else {
          _items.addAll(newItems);
        }
        _isLoading = false;
      });

      // If content doesn't fill the viewport yet, load more immediately.
      // This fixes fullscreen mode where the initial batch doesn't produce
      // enough scroll extent to ever trigger _onScroll.
      if (_hasMore && !_isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          if (_scrollController.position.maxScrollExtent <= 0) {
            _loadItems();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sizing = MovieCardSizing.fromWidth(MediaQuery.sizeOf(context).width);
    final tokens = PlayTorrioTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bgPrimary,
      body: Stack(
        children: [
          // ── Main Content Grid ──
          if (_items.isEmpty && _isLoading)
            Center(child: CircularProgressIndicator(color: tokens.accent))
          else if (_items.isEmpty && _error != null)
            ErrorView(
              error: _error,
              onRetry: () => _loadItems(refresh: true),
            )
          else if (_items.isEmpty)
            Center(
              child: Text(
                'No items found',
                style: TextStyle(color: tokens.textSecondary, fontSize: 16),
              ),
            )
          else
            _buildGrid(tokens, sizing, topPadding, bottomInset),

          // ── Floating back ──
          Positioned(
            top: topPadding + AppSpacing.xs,
            left: AppSpacing.md,
            child: const FloatingBackButton(),
          ),
        ],
      ),
    );
  }

  /// The grid plus the section title, which scrolls away with the content.
  ///
  /// There is no top bar on this page: the back control floats over the grid
  /// and the title sits in the scroll view, so the artwork keeps the top of
  /// the screen instead of losing it to a chrome strip.
  Widget _buildGrid(
    PlayTorrioTokens tokens,
    MovieCardSizing sizing,
    double topInset,
    double bottomInset,
  ) {
    final gridMetrics = sizing.grid;

    return CustomScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gridMetrics.padding,
            topInset + 56,
            gridMetrics.padding,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              widget.section.title,
              style: AppTypography.screenTitle.copyWith(color: tokens.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gridMetrics.padding,
            0,
            gridMetrics.padding,
            40 + bottomInset,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridMetrics.columns,
              childAspectRatio: gridMetrics.aspectRatio,
              crossAxisSpacing: sizing.spacing,
              mainAxisSpacing: sizing.spacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => MovieCard(movie: _items[index]),
              childCount: _items.length,
            ),
          ),
        ),
        if (_hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: CircularProgressIndicator(color: tokens.accent),
              ),
            ),
          ),
      ],
    );
  }
}
