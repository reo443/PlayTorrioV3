import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Filter state for the anime search page — mapped to AniList query params.
class AnimeSearchFilterState {
  final String? genre;
  final int? year;
  final String? season; // 'WINTER' | 'SPRING' | 'SUMMER' | 'FALL'
  final String? format; // 'TV' | 'TV_SHORT' | 'MOVIE' | ...
  final String? status; // 'RELEASING' | 'FINISHED' | ...
  final String sort; // AniList sort enum, e.g. 'TRENDING_DESC'
  final bool adult;

  const AnimeSearchFilterState({
    this.genre,
    this.year,
    this.season,
    this.format,
    this.status,
    this.sort = 'TRENDING_DESC',
    this.adult = false,
  });

  static const genres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Ecchi',
    'Fantasy',
    'Horror',
    'Mahou Shoujo',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ];

  static const seasons = {
    'WINTER': 'Winter',
    'SPRING': 'Spring',
    'SUMMER': 'Summer',
    'FALL': 'Fall',
  };

  static const formats = {
    'TV': 'TV',
    'TV_SHORT': 'TV Short',
    'MOVIE': 'Movie',
    'OVA': 'OVA',
    'ONA': 'ONA',
    'SPECIAL': 'Special',
    'MUSIC': 'Music',
  };

  static const statuses = {
    'RELEASING': 'Releasing',
    'FINISHED': 'Finished',
    'NOT_YET_RELEASED': 'Not Yet Released',
    'CANCELLED': 'Cancelled',
    'HIATUS': 'Hiatus',
  };

  static const sortOptions = {
    'TRENDING_DESC': 'Trending',
    'POPULARITY_DESC': 'Most Popular',
    'SCORE_DESC': 'Top Rated',
    'FAVOURITES_DESC': 'Most Favorited',
    'START_DATE_DESC': 'Newest',
    'START_DATE': 'Oldest',
    'TITLE_ROMAJI': 'Title (A-Z)',
  };

  bool get isDefault =>
      genre == null &&
      year == null &&
      season == null &&
      format == null &&
      status == null &&
      sort == 'TRENDING_DESC' &&
      !adult;

  int get activeCount {
    var count = 0;
    if (genre != null) count++;
    if (year != null) count++;
    if (season != null) count++;
    if (format != null) count++;
    if (status != null) count++;
    if (sort != 'TRENDING_DESC') count++;
    if (adult) count++;
    return count;
  }

  @override
  bool operator ==(Object other) =>
      other is AnimeSearchFilterState &&
      genre == other.genre &&
      year == other.year &&
      season == other.season &&
      format == other.format &&
      status == other.status &&
      sort == other.sort &&
      adult == other.adult;

  @override
  int get hashCode =>
      Object.hash(genre, year, season, format, status, sort, adult);
}

Future<void> showAnimeSearchFilterSheet({
  required BuildContext context,
  required AnimeSearchFilterState current,
  required void Function(AnimeSearchFilterState result) onApply,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 620),
    builder: (ctx) =>
        _AnimeSearchFilterSheet(current: current, onApply: onApply),
  );
}

class _AnimeSearchFilterSheet extends StatefulWidget {
  final AnimeSearchFilterState current;
  final void Function(AnimeSearchFilterState result) onApply;

  const _AnimeSearchFilterSheet({required this.current, required this.onApply});

  @override
  State<_AnimeSearchFilterSheet> createState() =>
      _AnimeSearchFilterSheetState();
}

class _AnimeSearchFilterSheetState extends State<_AnimeSearchFilterSheet> {
  static const _accent = Color(0xFF7C5CFF);

