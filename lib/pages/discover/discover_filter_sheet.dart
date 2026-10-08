import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/addon/addon.dart';

typedef DiscoverCatalogEntry = ({InstalledAddon addon, AddonCatalog catalog});

class DiscoverFilterResult {
  final String type;
  final DiscoverCatalogEntry? catalogEntry;
  final List<String> genres;
  final String? sortKey; // null | 'title' | 'trending' | 'popularity' | 'score'
  final bool sortDescending;
  final int? minYear;
  final int? maxYear;
  final double? minRating;
  final double? maxRating;
  final int? minDuration;
  final int? maxDuration;

  const DiscoverFilterResult({
    required this.type,
    this.catalogEntry,
    required this.genres,
    this.sortKey,
    this.sortDescending = true,
    this.minYear,
    this.maxYear,
    this.minRating,
    this.maxRating,
    this.minDuration,
    this.maxDuration,
  });
}

Future<void> showDiscoverFilterSheet({
  required BuildContext context,
  required String selectedType,
  required List<DiscoverCatalogEntry> catalogs,
  required DiscoverCatalogEntry selectedCatalogEntry,
  required List<String> selectedGenres,
  String? sortKey,
  bool sortDescending = true,
  int? minYear,
  int? maxYear,
  double? minRating,
  double? maxRating,
  int? minDuration,
  int? maxDuration,
  required void Function(DiscoverFilterResult result) onApply,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 620),
    builder: (ctx) => _DiscoverFilterSheet(
      selectedType: selectedType,
      catalogs: catalogs,
      selectedCatalogEntry: selectedCatalogEntry,
      selectedGenres: selectedGenres,
      sortKey: sortKey,
      sortDescending: sortDescending,
      minYear: minYear,
      maxYear: maxYear,
      minRating: minRating,
      maxRating: maxRating,
      minDuration: minDuration,
      maxDuration: maxDuration,
      onApply: onApply,
    ),
  );
}

class _DiscoverFilterSheet extends StatefulWidget {
  final String selectedType;
  final List<DiscoverCatalogEntry> catalogs;
  final DiscoverCatalogEntry selectedCatalogEntry;
  final List<String> selectedGenres;
  final String? sortKey;
  final bool sortDescending;
  final int? minYear;
  final int? maxYear;
  final double? minRating;
  final double? maxRating;
  final int? minDuration;
  final int? maxDuration;
  final void Function(DiscoverFilterResult result) onApply;

  const _DiscoverFilterSheet({
    required this.selectedType,
    required this.catalogs,
    required this.selectedCatalogEntry,
    required this.selectedGenres,
    this.sortKey,
    this.sortDescending = true,
    this.minYear,
    this.maxYear,
    this.minRating,
    this.maxRating,
    this.minDuration,
    this.maxDuration,
    required this.onApply,
  });

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  static const _accent = Color(0xFF7C5CFF);

  static const _sortOptions = {
    'title': 'Title',
    'trending': 'Trending',
    'popularity': 'Popularity',
    'score': 'Score',
  };

  static const _typeOptions = {'movie': 'Movie', 'series': 'Series'};

  late String _type;
  DiscoverCatalogEntry? _entry;
  late final List<String> _selectedGenres;
  String? _sortKey;
  late bool _sortDescending;

  late final TextEditingController _yearFromCtrl;
  late final TextEditingController _yearToCtrl;
  late final TextEditingController _ratingMinCtrl;
  late final TextEditingController _ratingMaxCtrl;
  late final TextEditingController _durationMinCtrl;
  late final TextEditingController _durationMaxCtrl;

  List<DiscoverCatalogEntry> get _catalogsForType =>
      widget.catalogs.where((c) => c.catalog.type == _type).toList();

  /// Cinemeta's "New" (year) catalog names its year options "genre" —
  /// detect 4-digit year values so they don't pollute the genre list.
  static bool _yearLike(String s) => RegExp(r'^(19|20)\d{2}$').hasMatch(s.trim());

  bool _catalogSupportsGenres(DiscoverCatalogEntry entry) {
    if (entry.catalog.getExtra('genre') == null) return false;
    final options = entry.catalog.genres;
    final nonYear = options.where((g) => !_yearLike(g)).length;
    return nonYear * 2 >= options.length;
  }

