import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/movie/tmdb_person.dart';
import '../../services/metadata/tmdb_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';
import '../../widgets/common/page_top_bar.dart';
import '../../widgets/movie/movie_card.dart';
import '../../widgets/ui/app_empty_state.dart';
import '../../widgets/ui/app_error_state.dart';

/// A TMDB person page: photo, name, department and a short biography, followed
/// by their movie + TV credits as poster cards.
///
/// Reached from the cast row on the details page. Cast members only carry a
/// name, so the lookup is name-based (search → profile). Transparent over the
/// app's ambient background, like the other catalogue screens.
class PersonPage extends StatefulWidget {
  const PersonPage({super.key, required this.name, this.loader});

  /// Display name to look up, e.g. "Tom Hardy".
  final String name;

  /// Test seam; defaults to [TmdbService.fetchPersonByName].
  final Future<TmdbPerson?> Function(String name)? loader;

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  TmdbPerson? _person;
  bool _isLoading = true;
  bool _notConfigured = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loader = widget.loader;
    final isConfigured = loader != null || TmdbService.isConfigured;

    setState(() {
      _isLoading = true;
      _notConfigured = !isConfigured;
      _error = null;
    });
    if (!isConfigured) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final person = await (loader ?? TmdbService.fetchPersonByName)(
        widget.name,
      );
      if (!mounted) return;
      setState(() {
        _person = person;
        _isLoading = false;
      });
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
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomInset = mediaQuery.padding.bottom;
    final headerHeight = topPadding + 56;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBody(headerHeight, bottomInset)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PageTopBar(
              topPadding: topPadding,
              title: 'Person',
              showBack: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double topOffset, double bottomInset) {
    final tokens = PlayTorrioTokens.of(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: tokens.accent));
    }

    final padding = EdgeInsets.fromLTRB(
      AppSpacing.xl,
      topOffset + AppSpacing.xxl,
      AppSpacing.xl,
      AppSpacing.xxxl + bottomInset,
    );

    if (_notConfigured) {
      return _centered(
        padding,
        const AppEmptyState(
          icon: Icons.key_off_rounded,
          title: 'TMDB is not configured',
          message: 'Add a TMDB API key to look up cast members.',
        ),
      );
    }

    if (_error != null) {
      return _centered(
        padding,
        AppErrorState(
          title: 'Could not load this person',
          message: _error,
          onRetry: _load,
        ),
      );
    }

    final person = _person;
    if (person == null) {
      return _centered(
        padding,
        AppEmptyState(
          icon: Icons.person_off_rounded,
          title: 'Person not found',
          message: 'No TMDB profile matches "${widget.name}".',
        ),
      );
    }

    return _buildProfile(person, topOffset, bottomInset);
  }

  Widget _centered(EdgeInsets padding, Widget child) {
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: padding,
        child: child,
      ),
    );
  }

  Widget _buildProfile(
    TmdbPerson person,
    double topOffset,
    double bottomInset,
  ) {
    final tokens = PlayTorrioTokens.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sizing = MovieCardSizing.fromWidth(screenWidth);
    final columns =
        ((screenWidth - sizing.sidePadding * 2 + sizing.spacing) /
                (sizing.cardWidth + sizing.spacing))
            .floor()
            .clamp(2, 10);
    final cardAspectRatio = sizing.cardWidth / sizing.totalHeight;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            sizing.sidePadding,
            topOffset + AppSpacing.xl,
            sizing.sidePadding,
            0,
          ),
          sliver: SliverToBoxAdapter(child: _buildHeader(person, tokens)),
        ),
        if (person.credits.isEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxxl + bottomInset,
            ),
            sliver: const SliverToBoxAdapter(
              child: AppEmptyState(
                icon: Icons.movie_filter_outlined,
                title: 'No credits yet',
                message: 'TMDB has no movie or TV credits for this person.',
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              sizing.sidePadding,
              AppSpacing.xxl,
              sizing.sidePadding,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Known for',
                style: AppTypography.sectionHeading.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              sizing.sidePadding,
              AppSpacing.md,
              sizing.sidePadding,
              AppSpacing.xxxl + bottomInset,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: cardAspectRatio,
                crossAxisSpacing: sizing.spacing,
                mainAxisSpacing: sizing.spacing,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => MovieCard(movie: person.credits[index]),
                childCount: person.credits.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(TmdbPerson person, PlayTorrioTokens tokens) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final photoSize = isNarrow ? 96.0 : 132.0;

    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: photoSize,
        height: photoSize,
        child: ColoredBox(
          color: tokens.surfaceElevated,
          child: person.profileUrl == null
              ? Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: tokens.textTertiary,
                )
              : CachedNetworkImage(
                  imageUrl: person.profileUrl!,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          person.name,
          style: AppTypography.screenTitle.copyWith(color: tokens.textPrimary),
        ),
        if (person.department.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            person.department,
            style: AppTypography.label.copyWith(color: tokens.accent),
          ),
        ],
        if (person.biography.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            person.biography,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.supporting.copyWith(
              color: tokens.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ],
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          photo,
          const SizedBox(height: AppSpacing.lg),
          info,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        photo,
        const SizedBox(width: AppSpacing.xxl),
        Expanded(child: info),
      ],
    );
  }
}
