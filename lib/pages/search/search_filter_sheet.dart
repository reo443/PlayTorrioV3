import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full client-side filter state for search results.
class SearchFilterState {
  final String type; // 'all' | 'movie' | 'series'
  final String? sortKey; // null | 'popularity' | 'score' | 'year' | 'title'
  final bool sortDescending;
  final List<String> genres;
  final int? minYear;
  final int? maxYear;
  final double? minRating;
  final double? maxRating;
  final int? minDuration;
  final int? maxDuration;

  const SearchFilterState({
    this.type = 'all',
    this.sortKey,
    this.sortDescending = true,
    this.genres = const [],
    this.minYear,
    this.maxYear,
    this.minRating,
    this.maxRating,
    this.minDuration,
    this.maxDuration,
  });

  static const sortOptions = <String, String>{
    'popularity': 'Popularity',
    'score': 'Score',
    'year': 'Year',
    'title': 'Title',
  };

  bool get isDefault =>
      type == 'all' &&
      sortKey == null &&
      sortDescending &&
      genres.isEmpty &&
      minYear == null &&
      maxYear == null &&
      minRating == null &&
      maxRating == null &&
      minDuration == null &&
      maxDuration == null;

  int get activeCount {
    var count = 0;
    if (type != 'all') count++;
    if (sortKey != null) count++;
    if (genres.isNotEmpty) count++;
    if (minYear != null || maxYear != null) count++;
    if (minRating != null || maxRating != null) count++;
    if (minDuration != null || maxDuration != null) count++;
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (other is! SearchFilterState) return false;
    bool listEq(List<String> a, List<String> b) =>
        a.length == b.length && a.every(b.contains);
    return type == other.type &&
        sortKey == other.sortKey &&
        sortDescending == other.sortDescending &&
        listEq(genres, other.genres) &&
        minYear == other.minYear &&
        maxYear == other.maxYear &&
        minRating == other.minRating &&
        maxRating == other.maxRating &&
        minDuration == other.minDuration &&
        maxDuration == other.maxDuration;
  }

  @override
  int get hashCode => Object.hash(
      type, sortKey, sortDescending, Object.hashAll(genres), minYear, maxYear,
      minRating, maxRating, minDuration, maxDuration);
}

Future<void> showSearchFilterSheet({
  required BuildContext context,
  required SearchFilterState current,
  required List<String> availableGenres,
  required void Function(SearchFilterState result) onApply,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 620),
    builder: (ctx) => _SearchFilterSheet(
      current: current,
      availableGenres: availableGenres,
      onApply: onApply,
    ),
  );
}

class _SearchFilterSheet extends StatefulWidget {
  final SearchFilterState current;
  final List<String> availableGenres;
  final void Function(SearchFilterState result) onApply;

  const _SearchFilterSheet({
    required this.current,
    required this.availableGenres,
    required this.onApply,
  });

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  static const _accent = Color(0xFF7C5CFF);

  late String _type;
  String? _sortKey;
  late bool _sortDescending;
  late final List<String> _selectedGenres;

  late final TextEditingController _yearFromCtrl;
  late final TextEditingController _yearToCtrl;
  late final TextEditingController _ratingMinCtrl;
  late final TextEditingController _ratingMaxCtrl;
  late final TextEditingController _durationMinCtrl;
  late final TextEditingController _durationMaxCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.current;
    _type = f.type;
    _sortKey = f.sortKey;
    _sortDescending = f.sortDescending;
    _selectedGenres = List<String>.from(f.genres);

    String fmtDouble(double? v) =>
        v == null ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toString());

    _yearFromCtrl = TextEditingController(text: f.minYear?.toString() ?? '');
    _yearToCtrl = TextEditingController(text: f.maxYear?.toString() ?? '');
    _ratingMinCtrl = TextEditingController(text: fmtDouble(f.minRating));
    _ratingMaxCtrl = TextEditingController(text: fmtDouble(f.maxRating));
    _durationMinCtrl = TextEditingController(text: f.minDuration?.toString() ?? '');
    _durationMaxCtrl = TextEditingController(text: f.maxDuration?.toString() ?? '');
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
    if (_type != 'all') count++;
    if (_sortKey != null) count++;
    if (_selectedGenres.isNotEmpty) count++;
    if (_yearFromCtrl.text.trim().isNotEmpty || _yearToCtrl.text.trim().isNotEmpty) count++;
    if (_ratingMinCtrl.text.trim().isNotEmpty || _ratingMaxCtrl.text.trim().isNotEmpty) count++;
    if (_durationMinCtrl.text.trim().isNotEmpty || _durationMaxCtrl.text.trim().isNotEmpty) count++;
    return count;
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
      _type = 'all';
      _sortKey = null;
      _sortDescending = true;
      _selectedGenres.clear();
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
    widget.onApply(SearchFilterState(
      type: _type,
      sortKey: _sortKey,
      sortDescending: _sortDescending,
      genres: List<String>.from(_selectedGenres),
      minYear: minYear,
      maxYear: maxYear,
      minRating: minRating,
      maxRating: maxRating,
      minDuration: minDuration,
      maxDuration: maxDuration,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardInset = mq.viewInsets.bottom;
    final maxHeight =
        (mq.size.height * 0.82).clamp(0.0, mq.size.height - keyboardInset - 16);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ClipRRect(
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
                        const Expanded(
                          child: Text(
                            'Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
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
                        _buildGenresSection(),
                        _buildSortSection(),
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
    const options = {'all': 'All Types', 'movie': 'Movies', 'series': 'Series'};
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
            children: options.entries.map((e) {
              return _buildChoiceChip(
                label: e.value,
                selected: _type == e.key,
                onSelected: () => setState(() => _type = e.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenresSection() {
    if (widget.availableGenres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSectionHeader('GENRES')),
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
              ...widget.availableGenres.map(
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
            children: SearchFilterState.sortOptions.entries.map((opt) {
              return _buildChoiceChip(
                label: opt.value,
                selected: _sortKey == opt.key,
                onSelected: () => setState(() {
                  if (_sortKey == opt.key) {
                    _sortKey = null; // tap selected chip again to clear
                  } else {
                    _sortKey = opt.key;
                    _sortDescending = opt.key != 'title';
                  }
                }),
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

  Widget _buildReleaseDateSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('RELEASE DATE'),
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