  List<String> get _allGenres {
    final seen = <String>{};
    final list = <String>[];
    for (final entry in _catalogsForType) {
      for (final g in entry.catalog.genres) {
        final trimmed = g.trim();
        if (trimmed.isNotEmpty && !_yearLike(trimmed) && seen.add(trimmed)) {
          list.add(trimmed);
        }
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
    _entry = widget.selectedCatalogEntry;
    _selectedGenres = List<String>.from(widget.selectedGenres);
    _sortKey = widget.sortKey;
    _sortDescending = widget.sortDescending;

    _yearFromCtrl = TextEditingController(text: widget.minYear?.toString() ?? '');
    _yearToCtrl = TextEditingController(text: widget.maxYear?.toString() ?? '');
    _ratingMinCtrl = TextEditingController(text: _fmtDouble(widget.minRating));
    _ratingMaxCtrl = TextEditingController(text: _fmtDouble(widget.maxRating));
    _durationMinCtrl = TextEditingController(text: widget.minDuration?.toString() ?? '');
    _durationMaxCtrl = TextEditingController(text: widget.maxDuration?.toString() ?? '');
  }

  @override
  void dispose() {
    _yearFromCtrl.dispose();
    _yearToCtrl.dispose();
    _ratingMinCtrl.dispose();
    _ratingMaxCtrl.dispose();
    _durationMinCtrl.dispose();
    _durationMaxCtrl.dispose();
    super.dispose();
  }

  static String _fmtDouble(double? v) {
    if (v == null) return '';
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toString();
  }

  static int? _parseInt(String s) {
    final v = int.tryParse(s.trim());
    return (v != null && v > 0) ? v : null;
  }

  static double? _parseDouble(String s) {
    final v = double.tryParse(s.trim());
    return (v != null && v > 0) ? v : null;
  }

  int get _activeCount {
    var count = 0;
    if (_selectedGenres.isNotEmpty) count++;
    if (_sortKey != null) count++;
    if (_yearFromCtrl.text.trim().isNotEmpty || _yearToCtrl.text.trim().isNotEmpty) count++;
    if (_ratingMinCtrl.text.trim().isNotEmpty || _ratingMaxCtrl.text.trim().isNotEmpty) count++;
    if (_durationMinCtrl.text.trim().isNotEmpty || _durationMaxCtrl.text.trim().isNotEmpty) count++;
    return count;
  }

  void _onTypeSelected(String type) {
    if (type == _type) return;

    final catalogs = widget.catalogs.where((c) => c.catalog.type == type).toList();
    final prev = _entry;

    // Keep the layout consistent when switching type: prefer the same
    // addon + catalog id, then the same addon, then a catalog that has
    // selectable extras, before falling back to the first catalog.
    DiscoverCatalogEntry? match;
    if (prev != null) {
      for (final c in catalogs) {
        if (c.addon.manifest.id == prev.addon.manifest.id &&
            c.catalog.id == prev.catalog.id) {
          match = c;
          break;
        }
      }
    }
    if (match == null && prev != null) {
      for (final c in catalogs) {
        if (c.addon.manifest.id == prev.addon.manifest.id) {
          match = c;
          break;
        }
      }
    }
    match ??= catalogs
            .where((c) => c.catalog.selectableExtras.isNotEmpty)
            .firstOrNull ??
        catalogs.firstOrNull;

    setState(() {
      _type = type;
      _entry = match;
      _selectedGenres.clear();
    });
  }

  void _onSortSelected(String key) {
    setState(() {
      if (_sortKey == key) {
        _sortKey = null;
      } else {
        _sortKey = key;
        _sortDescending = key != 'title';
      }
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedGenres.clear();
      _sortKey = null;
      _sortDescending = true;
      _yearFromCtrl.clear();
      _yearToCtrl.clear();
      _ratingMinCtrl.clear();
      _ratingMaxCtrl.clear();
      _durationMinCtrl.clear();
      _durationMaxCtrl.clear();
    });
  }

  void _apply() {
    var minYear = _parseInt(_yearFromCtrl.text);
    var maxYear = _parseInt(_yearToCtrl.text);
    if (minYear != null && maxYear != null && minYear > maxYear) {
      final t = minYear;
      minYear = maxYear;
      maxYear = t;
    }

    var minRating = _parseDouble(_ratingMinCtrl.text);
    var maxRating = _parseDouble(_ratingMaxCtrl.text);
    if (minRating != null && maxRating != null && minRating > maxRating) {
      final t = minRating;
      minRating = maxRating;
      maxRating = t;
    }

    var minDuration = _parseInt(_durationMinCtrl.text);
    var maxDuration = _parseInt(_durationMaxCtrl.text);
    if (minDuration != null && maxDuration != null && minDuration > maxDuration) {
      final t = minDuration;
      minDuration = maxDuration;
      maxDuration = t;
    }

    Navigator.of(context).pop();
    widget.onApply(
      DiscoverFilterResult(
        type: _type,
        catalogEntry: _entry,
        genres: (_entry != null && _catalogSupportsGenres(_entry!))
            ? List<String>.from(_selectedGenres)
            : const <String>[],
        sortKey: _sortKey,
        sortDescending: _sortDescending,
        minYear: minYear,
        maxYear: maxYear,
        minRating: minRating,
        maxRating: maxRating,
        minDuration: minDuration,
        maxDuration: maxDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;
    final genres = _allGenres;
    final genreSupported = _entry != null && _catalogSupportsGenres(_entry!);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: const Color(0xFF12151E),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: _accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filters',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _entry?.catalog.name ?? 'Catalog',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 20),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    physics: const ClampingScrollPhysics(),
                    children: [
                      _buildTypeSection(),
                      _buildSortSection(),
                      if (genres.isNotEmpty && genreSupported)
                        _buildGenreSection(genres),
                      _buildReleaseDateSection(),
                      _buildRatingSection(),
                      _buildDurationSection(),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearAll,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _apply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            _activeCount > 0 ? 'Apply ($_activeCount Active)' : 'Apply',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.35),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTypeSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('CONTENT TYPE'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _typeOptions.entries.map((t) {
              final isSelected = t.key == _type;
              return _buildChoiceChip(
                label: t.value,
                selected: isSelected,
                onSelected: () => _onTypeSelected(t.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSectionHeader('SORT BY')),
              _buildOrderToggle(),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.entries.map((opt) {
              return _buildChoiceChip(
                label: opt.value,
                selected: _sortKey == opt.key,
                onSelected: () => _onSortSelected(opt.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderToggle() {
    final enabled = _sortKey != null;
    final desc = _sortDescending;

    return Tooltip(
      message: desc ? 'High to Low (Descending)' : 'Low to High (Ascending)',
      child: InkWell(
        onTap: enabled
            ? () => setState(() => _sortDescending = !_sortDescending)
            : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: enabled ? _accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? _accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                desc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 14,
                color: enabled ? const Color(0xFF9D85FF) : Colors.white30,
              ),
              const SizedBox(width: 4),
              Text(
                desc ? 'DSC' : 'ASC',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: enabled ? const Color(0xFF9D85FF) : Colors.white30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreSection(List<String> genres) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSectionHeader('GENRE')),
              if (_selectedGenres.isNotEmpty)
                Text(
                  '${_selectedGenres.length} selected',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                label: 'All',
                selected: _selectedGenres.isEmpty,
                onSelected: () => setState(() => _selectedGenres.clear()),
              ),
              ...genres.map(
                (g) => _buildChoiceChip(
                  label: g,
                  selected: _selectedGenres.contains(g),
                  onSelected: () => _toggleGenre(g),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseDateSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('RELEASE DATE'),
          const SizedBox(height: 4),
          const Text(
            'Filters loaded titles by release year',
            style: TextStyle(fontSize: 11.5, color: Colors.white54),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _yearFromCtrl,
                  label: 'From (year)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  controller: _yearToCtrl,
                  label: 'To (year)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('RATING (IMDB)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _ratingMinCtrl,
                  label: 'Min',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d{0,1})?$')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  controller: _ratingMaxCtrl,
                  label: 'Max',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d{0,1})?$')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('DURATION (MINUTES)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _durationMinCtrl,
                  label: 'Min',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  controller: _durationMaxCtrl,
                  label: 'Max',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0D1017),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: _accent.withValues(alpha: 0.25),
      backgroundColor: const Color(0xFF0D1017),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF9D85FF) : Colors.white70,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected
            ? _accent.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.08),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
