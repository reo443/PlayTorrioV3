/// Shared formatting helpers for media metadata (runtime, ratings).

/// Formats a runtime value into hours/minutes.
///
/// Accepts either a plain minute count (`"94"`, `"94 min"`) or an
/// already-formatted string containing hours (`"1h 34m"`), which is returned
/// unchanged. Returns null when nothing usable can be parsed.
String? formatRuntime(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  // Already formatted (contains an hour component) — leave as-is.
  final lower = trimmed.toLowerCase();
  if (lower.contains('h')) return trimmed;

  final match = RegExp(r'\d+').firstMatch(trimmed);
  if (match == null) return trimmed;

  final minutes = int.tryParse(match.group(0)!);
  if (minutes == null || minutes <= 0) return trimmed;

  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours <= 0) return '${mins}m';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

/// Formats a rating to a single decimal place (e.g. `9.093` -> `9.1`).
///
/// Returns the original string when it cannot be parsed as a number.
String? formatRating(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final value = double.tryParse(trimmed);
  if (value == null) return trimmed;
  return value.toStringAsFixed(1);
}
