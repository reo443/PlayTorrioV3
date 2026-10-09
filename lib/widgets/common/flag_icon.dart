import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a real country flag (from flagcdn.com) for a language name or
/// ISO 639 code. Falls back to a muted globe icon for unknown languages.
///
/// Replaces emoji flags, which don't render on Windows and were matched
/// with naive substring checks (e.g. "french" containing "en" → US flag).
class FlagIcon extends StatelessWidget {
  /// Display height of the flag; width follows the flag's aspect ratio.
  final double height;
  final String language;

  const FlagIcon({
    super.key,
    required this.language,
    this.height = 12,
  });

  static const Map<String, String> _languageToCountry = {
    'english': 'gb',
    'en': 'gb',
    'eng': 'gb',
    'arabic': 'sa',
    'ar': 'sa',
    'ara': 'sa',
    'spanish': 'es',
    'es': 'es',
    'spa': 'es',
    'castilian': 'es',
    'espanol': 'es',
    'español': 'es',
    'french': 'fr',
    'fr': 'fr',
    'fre': 'fr',
    'fra': 'fr',
    'german': 'de',
    'de': 'de',
    'ger': 'de',
    'deu': 'de',
    'italian': 'it',
    'it': 'it',
    'ita': 'it',
    'portuguese': 'pt',
    'pt': 'pt',
    'por': 'pt',
    'brazilian': 'br',
    'russian': 'ru',
    'ru': 'ru',
    'rus': 'ru',
    'japanese': 'jp',
    'ja': 'jp',
    'jpn': 'jp',
    'korean': 'kr',
    'ko': 'kr',
    'kor': 'kr',
    'chinese': 'cn',
    'zh': 'cn',
    'chi': 'cn',
    'zho': 'cn',
    'mandarin': 'cn',
    'hindi': 'in',
    'hi': 'in',
    'hin': 'in',
    'turkish': 'tr',
    'tr': 'tr',
    'tur': 'tr',
    'indonesian': 'id',
    'ind': 'id',
    'thai': 'th',
    'th': 'th',
    'vietnamese': 'vn',
    'vi': 'vn',
    'vie': 'vn',
    'dutch': 'nl',
    'nl': 'nl',
    'nld': 'nl',
    'flemish': 'nl',
    'polish': 'pl',
    'pl': 'pl',
    'pol': 'pl',
    'ukrainian': 'ua',
    'uk': 'ua',
    'ukr': 'ua',
    'swedish': 'se',
    'sv': 'se',
    'swe': 'se',
    'norwegian': 'no',
    'no': 'no',
    'nor': 'no',
    'danish': 'dk',
    'da': 'dk',
    'dan': 'dk',
    'finnish': 'fi',
    'fi': 'fi',
    'fin': 'fi',
    'greek': 'gr',
    'el': 'gr',
    'ell': 'gr',
    'hebrew': 'il',
    'he': 'il',
    'heb': 'il',
    'hungarian': 'hu',
    'hu': 'hu',
    'hun': 'hu',
    'czech': 'cz',
    'cs': 'cz',
    'ces': 'cz',
    'romanian': 'ro',
    'ro': 'ro',
    'ron': 'ro',
    'bulgarian': 'bg',
    'bg': 'bg',
    'malay': 'my',
    'ms': 'my',
    'persian': 'ir',
    'fa': 'ir',
    'farsi': 'ir',
    'bengali': 'bd',
    'bn': 'bd',
    'ben': 'bd',
    'croatian': 'hr',
    'hr': 'hr',
    'serbian': 'rs',
    'sr': 'rs',
    'slovak': 'sk',
    'sk': 'sk',
    'slovenian': 'si',
    'sl': 'si',
    'latvian': 'lv',
    'lv': 'lv',
    'lithuanian': 'lt',
    'lt': 'lt',
    'estonian': 'ee',
    'et': 'ee',
    'georgian': 'ge',
    'ka': 'ge',
    'armenian': 'am',
    'hy': 'am',
    'azerbaijani': 'az',
    'az': 'az',
    'kazakh': 'kz',
    'kk': 'kz',
    'urdu': 'pk',
    'ur': 'pk',
    'punjabi': 'in',
    'pa': 'in',
    'tamil': 'in',
    'ta': 'in',
    'telugu': 'in',
    'marathi': 'in',
    'mr': 'in',
    'filipino': 'ph',
    'tagalog': 'ph',
    'tl': 'ph',
    'fil': 'ph',
    'swahili': 'ke',
    'amharic': 'et',
    'somali': 'so',
    'afrikaans': 'za',
    'albanian': 'al',
    'macedonian': 'mk',
    'bosnian': 'ba',
    'icelandic': 'is',
    'irish': 'ie',
    'catalan': 'es',
    'basque': 'es',
    'nepali': 'np',
    'sinhala': 'lk',
    'khmer': 'kh',
    'lao': 'la',
    'burmese': 'mm',
    'myanmar': 'mm',
    'mongolian': 'mn',
    'zulu': 'za',
    'yoruba': 'ng',
    'igbo': 'ng',
    'hausa': 'ng',
  };

  /// Maps a language name (or ISO 639-1/2 code) to an ISO 3166-1 alpha-2
  /// country code for flag lookups. Uses word-boundary matching so e.g.
  /// "french" no longer matches the "en" inside it.
  static String? countryCodeFor(String language) {
    final l = language.toLowerCase().trim();
    if (l.isEmpty) return null;

    if (l.contains('brazil') || l.contains('pt-br') || l.contains('ptbr')) return 'br';
    if (l.contains('cantonese')) return 'hk';

    if (_languageToCountry.containsKey(l)) return _languageToCountry[l];

    final keys = _languageToCountry.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final k in keys) {
      if (RegExp('\\b${RegExp.escape(k)}\\b').hasMatch(l)) {
        return _languageToCountry[k];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final code = countryCodeFor(language);

    if (code == null) {
      return Icon(Icons.public_rounded, size: height, color: Colors.white54);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(2.5),
      child: SizedBox(
        width: height * 1.35,
        height: height,
        child: CachedNetworkImage(
          imageUrl: 'https://flagcdn.com/w80/$code.png',
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          errorWidget: (_, __, ___) =>
              Icon(Icons.public_rounded, size: height, color: Colors.white54),
        ),
      ),
    );
  }
}
