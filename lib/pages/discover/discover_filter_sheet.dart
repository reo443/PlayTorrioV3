import 'package:flutter/material.dart';

import '../../models/addon/addon.dart';
import '../../services/addon/addon_manager.dart';

typedef DiscoverCatalogEntry = ({InstalledAddon addon, AddonCatalog catalog});

class DiscoverFilterResult {
  final String type;
  final DiscoverCatalogEntry? catalogEntry;
  final Map<String, String> extras;
  final String? sortKey;
  final bool sortDescending;
  final int? minYear;
  final int? maxYear;
  final double? minRating;

  const DiscoverFilterResult({
    required this.type,
    this.catalogEntry,
    required this.extras,
    this.sortKey,
    this.sortDescending = true,
    this.minYear,
    this.maxYear,
    this.minRating,
  });
}

Future<void> showDiscoverFilterSheet({
  required BuildContext context,
  required List<String> availableTypes,
  required String selectedType,
  required List<DiscoverCatalogEntry> catalogs,
  required DiscoverCatalogEntry selectedCatalogEntry,
  required Map<String, String> selectedExtras,
  String? sortKey,
  bool sortDescending = true,
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
      availableTypes: availableTypes,
      selectedType: selectedType,
      catalogs: catalogs,
      selectedCatalogEntry: selectedCatalogEntry,
      selectedExtras: selectedExtras,
      sortKey: sortKey,
      sortDescending: sortDescending,
      minYear: minYear,
      maxYear: maxYear,
      minRating: minRating,
      onApply: onApply,
    ),
  );
}

class _DiscoverFilterSheet extends StatefulWidget {
  final List<String> availableTypes;
  final String selectedType;
  final List<DiscoverCatalogEntry> catalogs;
  final DiscoverCatalogEntry selectedCatalogEntry;
  final Map<String, String> selectedExtras;
  final String? sortKey;
  final bool sortDescending;
  final int? minYear;
  final int? maxYear;
  final double? minRating;
  final void Function(DiscoverFilterResult result) onApply;

  const _DiscoverFilterSheet({
    required this.availableTypes,
    required this.selectedType,
    required this.catalogs,
    required this.selectedCatalogEntry,
    required this.selectedExtras,
    this.sortKey,
    this.sortDescending = true,
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

  static const _sortOptions = {
    'trending': 'Trending',
    'popularity': 'Popularity',
    'score': 'Score',
    'date': 'Date',
  };

  late String _type;
  DiscoverCatalogEntry? _entry;
  late final Map<String, String> _extras;
  String? _sortKey;
  late bool _sortDescending;
  int? _minYear;
  int? _maxYear;
  double? _minRating;
  final Map<String, TextEditingController> _textControllers = {};

  List<CatalogExtra> get _visibleExtras => _entry?.catalog.extra
          .where((e) => e.name != 'skip' && (e.name != 'search' || e.isRequired))
          .toList() ??
      const <CatalogExtra>[];

  List<DiscoverCatalogEntry> get _catalogsForType =>
      widget.catalogs.where((c) => c.catalog.type == _type).toList();

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
    _entry = widget.selectedCatalogEntry;
    _extras = Map<String, String>.from(widget.selectedExtras);
    _sortKey = widget.sortKey;
    _sortDescending = widget.sortDescending;
    _minYear = widget.minYear;
    _maxYear = widget.maxYear;
    _minRating = widget.minRating;
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
    if (_sortKey != null) count++;
    if (_minYear != null || _maxYear != null) count++;
    if (_minRating != null) count++;
    return count;
  }

  void _onTypeSelected(String type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _entry = _catalogsForType.firstOrNull;
      _extras.clear();
      _resetTextControllers();
    });
  }

  void _onCatalogSelected(DiscoverCatalogEntry entry) {
    if (entry == _entry) return;
    setState(() {
      _entry = entry;
      _extras.clear();
      _resetTextControllers();
    });
  }

  void _resetTextControllers() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _textControllers.clear();
  }

  TextEditingController _controllerFor(String extraName) {
    return _textControllers.putIfAbsent(
      extraName,
      () => TextEditingController(text: _extras[extraName] ?? ''),
    );
  }

  void _clearAll() {
    setState(() {
      _extras.clear();
      _sortKey = null;
      _sortDescending = true;
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
        type: _type,
        catalogEntry: _entry,
        extras: Map<String, String>.from(_extras),
        sortKey: _sortKey,
        sortDescending: _sortDescending,
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
                      _buildCatalogSection(),
                      _buildSortSection(),
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
            children: widget.availableTypes.map((t) {
              final isSelected = t == _type;
              return _buildChoiceChip(
                label: t[0].toUpperCase() + t.substring(1),
                selected: isSelected,
                onSelected: () => _onTypeSelected(t),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogSection() {
    final catalogs = _catalogsForType;
    if (catalogs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('SOURCE / CATALOG'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: catalogs.map((entry) {
              final isSelected = entry == _entry;
              final hasReq = entry.catalog.hasRequiredExtra;
              return _buildChoiceChip(
                label: AddonManager.instance.catalogDisplayName(entry.catalog),
                selected: isSelected,
                onSelected: () => _onCatalogSelected(entry),
                trailingBadge: hasReq ? 'Custom' : null,
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
            children: [
              _buildChoiceChip(
                label: 'Default',
                selected: _sortKey == null,
                onSelected: () => setState(() => _sortKey = null),
              ),
              ..._sortOptions.entries.map(
                (opt) => _buildChoiceChip(
                  label: opt.value,
                  selected: _sortKey == opt.key,
                  onSelected: () => setState(() => _sortKey = opt.key),
                ),
              ),
            ],
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
              controller: _controllerFor(extra.name),
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
    String? trailingBadge,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (trailingBadge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white24 : Colors.amber.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trailingBadge,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : Colors.amber,
                ),
              ),
            ),
          ],
        ],
      ),
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
