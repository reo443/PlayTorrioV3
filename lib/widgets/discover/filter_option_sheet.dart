import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white.withValues(alpha: 0.2),
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
                      style: const TextStyle(
                        color: Colors.white,
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
                child: TextField(
                  autofocus: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.accent),
                    ),
                  ),
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
                    return _tile(label: 'Any', value: null);
                  }
                  final option = filtered[index - 1];
                  return _tile(label: option.label, value: option.value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({required String label, required T? value}) {
    final selected = value == widget.selected;
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          color: selected ? widget.accent : Colors.white,
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
