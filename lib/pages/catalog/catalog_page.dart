import 'package:flutter/material.dart';

import '../../models/movie/movie.dart';
import '../../models/movie/movie_section.dart';
import '../../services/metadata/metadata_service.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/page_top_bar.dart';
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
      final newItems = await MetadataService.fetchCatalog(
        baseUrl: widget.section.addonBaseUrl,
        type: widget.section.contentType,
        catalogId: widget.section.catalog.id,
        extraParams: _selectedExtras.isNotEmpty ? _selectedExtras : null,
        skip: _items.length,
      );

      if (!mounted) return;

      setState(() {
        if (newItems.isEmpty) {
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
    final topPadding = MediaQuery.of(context).padding.top;
    final sizing = MovieCardSizing.fromWidth(MediaQuery.sizeOf(context).width);
    final gridTopPadding = topPadding + kToolbarHeight + 40;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      body: Stack(
        children: [
          // ── Main Content Grid ──
          if (_items.isEmpty && _isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
            )
          else if (_items.isEmpty && _error != null)
            ErrorView(
              error: _error,
              onRetry: () => _loadItems(refresh: true),
            )
          else if (_items.isEmpty)
            const Center(
              child: Text(
                'No items found',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          else
            GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                sizing.sidePadding,
                gridTopPadding,
                sizing.sidePadding,
                40 + MediaQuery.paddingOf(context).bottom, // Bottom padding
              ),
              physics: const ClampingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    ((MediaQuery.sizeOf(context).width - sizing.sidePadding * 2 + sizing.spacing) /
                            (sizing.cardWidth + sizing.spacing))
                        .floor()
                        .clamp(2, 10),
                childAspectRatio: sizing.cardWidth / sizing.totalHeight,
                crossAxisSpacing: sizing.spacing,
                mainAxisSpacing: sizing.spacing,
              ),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
                  );
                }
                return MovieCard(movie: _items[index]);
              },
            ),

          // ── Glass App Bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PageTopBar(
              topPadding: topPadding,
              title: widget.section.title,
              showBack: true,
            ),
          ),
        ],
      ),
    );
  }
}
