import 'package:flutter/material.dart';

import '../../theme/playtorrio_tokens.dart';
import '../ui/app_text_field.dart';

/// A single-select option list designed for a bottom sheet.
///
/// Emits the chosen value (or `null` for the "Any" row) via [onSelected].
/// When [searchable] is true a filter field is shown above the list.
class FilterOptionSheet<T> extends StatefulWidget {
  final String title;
  final List<({T value, String label})> options;
  final T? selected;
  final Color accent;
  final bool searchable;
  final ValueChanged<T?> onSelected;

  const FilterOptionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.accent,
    required this.onSelected,
    this.searchable = false,
  });

  @override
  State<FilterOptionSheet<T>> createState() => _FilterOptionSheetState<T>();
}

class _FilterOptionSheetState<T> extends State<FilterOptionSheet<T>> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final filtered = _query.isEmpty
        ? widget.options
        : widget.options
              .where(
                (o) => o.label.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.selected != null)
                    TextButton(
                      onPressed: () => widget.onSelected(null),
                      child: Text(
                        'Clear',
                        style: TextStyle(color: widget.accent),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: AppSearchField(
                  controller: _searchController,
                  hintText: 'Search...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: filtered.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _tile(tokens: tokens, label: 'Any', value: null);
                  }
                  final option = filtered[index - 1];
                  return _tile(
                    tokens: tokens,
                    label: option.label,
                    value: option.value,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required PlayTorrioTokens tokens,
    required String label,
    required T? value,
  }) {
    final selected = value == widget.selected;
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          color: selected ? widget.accent : tokens.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: widget.accent, size: 20)
          : null,
      onTap: () => widget.onSelected(value),
    );
  }
}
