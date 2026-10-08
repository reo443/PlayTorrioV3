import 'package:flutter/material.dart';

import '../../models/addon/addon.dart';

class DiscoverFilterResult {
  final Map<String, String> extras;
  final int? minYear;
  final int? maxYear;
  final double? minRating;

  const DiscoverFilterResult({
    required this.extras,
    this.minYear,
    this.maxYear,
    this.minRating,
  });
}

Future<void> showDiscoverFilterSheet({
  required BuildContext context,
  required AddonCatalog catalog,
  required Map<String, String> selectedExtras,
  int? minYear,
  int? maxYear,
  double? minRating,
  required void Function(DiscoverFilterResult result) onApply,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 620),
    builder: (ctx) => _DiscoverFilterSheet(
      catalog: catalog,
      selectedExtras: selectedExtras,
      minYear: minYear,
      maxYear: maxYear,
      minRating: minRating,
      onApply: onApply,
    ),
  );
}

class _DiscoverFilterSheet extends StatefulWidget {
  final AddonCatalog catalog;
  final Map<String, String> selectedExtras;
  final int? minYear;
  final int? maxYear;
  final double? minRating;
  final void Function(DiscoverFilterResult result) onApply;

  const _DiscoverFilterSheet({
    required this.catalog,
    required this.selectedExtras,
    this.minYear,
    this.maxYear,
    this.minRating,
    required this.onApply,
  });

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  static const _accent = Color(0xFF7C5CFF);

  late final Map<String, String> _extras;
  late int? _minYear;
  late int? _maxYear;
  late double? _minRating;
  final Map<String, TextEditingController> _textControllers = {};

  List<CatalogExtra> get _visibleExtras => widget.catalog.extra
      .where((e) => e.name != 'skip' && (e.name != 'search' || e.isRequired))
      .toList();

  @override
  void initState() {
    super.initState();
    _extras = Map<String, String>.from(widget.selectedExtras);
    _minYear = widget.minYear;
    _maxYear = widget.maxYear;
    _minRating = widget.minRating;
    for (final extra in _visibleExtras) {
      if (extra.options.isEmpty) {
        _textControllers[extra.name] =
            TextEditingController(text: _extras[extra.name] ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _activeCount {
    var count = _extras.length;
    if (_minYear != null || _maxYear != null) count++;
    if (_minRating != null) count++;
    return count;
  }

  void _clearAll() {
    setState(() {
      _extras.clear();
      _minYear = null;
      _maxYear = null;
      _minRating = null;
      for (final c in _textControllers.values) {
        c.clear();
      }
    });
  }

  void _apply() {
    for (final entry in _textControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) {
        _extras.remove(entry.key);
      } else {
        _extras[entry.key] = text;
      }
    }
    Navigator.of(context).pop();
    widget.onApply(
      DiscoverFilterResult(
        extras: Map<String, String>.from(_extras),
        minYear: _minYear,
        maxYear: _maxYear,
        minRating: _minRating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

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
                              widget.catalog.name ?? 'Catalog',
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
                      if (_visibleExtras.isNotEmpty) ...[
                        _buildSectionHeader('CATALOG FILTERS'),
                        const SizedBox(height: 12),
                        ..._visibleExtras.map(_buildExtraSection),
                      ],
                      _buildSectionHeader('TITLE FILTERS'),
                      const SizedBox(height: 4),
                      const Text(
                        'Applied locally to loaded titles — more results stream in automatically as you scroll',
                        style: TextStyle(fontSize: 11.5, color: Colors.white54),
                      ),
                      const SizedBox(height: 14),
                      _buildYearSection(),
                      _buildRatingSection(),
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

  Widget _buildExtraSection(CatalogExtra extra) {
    final current = _extras[extra.name];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                extra.name[0].toUpperCase() + extra.name.substring(1),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: extra.isRequired
                      ? Colors.amber.withValues(alpha: 0.2)
                      : _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  extra.isRequired ? 'REQUIRED' : 'OPTIONAL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: extra.isRequired ? Colors.amber : const Color(0xFF9D85FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (extra.options.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!extra.isRequired)
                  _buildChoiceChip(
                    label: 'All',
                    selected: current == null,
                    onSelected: () => setState(() => _extras.remove(extra.name)),
                  ),
                ...extra.options.map(
                  (opt) => _buildChoiceChip(
                    label: opt,
                    selected: current == opt,
                    onSelected: () => setState(() => _extras[extra.name] = opt),
                  ),
                ),
              ],
            )
          else
            TextField(
              controller: _textControllers[extra.name],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter ${extra.name}...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0D1017),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            ),
        ],
      ),
    );
  }

  Widget _buildYearSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Release Year',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildYearDropdown('From', _minYear, (v) => setState(() => _minYear = v)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildYearDropdown('To', _maxYear, (v) => setState(() => _maxYear = v)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown(String label, int? value, ValueChanged<int?> onChanged) {
    final currentYear = DateTime.now().year;

    return DropdownButtonFormField<int?>(
      value: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF151822),
      menuMaxHeight: 360,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0D1017),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Any')),
        ...List.generate(currentYear + 2 - 1950, (i) {
          final y = currentYear + 1 - i;
          return DropdownMenuItem<int?>(value: y, child: Text('$y'));
        }),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildRatingSection() {
    const ratings = [5.0, 6.0, 7.0, 8.0, 9.0];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Minimum Rating',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                label: 'Any',
                selected: _minRating == null,
                onSelected: () => setState(() => _minRating = null),
              ),
              ...ratings.map(
                (r) => _buildChoiceChip(
                  label: '${r.toStringAsFixed(0)}+',
                  selected: _minRating == r,
                  onSelected: () => setState(() => _minRating = r),
                ),
              ),
            ],
          ),
        ],
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
