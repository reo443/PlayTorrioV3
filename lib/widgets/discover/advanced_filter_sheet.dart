import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/discover/discover_filter_state.dart';
import '../../services/metadata/tmdb_service.dart';
import '../../services/theme/app_theme_service.dart';
import 'filter_option_sheet.dart';

/// A vertically scrolling advanced-filter bottom sheet for the Browse screen.
///
/// Pops with the applied [DiscoverFilterState] (or `null` when dismissed
/// without applying). The header, action bar and validation all derive from a
/// single draft state, so selections survive close/reopen via the caller.
class AdvancedFilterSheet extends StatefulWidget {
  /// `movie` or `series` — drives genre/provider/certification lists.
  final String mediaType;

  /// Currently applied filters (used to seed the draft).
  final DiscoverFilterState initial;

  /// Returns the live result count for a draft, or `null` when unavailable.
  /// Callers must not fabricate a count, so the sheet falls back to
  /// "Show results" when this returns null.
  final Future<int?> Function(DiscoverFilterState draft) countResults;

  const AdvancedFilterSheet({
    super.key,
    required this.mediaType,
    required this.initial,
    required this.countResults,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  static const int _collapsedGenres = 9;
  static const int _collapsedProviders = 12;

  late DiscoverFilterState _draft = widget.initial;

  // Option lists (loaded from TMDB).
  List<({int id, String name})> _genres = const [];
  List<({int id, String name})> _providers = const [];
  List<String> _certifications = const [];
  List<({String code, String name})> _countries = const [];
  List<({String code, String name})> _languages = const [];

  bool _genresLoading = true;
  bool _providersLoading = true;
  bool _certsLoading = true;
  bool _countriesLoading = false;
  bool _languagesLoading = false;

  bool _genresFailed = false;
  bool _providersFailed = false;
  bool _certsFailed = false;
  bool _countriesFailed = false;
  bool _languagesFailed = false;

  bool _genresExpanded = false;
  bool _providersExpanded = false;
  bool _certsExpanded = false;

  // Live result count.
  int? _count;
  bool _counting = false;
  Timer? _countDebounce;

  bool get _yearRangeValid =>
      _draft.yearFrom == null ||
      _draft.yearTo == null ||
      _draft.yearFrom! <= _draft.yearTo!;

  @override
  void initState() {
    super.initState();
    _loadCoreOptions();
    _scheduleCount();
  }

  @override
  void dispose() {
    _countDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCoreOptions() async {
    try {
      final genres = await TmdbService.fetchGenres(widget.mediaType);
      if (!mounted) return;
      setState(() {
        _genres = genres;
        _genresLoading = false;
        _genresFailed = genres.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _genresLoading = false;
        _genresFailed = true;
      });
    }

    try {
      final providers = await TmdbService.fetchWatchProviders(widget.mediaType);
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _providersLoading = false;
        _providersFailed = providers.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _providersLoading = false;
        _providersFailed = true;
      });
    }

    try {
      final certs = await TmdbService.fetchCertifications(widget.mediaType);
      if (!mounted) return;
      setState(() {
        _certifications = certs;
        _certsLoading = false;
        _certsFailed = certs.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _certsLoading = false;
        _certsFailed = true;
      });
    }
  }

  Future<void> _ensureCountries() async {
    if (_countries.isNotEmpty || _countriesLoading) return;
    setState(() => _countriesLoading = true);
    try {
      final countries = await TmdbService.fetchCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _countriesLoading = false;
        _countriesFailed = countries.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _countriesLoading = false;
        _countriesFailed = true;
      });
    }
  }

  Future<void> _ensureLanguages() async {
    if (_languages.isNotEmpty || _languagesLoading) return;
    setState(() => _languagesLoading = true);
    try {
      final languages = await TmdbService.fetchLanguages();
      if (!mounted) return;
      setState(() {
        _languages = languages;
        _languagesLoading = false;
        _languagesFailed = languages.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _languagesLoading = false;
        _languagesFailed = true;
      });
    }
  }

  void _updateDraft(DiscoverFilterState next) {
    if (next == _draft) return;
    setState(() => _draft = next);
    _scheduleCount();
  }

  void _scheduleCount() {
    _countDebounce?.cancel();
    setState(() => _counting = true);
    _countDebounce = Timer(const Duration(milliseconds: 450), _refreshCount);
  }

  Future<void> _refreshCount() async {
    final requested = _draft;
    int? total;
    try {
      total = await widget.countResults(requested);
    } catch (_) {
      total = null;
    }
    if (!mounted || requested != _draft) return;
    setState(() {
      _count = total;
      _counting = false;
    });
  }

  void _resetAll() {
    _updateDraft(DiscoverFilterState.empty);
  }

  // ── Pickers that need to distinguish "cleared" from "dismissed" ──────────

  Future<bool> _pickAndClearable<T>({
    required String title,
    required List<({T value, String label})> options,
    required T? selected,
    required ValueChanged<T?> onChanged,
    bool searchable = false,
    required VoidCallback onCleared,
  }) async {
    final accent = AppThemeService.currentPalette.value.primaryColor;
    final result = await showModalBottomSheet<({T? value})>(
      context: context,
      backgroundColor: AppThemeService.currentPalette.value.cardBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FilterOptionSheet<T>(
        title: title,
        options: options,
        selected: selected,
        accent: accent,
        searchable: searchable,
        onSelected: (value) => Navigator.pop(ctx, (value: value)),
      ),
    );
    if (result == null) return false;
    if (result.value == null) {
      onCleared();
    } else {
      onChanged(result.value);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeService.currentPalette.value;
    final accent = palette.primaryColor;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: palette.cardBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(accent),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(
                      icon: Icons.local_movies_outlined,
                      label: 'Genre',
                      child: _buildGenreChips(accent),
                    ),
                    _divider(),
                    _section(
                      icon: Icons.star_rate_rounded,
                      label: 'Minimum score',
                      trailing: Text(
                        _draft.minScore <= 0
                            ? 'Any'
                            : '${_draft.minScore.toStringAsFixed(1)}+',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      child: _buildScoreSlider(accent),
                    ),
                    _divider(),
                    _section(
                      icon: Icons.schedule_rounded,
                      label: 'Runtime',
                      child: _buildRuntimeChips(accent),
                    ),
                    _divider(),
                    _section(
                      icon: Icons.calendar_today_rounded,
                      label: 'Release year',
                      trailing: _yearRangeValid
                          ? null
                          : Text(
                              'Start year is after end year',
                              style: TextStyle(
                                color: Colors.redAccent.withValues(alpha: 0.9),
                                fontSize: 11.5,
                              ),
                            ),
                      child: _buildYearRange(accent),
                    ),
                    _divider(),
                    _section(
                      icon: Icons.live_tv_rounded,
                      label: 'Streaming services',
                      child: _buildProviderChips(accent),
                    ),
                    _divider(),
                    _section(
                      icon: Icons.translate_rounded,
                      label: 'Language',
                      trailing: Text(
                        'Single select',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11.5,
                        ),
                      ),
                      child: _buildLanguageChips(accent),
                    ),
                    _divider(),
                    _section(
                      icon: Icons.public_rounded,
                      label: 'Country',
                      trailing: Text(
                        'Single select',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11.5,
                        ),
                      ),
                      child: _buildCountrySelector(accent),
                    ),
                    _divider(),
                    _buildCertificationSection(accent),
                  ],
                ),
              ),
            ),
            _buildActionBar(accent),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(Color accent) {
    return Column(
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
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_draft.activeCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '${_draft.activeCount} active',
                              style: TextStyle(
                                color: accent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Find exactly what you're in the mood for",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────

  Widget _section({
    required IconData icon,
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    thickness: 1,
    color: Colors.white.withValues(alpha: 0.06),
  );

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = AppThemeService.currentPalette.value.primaryColor;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipWrap(List<Widget> chips) {
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _unavailable() => Text(
    'Unavailable right now',
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 12.5,
    ),
  );

  Widget _miniLoader() => const SizedBox(
    height: 28,
    child: Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  Widget _buildGenreChips(Color accent) {
    if (_genresLoading) return _miniLoader();
    if (_genresFailed || _genres.isEmpty) return _unavailable();

    final visible = _genresExpanded
        ? _genres
        : _genres.take(_collapsedGenres).toList();

    return _chipWrap([
      for (final g in visible)
        _chip(
          g.name,
          selected: _draft.genreIds.contains(g.id),
          onTap: () => _updateDraft(_draft.toggleGenre(g.id)),
        ),
      if (_genres.length > _collapsedGenres)
        _chip(
          _genresExpanded ? 'Less' : 'More',
          selected: false,
          onTap: () => setState(() => _genresExpanded = !_genresExpanded),
        ),
    ]);
  }

  Widget _buildScoreSlider(Color accent) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              thumbColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              overlayColor: accent.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _draft.minScore.clamp(0, 10),
              min: 0,
              max: 10,
              divisions: 20,
              label: _draft.minScore <= 0
                  ? 'Any'
                  : '${_draft.minScore.toStringAsFixed(1)}+',
              onChanged: (v) =>
                  _updateDraft(_draft.copyWith(minScore: (v * 2).round() / 2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuntimeChips(Color accent) {
    const options = [
      (min: null, max: null, label: 'Any'),
      (min: null, max: 90, label: 'Under 90 min'),
      (min: 90, max: 120, label: '90-120 min'),
      (min: 120, max: null, label: 'Over 120 min'),
    ];
    return _chipWrap([
      for (final o in options)
        _chip(
          o.label,
          selected: _draft.minRuntime == o.min && _draft.maxRuntime == o.max,
          onTap: () {
            if (o.min == null && o.max == null) {
              _updateDraft(_draft.copyWith(clearRuntime: true));
            } else {
              _updateDraft(
                _draft.copyWith(minRuntime: o.min, maxRuntime: o.max),
              );
            }
          },
        ),
    ]);
  }

  Widget _buildYearRange(Color accent) {
    final fromLabel = _draft.yearFrom == null ? 'From' : '${_draft.yearFrom}';
    final toLabel = _draft.yearTo == null ? 'To' : '${_draft.yearTo}';
    return Row(
      children: [
        Expanded(
          child: _selector(
            label: fromLabel,
            active: _draft.yearFrom != null,
            accent: accent,
            onTap: () async {
              final changed = await _pickAndClearable<int>(
                title: 'From year',
                options: [
                  for (final y in TmdbService.yearOptions)
                    (value: y, label: '$y'),
                ],
                selected: _draft.yearFrom,
                searchable: true,
                onChanged: (v) => _updateDraft(_draft.copyWith(yearFrom: v)),
                onCleared: () =>
                    _updateDraft(_draft.copyWith(clearYears: true)),
              );
              if (changed) setState(() {});
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _selector(
            label: toLabel,
            active: _draft.yearTo != null,
            accent: accent,
            onTap: () async {
              final changed = await _pickAndClearable<int>(
                title: 'To year',
                options: [
                  for (final y in TmdbService.yearOptions)
                    (value: y, label: '$y'),
                ],
                selected: _draft.yearTo,
                searchable: true,
                onChanged: (v) => _updateDraft(_draft.copyWith(yearTo: v)),
                onCleared: () =>
                    _updateDraft(_draft.copyWith(clearYears: true)),
              );
              if (changed) setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderChips(Color accent) {
    if (_providersLoading) return _miniLoader();
    if (_providersFailed || _providers.isEmpty) return _unavailable();

    final visible = _providersExpanded
        ? _providers
        : _providers.take(_collapsedProviders).toList();

    return _chipWrap([
      for (final p in visible)
        _chip(
          p.name,
          selected: _draft.providerIds.contains(p.id),
          onTap: () => _updateDraft(_draft.toggleProvider(p.id)),
        ),
      if (_providers.length > _collapsedProviders)
        _chip(
          _providersExpanded ? 'Less' : 'More',
          selected: false,
          onTap: () => setState(() => _providersExpanded = !_providersExpanded),
        ),
    ]);
  }

  static const List<({String code, String label})> _commonLanguages = [
    (code: 'en', label: 'English'),
    (code: 'es', label: 'Spanish'),
    (code: 'fr', label: 'French'),
    (code: 'de', label: 'German'),
    (code: 'it', label: 'Italian'),
    (code: 'ja', label: 'Japanese'),
    (code: 'ko', label: 'Korean'),
    (code: 'hi', label: 'Hindi'),
    (code: 'zh', label: 'Chinese'),
    (code: 'pt', label: 'Portuguese'),
    (code: 'ru', label: 'Russian'),
    (code: 'ar', label: 'Arabic'),
  ];

  Widget _buildLanguageChips(Color accent) {
    return _chipWrap([
      for (final l in _commonLanguages)
        _chip(
          l.label,
          selected: _draft.language == l.code,
          onTap: () => _updateDraft(
            _draft.language == l.code
                ? _draft.copyWith(clearLanguage: true)
                : _draft.copyWith(language: l.code),
          ),
        ),
      _chip(
        'More',
        selected: false,
        onTap: () async {
          await _ensureLanguages();
          if (!mounted) return;
          if (_languagesFailed || _languages.isEmpty) return;
          final changed = await _pickAndClearable<String>(
            title: 'Language',
            options: [
              for (final l in _languages) (value: l.code, label: l.name),
            ],
            selected: _draft.language,
            searchable: true,
            onChanged: (v) => _updateDraft(_draft.copyWith(language: v)),
            onCleared: () => _updateDraft(_draft.copyWith(clearLanguage: true)),
          );
          if (changed) setState(() {});
        },
      ),
    ]);
  }

  Widget _buildCountrySelector(Color accent) {
    final label = _draft.country == null
        ? 'Any country'
        : _countries
              .firstWhere(
                (c) => c.code == _draft.country,
                orElse: () => (code: _draft.country!, name: _draft.country!),
              )
              .name;

    return _selector(
      label: label,
      active: _draft.country != null,
      accent: accent,
      onTap: () async {
        await _ensureCountries();
        if (!mounted) return;
        if (_countriesFailed || _countries.isEmpty) return;
        final changed = await _pickAndClearable<String>(
          title: 'Country',
          options: [for (final c in _countries) (value: c.code, label: c.name)],
          selected: _draft.country,
          searchable: true,
          onChanged: (v) => _updateDraft(_draft.copyWith(country: v)),
          onCleared: () => _updateDraft(_draft.copyWith(clearCountry: true)),
        );
        if (changed) setState(() {});
      },
    );
  }

  Widget _buildCertificationSection(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _certsExpanded = !_certsExpanded),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Certification',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_draft.certification != null)
                  Text(
                    _draft.certification!,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                Icon(
                  _certsExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
          if (_certsExpanded) ...[
            const SizedBox(height: 12),
            if (_certsLoading)
              _miniLoader()
            else if (_certsFailed || _certifications.isEmpty)
              _unavailable()
            else
              _chipWrap([
                for (final c in _certifications)
                  _chip(
                    c,
                    selected: _draft.certification == c,
                    onTap: () => _updateDraft(
                      _draft.certification == c
                          ? _draft.copyWith(clearCertification: true)
                          : _draft.copyWith(certification: c),
                    ),
                  ),
              ]),
          ],
        ],
      ),
    );
  }

  Widget _selector({
    required String label,
    required bool active,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Action bar ───────────────────────────────────────────────────────────

  Widget _buildActionBar(Color accent) {
    final canApply = _yearRangeValid;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: _draft.isEmpty && !_counting ? null : _resetAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Reset all'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canApply
                      ? () => Navigator.pop(context, _draft)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: accent.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _count != null
                        ? 'Show ${_count!} result${_count == 1 ? '' : 's'}'
                        : 'Show results',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