  late String? _genre;
  late String? _season;
  late String? _format;
  late String? _status;
  late String _sort;
  late bool _adult;
  late final TextEditingController _yearCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.current;
    _genre = f.genre;
    _season = f.season;
    _format = f.format;
    _status = f.status;
    _sort = f.sort;
    _adult = f.adult;
    _yearCtrl = TextEditingController(text: f.year?.toString() ?? '');
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    super.dispose();
  }

  int get _activeCount {
    var count = 0;
    if (_genre != null) count++;
    if (_yearCtrl.text.trim().isNotEmpty) count++;
    if (_season != null) count++;
    if (_format != null) count++;
    if (_status != null) count++;
    if (_sort != 'TRENDING_DESC') count++;
    if (_adult) count++;
    return count;
  }

  void _clearAll() {
    setState(() {
      _genre = null;
      _season = null;
      _format = null;
      _status = null;
      _sort = 'TRENDING_DESC';
      _adult = false;
      _yearCtrl.clear();
    });
  }

  void _apply() {
    final year = int.tryParse(_yearCtrl.text.trim());
    Navigator.of(context).pop();
    widget.onApply(
      AnimeSearchFilterState(
        genre: _genre,
        year: (year != null && year > 1900) ? year : null,
        season: _season,
        format: _format,
        status: _status,
        sort: _sort,
        adult: _adult,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardInset = mq.viewInsets.bottom;
    final maxHeight = (mq.size.height * 0.82).clamp(
      0.0,
      mq.size.height - keyboardInset - 16,
    );

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
                        const Icon(
                          Icons.tune_rounded,
                          color: _accent,
                          size: 20,
                        ),
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
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.06),
                    height: 20,
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      physics: const ClampingScrollPhysics(),
                      children: [
                        _buildChipsSection(
                          'GENRE',
                          [null, ...AnimeSearchFilterState.genres],
                          _genre,
                          (v) => setState(() => _genre = v),
                        ),
                        _buildYearSection(),
                        _buildChipsSection(
                          'SEASON',
                          [
                            null,
                            ...AnimeSearchFilterState.seasons.keys.toList(),
                          ],
                          _season,
                          (v) => setState(() => _season = v),
                        ),
                        _buildChipsSection(
                          'FORMAT',
                          [
                            null,
                            ...AnimeSearchFilterState.formats.keys.toList(),
                          ],
                          _format,
                          (v) => setState(() => _format = v),
                        ),
                        _buildChipsSection(
                          'STATUS',
                          [
                            null,
                            ...AnimeSearchFilterState.statuses.keys.toList(),
                          ],
                          _status,
                          (v) => setState(() => _status = v),
                        ),
                        _buildSortSection(),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _activeCount > 0 ? 'Apply ($_activeCount Active)' : 'Apply',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
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

  Widget _buildChipsSection(
    String header,
    List<String?> values,
    String? current,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(header),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((v) {
              final isAll = v == null;
              final selected = isAll ? current == null : current == v;
              String label;
              if (isAll) {
                label = 'All';
              } else {
                label = switch (header) {
                  'SEASON' => AnimeSearchFilterState.seasons[v] ?? v,
                  'FORMAT' => AnimeSearchFilterState.formats[v] ?? v,
                  'STATUS' => AnimeSearchFilterState.statuses[v] ?? v,
                  _ => v,
                };
              }
              return _buildChoiceChip(
                label: label,
                selected: selected,
                onSelected: () => onChanged(isAll ? null : v),
              );
            }).toList(),
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
          _buildSectionHeader('RELEASE YEAR'),
          const SizedBox(height: 10),
          SizedBox(
            width: 180,
            child: TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Year',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: const Color(0xFF0D1017),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _accent),
                ),
              ),
            ),
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
          _buildSectionHeader('SORT BY'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AnimeSearchFilterState.sortOptions.entries.map((e) {
              return _buildChoiceChip(
                label: e.value,
                selected: _sort == e.key,
                onSelected: () => setState(() => _sort = e.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdultSection() {
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
            children: [
              _buildChoiceChip(
                label: 'Hide Adult',
                selected: !_adult,
                onSelected: () => setState(() => _adult = false),
              ),
              _buildChoiceChip(
                label: 'Include Adult',
                selected: _adult,
                onSelected: () => setState(() => _adult = true),
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
