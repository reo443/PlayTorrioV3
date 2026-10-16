import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late DiscoverFilterState _draft = widget.initial;

  late final TextEditingController _yearFromController;
  late final TextEditingController _yearToController;

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

  bool _certsExpanded = false;

  // Live result count.
  int? _count;
  bool _counting = false;
  Timer? _countDebounce;

  static int get _maxYear => DateTime.now().year + 10;

  @override
  void initState() {
    super.initState();
    _yearFromController = TextEditingController(
      text: widget.initial.yearFrom?.toString() ?? '',
    );
    _yearToController = TextEditingController(
      text: widget.initial.yearTo?.toString() ?? '',
    );
    _loadCoreOptions();
    _scheduleCount();
  }

  @override
  void dispose() {
    _countDebounce?.cancel();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  /// Parses a 4-digit year within `1900.._maxYear`, else null.
  int? _parseYear(String text) {
    final trimmed = text.trim();
    if (trimmed.length != 4) return null;
    final year = int.tryParse(trimmed);
    if (year == null || year < 1900 || year > _maxYear) return null;
    return year;
  }

  bool _yearFieldInvalid(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isNotEmpty && _parseYear(text) == null;
  }

  /// Whether both year inputs are valid and ordered.
  bool get _yearsOk {
    if (_yearFieldInvalid(_yearFromController)) return false;
    if (_yearFieldInvalid(_yearToController)) return false;
    final from = _parseYear(_yearFromController.text);
    final to = _parseYear(_yearToController.text);
    if (from != null && to != null && from > to) return false;
    return true;
  }

  void _onYearChanged({required bool isFrom}) {
    final controller = isFrom ? _yearFromController : _yearToController;
    final raw = controller.text.trim();
    setState(() {
      if (raw.isEmpty) {
        _draft = isFrom
            ? _draft.copyWith(clearYearFrom: true)
            : _draft.copyWith(clearYearTo: true);
      } else {
        final year = _parseYear(raw);
        if (year != null) {
          _draft = isFrom
              ? _draft.copyWith(yearFrom: year)
              : _draft.copyWith(yearTo: year);
        }
      }
    });
    if (raw.isEmpty || _parseYear(raw) != null) _scheduleCount();
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
      // Restrict to the curated set of top streaming services, in order.
      final byId = {for (final p in providers) p.id: p};
      final curated = [
        for (final id in TmdbService.curatedWatchProviderIds)
          if (byId[id] != null) byId[id]!,
      ];
      setState(() {
        _providers = curated;
        _providersLoading = false;
        _providersFailed = curated.isEmpty;
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
    if (!_yearsOk) {
      setState(() {
        _counting = false;
        _count = null;
      });
      return;
    }
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
    _yearFromController.clear();
    _yearToController.clear();
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
                      child: _buildLanguageSelector(accent),
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

    return _chipWrap([
      for (final g in _genres)
        _chip(
          g.name,
          selected: _draft.genreIds.contains(g.id),
          onTap: () => _updateDraft(_draft.toggleGenre(g.id)),
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
    final from = _parseYear(_yearFromController.text);
    final to = _parseYear(_yearToController.text);
    final rangeError = (from != null && to != null && from > to)
        ? 'Start year is after end year'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _yearField(
                controller: _yearFromController,
                hint: 'From',
                accent: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _yearField(
                controller: _yearToController,
                hint: 'To',
                accent: accent,
              ),
            ),
          ],
        ),
        if (rangeError != null) ...[
          const SizedBox(height: 8),
          Text(
            rangeError,
            style: TextStyle(
              color: Colors.redAccent.withValues(alpha: 0.9),
              fontSize: 11.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _yearField({
    required TextEditingController controller,
    required String hint,
    required Color accent,
  }) {
    final invalid = _yearFieldInvalid(controller);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: invalid
                ? Colors.redAccent.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent),
        ),
      ),
      onChanged: (_) =>
          _onYearChanged(isFrom: controller == _yearFromController),
    );
  }

  Widget _buildProviderChips(Color accent) {
    if (_providersLoading) return _miniLoader();
    if (_providersFailed || _providers.isEmpty) return _unavailable();

    return _chipWrap([
      for (final p in _providers)
        _chip(
          p.name,
          selected: _draft.providerIds.contains(p.id),
          onTap: () => _updateDraft(_draft.toggleProvider(p.id)),
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

  Widget _buildLanguageSelector(Color accent) {
    final code = _draft.language;
    var label = 'Any language';
    if (code != null) {
      label = code;
      for (final l in _languages) {
        if (l.code == code) {
          label = l.name;
          break;
        }
      }
      if (label == code) {
        for (final l in _commonLanguages) {
          if (l.code == code) {
            label = l.label;
            break;
          }
        }
      }
    }

    return _selector(
      label: label,
      active: _draft.language != null,
      accent: accent,
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
    );
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
    final canApply = _yearsOk;
    final hasInput = !_draft.isEmpty ||
        _yearFromController.text.trim().isNotEmpty ||
        _yearToController.text.trim().isNotEmpty;
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
                onPressed: hasInput ? _resetAll : null,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_counting && _count == null) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _count != null
                            ? 'Show ${_count!} result${_count == 1 ? '' : 's'}'
                            : 'Show results',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
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
