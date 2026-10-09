import 'package:flutter/material.dart';

import '../../models/manga/manga_browse_filter.dart';
import '../../services/manga/manga_service.dart';

Future<void> showMangaFilterSheet({
  required BuildContext context,
  required MangaBrowseFilter current,
  required void Function(MangaBrowseFilter result) onApply,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 620),
    builder: (ctx) => _MangaFilterSheet(
      current: current,
      onApply: onApply,
    ),
  );
}

class _MangaFilterSheet extends StatefulWidget {
  final MangaBrowseFilter current;
  final void Function(MangaBrowseFilter result) onApply;

  const _MangaFilterSheet({
    required this.current,
    required this.onApply,
  });

  @override
  State<_MangaFilterSheet> createState() => _MangaFilterSheetState();
}

class _MangaFilterSheetState extends State<_MangaFilterSheet> {
  static const _accent = Color(0xFF7C5CFF);

  late String _sort;
  late bool _descending;
  late List<String> _types;
  late List<String> _statuses;
  late List<String> _includedTags;
  late List<String> _excludedTags;
  late String _official;
  late String _adult;
  bool _excludeMode = false;

  @override
  void initState() {
    super.initState();
    final f = widget.current;
    _sort = f.sort;
    _descending = f.descending;
    _types = List<String>.from(f.types);
    _statuses = List<String>.from(f.statuses);
    _includedTags = List<String>.from(f.includedTags);
    _excludedTags = List<String>.from(f.excludedTags);
    _official = f.official;
    _adult = f.adult;
  }

  MangaBrowseFilter get _result => MangaBrowseFilter(
        sort: _sort,
        descending: _descending,
        types: List<String>.from(_types),
        statuses: List<String>.from(_statuses),
        includedTags: List<String>.from(_includedTags),
        excludedTags: List<String>.from(_excludedTags),
        official: _official,
        adult: _adult,
      );

  int get _activeCount => _result.activeCount;

  void _toggleInList(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_excludeMode) {
        _includedTags.remove(tag);
        _toggleInList(_excludedTags, tag);
      } else {
        _excludedTags.remove(tag);
        _toggleInList(_includedTags, tag);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _sort = 'Popularity';
      _descending = true;
      _types.clear();
      _statuses.clear();
      _includedTags.clear();
      _excludedTags.clear();
      _official = 'Any';
      _adult = 'False';
    });
  }

  void _apply() {
    Navigator.of(context).pop();
    widget.onApply(_result);
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
                        _buildSortSection(),
                        _buildTypeSection(),
                        _buildStatusSection(),
                        _buildTagsSection(),
                        _buildOfficialSection(),
                        _buildAdultSection(),
                      ],
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
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
            children: MangaBrowseFilter.sortOptions.map((s) {
              return _buildChoiceChip(
                label: s,
                selected: _sort == s,
                onSelected: () => setState(() => _sort = s),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderToggle() {
    final desc = _descending;
    return Tooltip(
      message: desc ? 'High to Low (Descending)' : 'Low to High (Ascending)',
      child: InkWell(
        onTap: () => setState(() => _descending = !_descending),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                desc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 14,
                color: const Color(0xFF9D85FF),
              ),
              const SizedBox(width: 4),
              Text(
                desc ? 'DSC' : 'ASC',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9D85FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('TYPE'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MangaBrowseFilter.typeOptions.map((t) {
              return _buildChoiceChip(
                label: t,
                selected: _types.contains(t),
                onSelected: () => _toggleInList(_types, t),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('STATUS'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MangaBrowseFilter.statusOptions.map((s) {
              return _buildChoiceChip(
                label: s,
                selected: _statuses.contains(s),
                onSelected: () => _toggleInList(_statuses, s),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    final incCount = _includedTags.length;
    final excCount = _excludedTags.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('GENRES'),
                    if (incCount > 0 || excCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          [
                            if (incCount > 0) '$incCount included',
                            if (excCount > 0) '$excCount excluded',
                          ].join(' • '),
                          style: const TextStyle(fontSize: 9.5, color: Colors.white54),
                        ),
                      ),
                  ],
                ),
              ),
              _buildIncludeExcludeToggle(),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MangaService.availableTags.map((tag) {
              final included = _includedTags.contains(tag);
              final excluded = _excludedTags.contains(tag);
              return _buildChoiceChip(
                label: tag,
                selected: included || excluded,
                exclude: excluded,
                onSelected: () => _toggleTag(tag),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludeExcludeToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeChip('Include', !_excludeMode, () => setState(() => _excludeMode = false)),
        const SizedBox(width: 6),
        _buildModeChip('Exclude', _excludeMode, () => setState(() => _excludeMode = true)),
      ],
    );
  }

  Widget _buildModeChip(String label, bool selected, VoidCallback onTap) {
    final color = label == 'Exclude' ? Colors.redAccent : _accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? (label == 'Exclude' ? Colors.redAccent : const Color(0xFF9D85FF)) : Colors.white38,
          ),
        ),
      ),
    );
  }

  Widget _buildOfficialSection() {
    const options = {'Any': 'Any', 'True': 'Official', 'False': 'Unofficial'};
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('TRANSLATION'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.entries.map((e) {
              return _buildChoiceChip(
                label: e.value,
                selected: _official == e.key,
                onSelected: () => setState(() => _official = e.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdultSection() {
    const options = {'False': 'Hide Adult', 'Any': 'Show All', 'True': 'Only Adult'};
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ADULT CONTENT'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.entries.map((e) {
              return _buildChoiceChip(
                label: e.value,
                selected: _adult == e.key,
                onSelected: () => setState(() => _adult = e.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    bool exclude = false,
  }) {
    final color = exclude ? Colors.redAccent : _accent;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.22),
      backgroundColor: const Color(0xFF0D1017),
      labelStyle: TextStyle(
        color: selected
            ? (exclude ? Colors.redAccent : const Color(0xFF9D85FF))
            : Colors.white70,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
